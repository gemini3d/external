# builds all Gemini3D external libraries

cmake_minimum_required(VERSION 3.14...3.26)

if(NOT CMAKE_BUILD_TYPE)
  # ignore ENV{CMAKE_BUILD_TYPE} as we want to directly capture this project's user intent
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Release default")
endif()

include(cmake/toolchain.cmake)

project(GeminiExternalLibs
LANGUAGES C CXX Fortran
VERSION 1.1.1
)

include(cmake/options.cmake)
include(cmake/compilers.cmake)
include(cmake/package/cpacker.cmake)

# --- main program

# NOTE: lists must be passed via CMAKE_CACHE_ARGS using -Dvar:STRING=${var}
# the variable type must be included e.g. STRING

# template function
include(cmake/ExtProj.cmake)
include(cmake/FetchSource.cmake)

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

# determine possible user overrides for each of the libraries we might develop
# we specifically exclude from this manual override:
#   MPI, HDF5, ZLIB, scalapack_src, mumps_src
# as we're unlikely to modify those libraries

foreach(n ffilesystem iniparser glow hwm14 msis lapack scalapack mumps libsc p4est forestclaw)
  set(${n}_method "git")

  if(local)
    set(${n}_method "local")
  endif()

  if(${n}_source)
    # user command line point to source directory out of tree
    set(${n}_method "source_dir")
  endif()

  message(DEBUG "${n} method: ${${n}_method}")
endforeach()

# --- Fortran-filesystem
extproj(ffilesystem ${ffilesystem_method} "-Dcpp:BOOL=false" "")

# --- iniparser (for Gemini3D C++ frontend)
extproj(iniparser ${iniparser_method} "" "")

# --- GLOW
extproj(glow ${glow_method} "" "")

# --- HWM14
extproj(hwm14 ${hwm14_method} "" "")

# --- MPI
if(NOT DEFINED MPI_ROOT AND DEFINED ENV{MPI_ROOT})
  set(MPI_ROOT $ENV{MPI_ROOT})
endif()

find_package(MPI COMPONENTS C Fortran REQUIRED)

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
  set(MPI_3_Fortran_OK TRUE CACHE BOOL "MPI-3 Fortran support")
else()
  message(CHECK_FAIL "no")
  message(FATAL_ERROR "Gemini3D requires MPI-3 Fortran support")
endif()

endif()

# --- LAPACK
if(find OR CRAY OR DEFINED ENV{MKLROOT})
  find_package(LAPACK)
endif()
if(LAPACK_FOUND)
  add_custom_target(lapack)
  # dummy target to avoid error if user `cmake --build --target lapack`
else()
  set(lapack_args
  -Dlocal:PATH=${local}
  -DBUILD_SINGLE:BOOL=false
  -DBUILD_DOUBLE:BOOL=true
  -DBUILD_COMPLEX:BOOL=false
  -DBUILD_COMPLEX16:BOOL=false
  )
  extproj(lapack ${lapack_method} "${lapack_args}" "")
endif()

# --- Scalapack
include(cmake/scalapack.cmake)

# --- MUMPS
include(cmake/mumps.cmake)

# --- HDF5
if(find OR CRAY)
  find_package(HDF5 COMPONENTS C Fortran HL)
endif()
if(HDF5_FOUND)
  add_custom_target(hdf5)
else()
  include(cmake/zlib.cmake)
  include(cmake/hdf5.cmake)
endif()

# --- h5fortran
set(h5fortran_deps)
if(NOT HDF5_FOUND)
  list(APPEND h5fortran_deps "hdf5")
endif()

extproj(h5fortran git "${h5fortran_args}" "${h5fortran_deps}")

# --- MSIS
extproj(msis git "-Dmsis2:BOOL=true" "h5fortran")
# MSIS 2.x is built by default -- to use MSIS 2.x in a simulation run
# requires the simulation config.nml to have a field like:
#
# &neutral_BG
# msis_version = 21  ! MSIS version multiplied by 10 e.g. 21 is MSIS 2.1
# /

# --- Gemini3d project
if(package)
  extproj(gemini3d git "" "h5fortran;mumps;msis;hwm14;glow;ffilesystem;iniparser")
endif()

# --- p4est, forestclaw
if(amr)
  set(amr_args -Dmpi:BOOL=true)

  include(cmake/zlib.cmake)
  extproj(libsc ${libsc_method} "${amr_args}" "zlib")
  extproj(p4est ${p4est_method} "${amr_args}" "libsc")
  set(fclaw_args ${amr_args} -Dclawpatch:BOOL=true -Dclawpack:BOOL=true)
  extproj(forestclaw ${forestclaw_method} "${fclaw_args}" "p4est")
endif()

# print summary of configuration
include(FeatureSummary)

add_feature_info(Find ${find} "")
add_feature_info(HDF5-MPI ${hdf5_parallel} "HDF5-MPI layer (otherwise, serial HDF5)")
add_feature_info(shared ${BUILD_SHARED_LIBS} "build shared libs (otherwise, build static libs)")
add_feature_info(remote_disconnected ${EP_UPDATE_DISCONNECTED} "don't update remote repositories after first download/confiugre")
add_feature_info(packaging ${package} "preparing new data upoad (for development team)")

feature_summary(WHAT ALL)
