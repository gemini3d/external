# builds all Gemini3D external libraries

cmake_minimum_required(VERSION 3.20...3.24)

if(NOT CMAKE_BUILD_TYPE)
  # ignore ENV{CMAKE_BUILD_TYPE} as we want to directly capture this project's user intent
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Release default")
endif()

project(GeminiExternalLibs
LANGUAGES C CXX Fortran
VERSION 1.0.3
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

# --- HWLOC
if(NOT build_all)
  find_package(HWLOC 2.4)
endif()
if(HWLOC_FOUND)
  add_custom_target(hwloc)
  # dummy target to avoid error if user `cmake --build --target hwloc`
else()
  include(cmake/hwloc.cmake)
endif()

# --- MPI
if(NOT usempi)
  extproj(mpi_scalapack_stub git "" "")
endif()

if(usempi)
  if(NOT build_all)
    find_package(MPI COMPONENTS C Fortran)
  endif()
  if(MPI_FOUND)
    add_custom_target(mpi)
  elseif(CRAY)
    message(FATAL_ERROR "Cray systems should use cray-mpich. Setup Cray PE by:
    cmake -P ${CMAKE_CURRENT_SOURCE_DIR}/cray.cmake"
    )
  else()
    include(cmake/mpi.cmake)
  endif()
endif(usempi)

# --- LAPACK
if(CRAY OR DEFINED ENV{MKLROOT} OR (NOT build_all AND find))
  find_package(LAPACK)
endif()
if(LAPACK_FOUND)
  add_custom_target(lapack)
  # dummy target to avoid error if user `cmake --build --target lapack`
else()
  extproj(lapack git "-Darith=${arith}" "")
endif()

# --- Scalapack
set(scalapack_args
-Darith=${arith}
-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}
)

if(NOT LAPACK_FOUND)
  set(scalapack_deps lapack)
endif()
if(NOT MPI_FOUND)
  list(APPEND scalapack_deps mpi)
endif()

if(usempi)
  if(CRAY OR DEFINED ENV{MKLROOT} OR (NOT build_all AND find))
    find_package(SCALAPACK)
  endif()
  if(SCALAPACK_FOUND)
    add_custom_target(scalapack)
  else()
    extproj(scalapack git "${scalapack_args}" "${scalapack_deps}")
  endif()
endif(usempi)

# --- MUMPS
set(mumps_cmake_args
-Dscotch:BOOL=${scotch}
-Dopenmp:BOOL=false
-Dparallel:BOOL=${usempi}
-Darith=${arith}
-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}
)
if(MSVC AND BUILD_SHARED_LIBS)
  # long-standing bug in MUMPS that can't handle shared libraries with MSVC (Windows Intel oneAPI)
  list(APPEND mumps_cmake_args -DBUILD_SHARED_LIBS:BOOL=false)
endif()

set(mumps_deps)
if(usempi)
  if(NOT SCALAPACK_FOUND)
    list(APPEND mumps_deps scalapack)
  endif()
else()
  if(NOT LAPACK_FOUND)
    list(APPEND mumps_deps lapack mpi_scalapack_stub)
  endif()
endif()

if(NOT build_all AND find)
  if(usempi)
    find_package(MUMPS COMPONENTS ${arith})
  else()
    find_package(MUMPS COMPONENTS ${arith} mpiseq)
  endif()
endif()
if(MUMPS_FOUND)
  add_custom_target(mumps)
else()
  extproj(mumps git "${mumps_cmake_args}" "${mumps_deps}")
endif()

# --- HDF5
if(NOT build_all)
  find_package(HDF5 COMPONENTS C Fortran HL)
endif()
if(HDF5_FOUND)
  add_custom_target(hdf5)
# elseif(CRAY)
# too compiler specific
#   message(FATAL_ERROR "Cray systems should use cray-hdf5. Setup Cray PE by:
#   cmake -P ${CMAKE_CURRENT_SOURCE_DIR}/cray.cmake"
#   )
else()
  include(cmake/hdf5.cmake)
endif()

# --- h5fortran
set(h5fortran_deps)
if(NOT HDF5_FOUND)
  list(APPEND h5fortran_deps "zlib;hdf5")
  if(NOT MPI_FOUND AND hdf5_parallel)
    list(APPEND h5fortran_deps mpi)
  endif()
endif()

extproj(h5fortran git "-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}" "${h5fortran_deps}")

# --- nc4fortran
if(netcdf)
  extproj(nc4fortran git "" "zlib;hdf5")
endif()

# --- MSIS
extproj(msis git "-Dmsis2:BOOL=${msis2}" "h5fortran")

# --- p4est
if(amr)
  extproj(libsc git "-Dmpi:BOOL=${usempi};-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}" "zlib")
  extproj(p4est git "-Dmpi:BOOL=${usempi};-DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX}" "zlib;libsc")
endif()
