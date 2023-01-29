cmake_minimum_required(VERSION 3.19)

project(BuildMPI LANGUAGES C Fortran)

include(ExternalProject)

option(mpich "Build MPICH instead of OpenMPI")

message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)

find_package(Autotools REQUIRED)

# MPI builds spawn too many threads with bare "make -j" giving build crashes like
# libtool: fork: Resource temporarily unavailable
# clang: error: unable to execute command: posix_spawn failed: Resource temporarily unavailable

cmake_host_system_information(RESULT Ncpu QUERY NUMBER_OF_PHYSICAL_CORES)

set(mpi_flags --prefix=${CMAKE_INSTALL_PREFIX})

# OpenMPI/MPICH have significant problems with hinting and testing compilers, particularly on MacOS
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  list(APPEND mpi_flags CC=gcc)
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
  message(STATUS "Building MPICH")
  include(mpich.cmake)
else()
  message(STATUS "Building OpenMPI")
  include(openmpi.cmake)
endif()
