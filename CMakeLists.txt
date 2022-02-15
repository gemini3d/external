# builds all Gemini3D external libraries

cmake_minimum_required(VERSION 3.20...3.23)

project(GeminiExternalLibs
LANGUAGES C CXX Fortran
VERSION 1.0.2
)

# --- user options

option(BUILD_SHARED_LIBS "Build shared libraries")
option(build_all "Don't search for any libs, build them all")

set(arith "d")
option(scotch "MUMPS scotch")

option(msis2 "MSIS2 and MSISE00" true)

option(hdf5_parallel "HDF5 parallel")
option(netcdf "NetCDF4 / nc4fortran build")

option(openmpi "build OpenMPI")
option(mpich "build MPICH")

# --- main program

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules)

set(CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})

if(CMAKE_GENERATOR STREQUAL "Ninja Multi-Config")
  set(EXTPROJ_GEN "Ninja")
else()
  set(EXTPROJ_GEN ${CMAKE_GENERATOR})
endif()

# NOTE: lists must be passed via CMAKE_CACHE_ARGS using -Dvar:STRING=${var}
# the variable type must be included e.g. STRING
set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY EP_UPDATE_DISCONNECTED true)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/ExtProj.cmake)

# --- read JSON with URLs for each library
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/cmake/libraries.json json_meta)

# --- GNU Make
find_program(MAKE_EXECUTABLE
NAMES gmake make mingw32-make
NAMES_PER_DIR
DOC "GNU Make (or compatible)"
)

# --- Fortran filesystem
extproj(ffilesystem git "" "")

# --- GLOW
extproj(glow git "" "")

# --- HWM14
extproj(hwm14 git "" "")

# --- HWLOC
# HWLOC is optional.
# If you have new enough HWLOC, we don't build it.
if(NOT build_all)
  find_package(HWLOC 2.4)
endif()
if(NOT HWLOC_FOUND)
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/hwloc.cmake)
endif()

# --- MPI
if(NOT build_all)
  find_package(MPI COMPONENTS C Fortran)
endif()
if(NOT MPI_FOUND)
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mpi.cmake)
endif()

# --- LAPACK
extproj(lapack git "-Darith=${arith}" "")

# --- Scalapack
set(scalapack_deps lapack)
if(mpi)
  list(APPEND scalapack_deps mpi)
endif()

extproj(scalapack git "-Dautobuild:BOOL=false;-Darith=${arith}" ${scalapack_deps})

# --- MUMPS
set(mumps_cmake_args
-Dscotch:BOOL=${scotch}
-Dopenmp:BOOL=false
-Dparallel:BOOL=true
-Dautobuild:BOOL=false
-Darith=${arith}
)

extproj(mumps git "${mumps_cmake_args}" "scalapack")

# --- optional HDF5
if(NOT build_all)
  find_package(HDF5 COMPONENTS C Fortran HL)
endif()
if(NOT HDF5_FOUND)
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/hdf5.cmake)
endif()

# --- h5fortran
set(h5fortran_deps)
if(NOT HDF5_FOUND)
  list(APPEND h5fortran_deps hdf5)
  if(hdf5_parallel)
    list(APPEND h5fortran_deps mpi)
  endif()
endif()

extproj(h5fortran git "-Dautobuild:BOOL=off" "${h5fortran_deps}")

# --- nc4fortran
if(netcdf)
  extproj(nc4fortran git "-Dautobuild:BOOL=on" "hdf5")
endif()

# --- MSIS
extproj(msis git "-Dmsis2:BOOL=${msis2}" "h5fortran")
