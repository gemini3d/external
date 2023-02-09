cmake_minimum_required(VERSION 3.19...3.26)

project(BuildMPI LANGUAGES C Fortran)

include(CheckIncludeFile)
include(ExternalProject)

option(mpich "Build MPICH instead of OpenMPI")

message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

# --- auto-ignore build directory
if(NOT EXISTS ${PROJECT_BINARY_DIR}/.gitignore)
  file(WRITE ${PROJECT_BINARY_DIR}/.gitignore "*")
endif()

# --- check for updated external projects when "false"
set_property(DIRECTORY PROPERTY EP_UPDATE_DISCONNECTED true)


find_package(Autotools REQUIRED)

# --- determine number of cores for parallel build
# MPI builds spawn too many threads with bare "make -j" giving build crashes like
# libtool: fork: Resource temporarily unavailable
# clang: error: unable to execute command: posix_spawn failed: Resource temporarily unavailable
cmake_host_system_information(RESULT Ncpu QUERY NUMBER_OF_PHYSICAL_CORES)

set(mpi_flags --prefix=${CMAKE_INSTALL_PREFIX})

# OpenMPI/MPICH have significant problems with hinting and testing compilers, particularly on MacOS
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  if(mpich)
    list(APPEND mpi_flags CC=${CMAKE_C_COMPILER})
  else()
    list(APPEND mpi_flags CC=gcc)
  endif()
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang$")
  list(APPEND mpi_flags CC=clang)
elseif(CMAKE_C_COMPILER_ID MATCHES "Intel|IntelLLVM")
  list(APPEND mpi_flags CC=icx)
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  list(APPEND mpi_flags FC=gfortran)
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "Intel|IntelLLVM")
  list(APPEND mpi_flags FC=ifx)
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
    message(NOTICE "
*** ERROR: ISO_Fortran_binding.h not found with ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}  ${CMAKE_C_COMPILER}")
    if(APPLE)
      message(NOTICE "on macOS, please use GCC compiler. Specify GCC like:

cmake -DCMAKE_C_COMPILER=gcc-12 -B build

Note that just setting \"CC=gcc\" on macOS simply defaults to Clang, which will fail.
")
    endif()
    message(FATAL_ERROR "MPICH requires ISO_Fortran_binding.h")
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
