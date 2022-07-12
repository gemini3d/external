# builds all Gemini3D external libraries

cmake_minimum_required(VERSION 3.20...3.24)

if(NOT CMAKE_BUILD_TYPE)
  # ignore ENV{CMAKE_BUILD_TYPE} as we want to directly capture this project's user intent
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Release default")
endif()

project(GeminiExternalLibs
LANGUAGES C CXX Fortran
VERSION 1.0.5
)

include(cmake/options.cmake)
include(cmake/compilers.cmake)

# --- main program

# NOTE: lists must be passed via CMAKE_CACHE_ARGS using -Dvar:STRING=${var}
# the variable type must be included e.g. STRING

# template function
include(cmake/ExtProj.cmake)

find_package(Autotools)

# --- Zlib
set(zlib_cmake_args
-DZLIB_COMPAT:BOOL=on
-DZLIB_ENABLE_TESTS:BOOL=off
-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=on
)
# CMAKE_POSITION_INDEPENDENT_CODE=on is needed for zlib to work with Python, even when using static libs.

extproj(zlib git "${zlib_cmake_args}" "")

# --- Python
if(python)
  if(NOT WIN32 AND NOT Autotools_FOUND)
    message(FATAL_ERROR "Python on Unix-like systems requires Autotools")
  endif()
  include(cmake/python.cmake)
endif()

# --- Fortran filesystem
extproj(ffilesystem git "" "")

# --- iniparser (for Gemini3D C++ frontend)
extproj(iniparser git "" "")

# --- GLOW
extproj(glow git "" "")

# --- HWM14
extproj(hwm14 git "" "")

# --- MPI

if(build_mpi)
  include(cmake/mpi.cmake)
else()
  find_package(MPI COMPONENTS C Fortran)
endif()

if(build_mpi OR MPI_FOUND)
  set(use_mpi true)
else()
  set(use_mpi false)
endif()

# --- LAPACK
if(find OR CRAY OR DEFINED ENV{MKLROOT})
  find_package(LAPACK)
endif()
if(LAPACK_FOUND)
  add_custom_target(lapack)
  # dummy target to avoid error if user `cmake --build --target lapack`
else()
  extproj(lapack git "-Darith=${arith}" "")
endif()

# --- Scalapack
if(use_mpi)
  include(cmake/scalapack.cmake)
else()
  extproj(mpi_scalapack_stub git "" "")
endif()

# --- MUMPS
include(cmake/mumps.cmake)

# --- HDF5
if(find)
  find_package(HDF5 COMPONENTS C Fortran HL)
endif()
if(HDF5_FOUND)
  add_custom_target(hdf5)
else()
  include(cmake/hdf5.cmake)
endif()

# --- h5fortran
set(h5fortran_deps)
if(NOT HDF5_FOUND)
  list(APPEND h5fortran_deps "hdf5")
  if(build_mpi AND hdf5_parallel)
    list(APPEND h5fortran_deps mpi)
  endif()
endif()

extproj(h5fortran git "-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}" "${h5fortran_deps}")

# --- MSIS
extproj(msis git "-Dmsis2:BOOL=${msis2}" "h5fortran")

# --- p4est
if(amr)
  extproj(libsc git "-Dmpi:BOOL=true;-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}" "zlib")
  extproj(p4est git "-Dmpi:BOOL=true;-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}" "libsc")
  extproj(forestclaw git "-Dmpi:BOOL=true;-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX};-Dclawpatch:BOOL=true" "p4est")
endif()
