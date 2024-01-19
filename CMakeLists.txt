# builds all Gemini3D external libraries

cmake_minimum_required(VERSION 3.20...3.28)
# Cmake 3.19 string(JSON)
# Cmake 3.20 cmake_path()

if(NOT CMAKE_BUILD_TYPE)
  # ignore ENV{CMAKE_BUILD_TYPE} as we want to directly capture this project's user intent
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Release default")
endif()

include(cmake/toolchain.cmake)

project(GeminiExternalLibs
LANGUAGES C CXX Fortran
VERSION 1.1.1
)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  get_filename_component(home "~" ABSOLUTE)
  string(TOLOWER ${CMAKE_Fortran_COMPILER_ID} ln)
  set(CMAKE_INSTALL_PREFIX ${home}/libgem_${ln} CACHE PATH "default install prefix" FORCE)
endif()

include(options.cmake)

include(cmake/GitSubmodule.cmake)

# --- main program

# NOTE: lists must be passed via CMAKE_CACHE_ARGS using -Dvar:STRING=${var}
# the variable type must be included e.g. STRING

# template function
include(cmake/ExtProj.cmake)
include(cmake/FetchSource.cmake)

# --- avoid Anaconda libraries
if(DEFINED ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PREFIX_PATH $ENV{CONDA_PREFIX})
  list(APPEND CMAKE_IGNORE_PATH $ENV{CONDA_PREFIX}/bin)
  # need CMAKE_IGNORE_PATH for CMake < 3.23
  # and to ensure system env var PATH doesn't interfere
  # despite CMAKE_IGNORE_PREFIX_PATH
endif()

if(package)
  file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/package)
  if(NOT DEFINED manifest_txt)
    set(manifest_txt ${PROJECT_BINARY_DIR}/package/manifest.txt)
  endif()
  file(WRITE ${manifest_txt}
  "scalapack_src.tar.bz2
mumps_src.tar.gz
")
  fetch_source(scalapack_src git)
  fetch_source(mumps_src archive)
endif()

if(CRAY)
  # install toolchain file for future use
  file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cray.cmake DESTINATION ${CMAKE_INSTALL_PREFIX}/cmake/)
endif()

# --- Fortran-filesystem
git_submodule(${CMAKE_CURRENT_SOURCE_DIR}/ffilesystem)
add_subdirectory(ffilesystem)

# --- GLOW
git_submodule(${CMAKE_CURRENT_SOURCE_DIR}/glow)
add_subdirectory(glow)

# --- HWM14
git_submodule(${CMAKE_CURRENT_SOURCE_DIR}/hwm14)
add_subdirectory(hwm14)

# --- MPI
if(NOT DEFINED MPI_ROOT)
  if(DEFINED ENV{MPI_ROOT})
    set(MPI_ROOT $ENV{MPI_ROOT})
  elseif(DEFINED ENV{I_MPI_ROOT})
    set(MPI_ROOT $ENV{I_MPI_ROOT})
  endif()
endif()

message(STATUS "MPI_ROOT=${MPI_ROOT}")

find_package(MPI COMPONENTS C Fortran)
if(NOT MPI_FOUND)
  message(FATAL_ERROR "MPI library not found. Please set environment variable MPI_ROOT to the path of the MPI library.
For example, if you have ~/openmpi/bin/mpiexec, set env var MPI_ROOT=~/openmpi or specify:
cmake -Bbuild -DMPI_ROOT=~/openmpi")
endif()

if(NOT MPI_3_Fortran_OK)

message(CHECK_START "Checking for MPI-3 Fortran support")

try_compile(MPI_3_Fortran_OK
${CMAKE_CURRENT_BINARY_DIR}/mpi3test
${CMAKE_CURRENT_SOURCE_DIR}/scripts/mpi/test
MPI3test
CMAKE_FLAGS -DMPI_ROOT=${MPI_ROOT}
)
if(MPI_3_Fortran_OK)
  message(CHECK_PASS "yes")
else()
  message(CHECK_FAIL "no")
  message(WARNING "Gemini3D requires MPI-3 Fortran support.
Either specify the path to a newer/different MPI library via environment variable MPI_ROOT
or build OpenMPI from source with Fortran MPI-3 support:
cmake -Dprefix=~/openmpi -P ${CMAKE_CURRENT_SOURCE_DIR}/scripts/build_openmpi.cmake")
endif()

endif()


include(cmake/lapack.cmake)
include(cmake/scalapack.cmake)
include(cmake/mumps.cmake)

# --- HDF5
git_submodule(${CMAKE_CURRENT_SOURCE_DIR}/h5fortran)
add_subdirectory(h5fortran)

# --- MSIS
git_submodule(${CMAKE_CURRENT_SOURCE_DIR}/msis)
add_subdirectory(msis)

# print summary of configuration
include(FeatureSummary)

add_feature_info(Find find "find installed libraries")
add_feature_info(HDF5-MPI hdf5_parallel "HDF5-MPI layer (otherwise, serial HDF5)")
add_feature_info(shared BUILD_SHARED_LIBS "build shared libs (otherwise, build static libs)")
add_feature_info(remote_disconnected EP_UPDATE_DISCONNECTED "don't update remote repositories after first download/confiugre")
add_feature_info(packaging package "preparing new data upoad (for development team)")

feature_summary(WHAT ENABLED_FEATURES DISABLED_FEATURES)

include(cmake/package/cpacker.cmake)
