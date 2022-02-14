# builds all Gemini3D external libraries

cmake_minimum_required(VERSION 3.20...3.23)

project(GeminiExternalLibs
LANGUAGES C CXX Fortran
VERSION 1.0.0
)

set(arith "d")
option(scotch "MUMPS scotch")

option(BUILD_SHARED_LIBS "Build shared libraries")

option(hdf5_parallel "HDF5 parallel")
option(netcdf "NetCDF4 / nc4fortran build")

option(openmpi "build OpenMPI")
option(mpich "build MPICH")

if(openmpi AND mpich)
  message(FATAL_ERROR "options openmpi and mpich are mutually exclusive")
endif()

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  message(FATAL_ERROR "Specify where to install libraries by adding cmake option like:
  cmake -B build --install-prefix=/path/to/install")
endif()

if(NOT HDF5_VERSION)
  set(HDF5_VERSION 1.12.1 CACHE STRING "HDF5 version built")
endif()

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

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/libraries.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/ExtProj.cmake)

# --- GNU Make
find_program(MAKE_EXECUTABLE
NAMES gmake make
NAMES_PER_DIR
DOC "GNU Make"
)

# --- Fortran filesystem
extproj(ffilesystem ${ffilesystem_git} ${ffilesystem_tag} git "" "")

# --- GLOW
extproj(glow ${glow_git} ${glow_tag} git "" "")

# --- HWM14
extproj(hwm14 ${hwm14_git} ${hwm14_tag} git "" "")

# --- HWLOC
# HWLOC is optional.
# If you have new enough HWLOC, we don't build it.

find_package(HWLOC 2.4)
if(NOT HWLOC_FOUND)
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/hwloc.cmake)
endif()

# --- MPI
find_package(MPI COMPONENTS C Fortran)
if(NOT MPI_FOUND)
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/mpi.cmake)
endif()

# --- LAPACK
extproj(lapack ${lapack_git} ${lapack_tag} git "-Darith=${arith}" "")

# --- Scalapack
set(scalapack_deps lapack)
if(openmpi)
  list(APPEND scalapack_deps OPENMPI)
elseif(mpich)
  list(APPEND scalapack_deps MPICH)
endif()

extproj(scalapack ${scalapack_git} ${scalapack_tag} git "-Dautobuild:BOOL=false;-Darith=${arith}" ${scalapack_deps})

# --- MUMPS
set(mumps_cmake_args
-Dscotch:BOOL=${scotch}
-Dopenmp:BOOL=false
-Dparallel:BOOL=true
-Dautobuild:BOOL=false
-Darith=${arith}
)

extproj(mumps ${mumps_git} ${mumps_tag} git "${mumps_cmake_args}" "scalapack")

# --- Zlib
set(zlib_cmake_args
--install-prefix=${CMAKE_INSTALL_PREFIX}
-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
-DCMAKE_BUILD_TYPE=Release
-DZLIB_COMPAT:BOOL=on
-DZLIB_ENABLE_TESTS:BOOL=off
)

extproj(zlib ${zlib_url} ${zlib_sha256} archive "${zlib_cmake_args}" "")

# --- HDF5

set(hdf5_cmake_args
-DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON
-DZLIB_USE_EXTERNAL:BOOL=OFF
-DCMAKE_MODULE_PATH:PATH=${CMAKE_MODULE_PATH}
-DHDF5_GENERATE_HEADERS:BOOL=false
-DHDF5_DISABLE_COMPILER_WARNINGS:BOOL=true
-DBUILD_STATIC_LIBS:BOOL=$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>
-DHDF5_BUILD_FORTRAN:BOOL=true
-DHDF5_BUILD_CPP_LIB:BOOL=false
-DHDF5_BUILD_EXAMPLES:BOOL=false
-DUSE_LIBAEC:bool=true
-DHDF5_BUILD_TOOLS:BOOL=$<NOT:$<BOOL:${hdf5_parallel}>>
-DHDF5_ENABLE_PARALLEL:BOOL=$<BOOL:${hdf5_parallel}>
)
if(hdf5_parallel AND MPI_ROOT)
  list(APPEND hdf5_cmake_args -DMPI_ROOT:PATH=${MPI_ROOT})
endif()

extproj(hdf5 ${hdf5_url} ${hdf5_sha256} archive "${hdf5_cmake_args}" "zlib")

# --- h5fortran
set(h5fortran_deps hdf5)
if(hdf5_parallel)
  if(openmpi)
    list(APPEND h5fortran_deps OPENMPI)
  elseif(mpich)
    list(APPEND h5fortran_deps MPICH)
  endif()
endif()

extproj(h5fortran ${h5fortran_git} ${h5fortran_tag} git "-Dautobuild:BOOL=off" ${h5fortran_deps})

# --- nc4fortran
if(netcdf)
  extproj(nc4fortran ${nc4fortran_git} ${nc4fortran_tag} git "-Dautobuild:BOOL=on" "hdf5")
endif()
