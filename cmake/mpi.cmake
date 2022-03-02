if(NOT (openmpi OR mpich))
  set(openmpi true)
endif()

if(NOT MAKE_EXECUTABLE)
  message(FATAL_ERROR "MPI build requires GNU Make.")
endif()

if(WIN32)
  message(WARNING "Windows users normally use MS-MPI or Intel MPI")
endif()

# MPI builds spawn too many threads with bare "make -j" giving build crashes like
# libtool: fork: Resource temporarily unavailable
# clang: error: unable to execute command: posix_spawn failed: Resource temporarily unavailable

include(ProcessorCount)
ProcessorCount(Ncpu)

set(mpi_flags --prefix=${CMAKE_INSTALL_PREFIX})

# OpenMPI/MPICH have significant problems with hinting and testing compilers, particularly on MacOS
if(CMAKE_C_COMPILER_ID STREQUAL GNU)
  list(APPEND mpi_flags CC=gcc)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang$")
  list(APPEND mpi_flags CC=clang)
elseif(CMAKE_C_COMPILER_ID MATCHES "^Intel")
  list(APPEND mpi_flags CC=icx)
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL GNU)
  list(APPEND mpi_flags FC=gfortran)
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^Intel")
  list(APPEND mpi_flags FC=ifx)
endif()

# OpenMPI/MPICH have trouble finding -lm on MacOS especially
find_library(math NAMES m REQUIRED)
cmake_path(GET math PARENT_PATH math_LIBDIR)
set(mpi_ldflags "LDFLAGS=${CMAKE_LIBRARY_PATH_FLAG}${math_LIBDIR}")

if(openmpi)

string(JSON mpi_url GET ${json_meta} openmpi url)
string(JSON mpi_sha256 GET ${json_meta} openmpi sha256)

list(APPEND mpi_flags
--with-hwloc-libdir=${CMAKE_INSTALL_PREFIX}/lib
)

find_package(ZLIB)
if(ZLIB_FOUND)
  cmake_path(GET ZLIB_LIBRARIES PARENT_PATH ZLIB_LIBDIR)
  string(APPEND mpi_ldflags " ${CMAKE_LIBRARY_PATH_FLAG}${ZLIB_LIBDIR}")
endif()

if(BUILD_SHARED_LIBS)
  list(APPEND mpi_flags --enable-shared --disable-static)
else()
  list(APPEND mpi_flags --disable-shared --enable-static)
endif()
# --disable-shared avoids:
# lib_gcc/lib/libz.a(deflate_medium.c.o): relocation R_X86_64_32S against internal symbol `zng_length_code' can not be used when making a shared objec
# https://github.com/zlib-ng/zlib-ng/wiki/Common-build-problems#relocation-error-in-compress2

ExternalProject_Add(mpi
URL ${mpi_url}
URL_HASH SHA256=${mpi_sha256}
CONFIGURE_COMMAND <SOURCE_DIR>/configure ${mpi_flags} ${mpi_ldflags}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j ${Ncpu}
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j ${Ncpu} install
TEST_COMMAND ""
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD ON
DEPENDS hwloc
)

elseif(mpich)

string(JSON mpi_url GET ${json_meta} mpich url)
string(JSON mpi_sha256 GET ${json_meta} mpich sha256)

list(APPEND mpi_flags
--with-device=ch3
)

if(CMAKE_Fortran_COMPILER_ID STREQUAL GNU AND CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 10)
# need FCFLAGS and FFLAGS
  list(APPEND mpi_flags FCFLAGS=-fallow-argument-mismatch FFLAGS=-fallow-argument-mismatch)
endif()

ExternalProject_Add(mpi
URL ${mpi_url}
URL_HASH SHA256=${mpi_sha256}
CONFIGURE_COMMAND <SOURCE_DIR>/configure ${mpi_flags} ${mpi_ldflags}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j ${Ncpu}
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j ${Ncpu} install
TEST_COMMAND ""
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD ON
DEPENDS hwloc
)

endif()
