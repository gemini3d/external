if(NOT MAKE_EXECUTABLE)
  message(FATAL_ERROR "MPI build requires GNU Make.")
endif()

if(WIN32)
  message(WARNING "Windows users normally use MS-MPI or Intel MPI")
endif()

if(NOT Autotools_FOUND)
  message(FATAL_ERROR "MPI on Unix-like systems requires Autotools")
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
elseif(CMAKE_C_COMPILER_ID STREQUAL "Intel")
  list(APPEND mpi_flags CC=icc)
elseif(CMAKE_C_COMPILER_ID STREQUAL "IntelLLVM")
  list(APPEND mpi_flags CC=icx)
endif()

if(CMAKE_Fortran_COMPILER_ID STREQUAL GNU)
  list(APPEND mpi_flags FC=gfortran)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "Intel")
  list(APPEND mpi_flags FC=ifort)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "IntelLLVM")
  list(APPEND mpi_flags FC=ifx)
endif()

# OpenMPI/MPICH have trouble finding -lm on MacOS especially
find_library(math NAMES m REQUIRED)
cmake_path(GET math PARENT_PATH math_LIBDIR)
set(mpi_ldflags "LDFLAGS=${CMAKE_LIBRARY_PATH_FLAG}${math_LIBDIR}")


if(mpich)
  include(mpich.cmake)
else()
  include(openmpi.cmake)
endif()
