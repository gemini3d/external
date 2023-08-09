cmake_minimum_required(VERSION 3.19...3.27)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
  message(FATAL_ERROR "Use out of source build like
  cmake -Bbuild")
endif()

project(BuildMPI LANGUAGES C CXX Fortran)

include(CheckIncludeFile)
include(ExternalProject)

option(mpich "Build MPICH instead of OpenMPI")

message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

file(GENERATE OUTPUT .gitignore CONTENT "*")

# --- check for updated external projects when "false"
set_property(DIRECTORY PROPERTY EP_UPDATE_DISCONNECTED true)


find_package(Autotools REQUIRED)

# --- determine number of cores for parallel build
# MPI builds spawn too many threads with bare "make -j" giving build crashes like
# libtool: fork: Resource temporarily unavailable
# clang: error: unable to execute command: posix_spawn failed: Resource temporarily unavailable
if(CMAKE_GENERATOR MATCHES "Makefiles" AND NOT DEFINED ENV{CMAKE_BUILD_PARALLEL_LEVEL})
  cmake_host_system_information(RESULT Ncpu QUERY NUMBER_OF_PHYSICAL_CORES)
endif()

set(mpi_flags --prefix=${CMAKE_INSTALL_PREFIX})

# to avoid ABI problems and confusing build or runtime errors, mandate that C and C++ are same compiler vendor
if(NOT CMAKE_C_COMPILER_ID STREQUAL CMAKE_CXX_COMPILER_ID)
  message(FATAL_ERROR "C compiler ${CMAKE_C_COMPILER_ID} and C++ compiler ${CMAKE_CXX_COMPILER_ID} must be the same to avoid ABI build/runtime errors.
Set envioronment variables CC and CXX to the same compiler by prepending the command line:
  CC=gcc-13 CXX=g++-13")
endiF()

# help OpenMPI/MPICH by hinting compilers, particularly on MacOS
# assume whatever the C compiler is, the C++ and Fortran compilers are the same vendor
if(CMAKE_C_COMPILER_ID MATCHES "GNU|$Intel")
  # OpenMPI / MPICH needs full path to oneAPI compilers
  list(APPEND mpi_flags CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} FC=${CMAKE_Fortran_COMPILER})
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang$")
  # until Flang is ready, use Gfortran
  list(APPEND mpi_flags CC=clang CXX=clang++ FC=gfortran)
endif()

# OpenMPI/MPICH have trouble finding -lm on MacOS especially
find_library(math NAMES m REQUIRED)
get_filename_component(math_LIBDIR ${math} DIRECTORY)

set(mpi_ldflags "LDFLAGS=${CMAKE_LIBRARY_PATH_FLAG}${math_LIBDIR}")

# --- read JSON with URLs for each library
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/libraries.json json_meta)

if(mpich)
  check_include_file("ISO_Fortran_binding.h" HAVE_ISO_FORTRAN_BINDING_H)
  if(NOT HAVE_ISO_FORTRAN_BINDING_H)
    message(FATAL_ERROR "ISO_Fortran_binding.h not found with ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}  ${CMAKE_C_COMPILER}
We suggest GCC compiler. Specify GCC by prepending \"CC=gcc-13\" or similar to your command.
Setting \"CC=gcc\" on macOS defaults to Clang, which will fail. MPICH requires ISO_Fortran_binding.h")
  endif()

  string(JSON mpi_url GET ${json_meta} mpich url)
  string(JSON mpi_sha256 GET ${json_meta} mpich sha256)

  list(APPEND mpi_flags --with-device=ch3)
else()
  string(JSON mpi_url GET ${json_meta} openmpi url)
  string(JSON mpi_sha256 GET ${json_meta} openmpi sha256)

  list(APPEND mpi_flags --with-hwloc=internal)
  # internal HWLOC avoids error in MPI:
  # ibopen-pal.a(topology-linux.o): multiple definition of `hwloc_linux_component'
  #--with-hwloc-libdir=${CMAKE_INSTALL_PREFIX}/lib

  find_package(ZLIB)
  if(ZLIB_FOUND)
    get_filename_component(ZLIB_LIBDIR ${ZLIB_LIBRARIES} DIRECTORY)
    string(APPEND mpi_ldflags " ${CMAKE_LIBRARY_PATH_FLAG}${ZLIB_LIBDIR}")
  endif()

  if(BUILD_SHARED_LIBS)
    list(APPEND mpi_flags --enable-shared --disable-static)
  else()
    list(APPEND mpi_flags --disable-shared --enable-static)
  endif()
endif()

# Downloading URL instead of Git avoids very long "autogen" step
ExternalProject_Add(MPI
URL ${mpi_url}
URL_HASH SHA256=${mpi_sha256}
CONFIGURE_COMMAND <SOURCE_DIR>/configure ${mpi_flags} ${mpi_ldflags}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j${Ncpu}
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j${Ncpu} install
TEST_COMMAND ""
INACTIVITY_TIMEOUT 60
CONFIGURE_HANDLED_BY_BUILD ON
)


message(STATUS "MPI: ${mpi_url}
flags: ${mpi_flags}
ldflags: ${mpi_ldflags}")


# --- check that MPI-3 Fortran is working
ExternalProject_add(MPItest
SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/test
CMAKE_ARGS -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}
INSTALL_COMMAND ""
CONFIGURE_HANDLED_BY_BUILD on
DEPENDS MPI
)
