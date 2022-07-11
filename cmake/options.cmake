# --- user options

set(PYGEMINI_MIN_PYTHON 3.7)

option(BUILD_SHARED_LIBS "Build shared libraries")

option(find "Attempt to find numeric libraries--saves CI build time, but may slow runtime performance.")

option(amr "build packages used for AMR")
# p4est is still moving target, leave off by default

set(arith "d")  # "d" == 64-bit
option(scotch "MUMPS scotch")

option(msis2 "MSIS2 and MSISE00")
# MSIS 2.x has been an ongoing problem with downloading, patching
# to avoid problems for new users and automated systems, MSIS2 is off
# by default but users can select MSIS2 if they wish.

option(build_mpi "build MPI")

option(hdf5_parallel "HDF5 parallel")

option(mpich "build MPICH instead of OpenMPI")

if(NOT DEFINED python)
  find_package(Python COMPONENTS Interpreter)
  if(NOT Python_FOUND OR "${Python_VERSION}" VERSION_LESS ${PYGEMINI_MIN_PYTHON})
    set(python true)
  endif()
endif()

option(python "build Python")
# Some systems can't use Anaconda for license reasons, and have too old system Python
# This is a universal way to make a recent Python available

if(NOT DEFINED CRAY AND DEFINED ENV{CRAYPE_VERSION})
  set(CRAY true)
endif()

set(CMAKE_TLS_VERIFY true)

# --- config checks

if(CMAKE_GENERATOR MATCHES "Visual Studio")
  # needs to be before project()
  message(FATAL_ERROR "Visual Studio doesn't work with many libraries here. Please first install Ninja:
  cmake -P ${CMAKE_CURRENT_SOURCE_DIR}/scripts/install_ninja.cmake
  ")
endif()

get_property(is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(is_multi_config)
  if(CMAKE_GENERATOR MATCHES "Ninja")
    set(suggest Ninja)
  elseif(WIN32)
    set(suggest "MinGW Makefiles")
  else()
    set(suggest "Unix Makefiles")
  endif()
  message(FATAL_ERROR "Please use a single configuration generator like:
  cmake -G \"${suggest}\"
  ")
endif()

# --- user must specify where to install libraries

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  message(FATAL_ERROR "Please define an install location like
  cmake -B build -DCMAKE_INSTALL_PREFIX=~/libgem")
endif()

# --- exclude Conda from search
if(DEFINED ENV{CONDA_PREFIX})
  set(ignore_path
    $ENV{CONDA_PREFIX} $ENV{CONDA_PREFIX}/Library $ENV{CONDA_PREFIX}/Scripts $ENV{CONDA_PREFIX}/condabin
    $ENV{CONDA_PREFIX}/bin $ENV{CONDA_PREFIX}/lib $ENV{CONDA_PREFIX}/include
    $ENV{CONDA_PREFIX}/Library/bin $ENV{CONDA_PREFIX}/Library/lib $ENV{CONDA_PREFIX}/Library/include
  )
  list(APPEND CMAKE_IGNORE_PATH ${ignore_path})
endif()

# --- CMake Module search path (for Find*.cmake)
cmake_path(SET CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/Modules)

# --- look in CMAKE_PREFIX_PATH for Find*.cmake as well
if(NOT DEFINED CMAKE_PREFIX_PATH AND DEFINED ENV{CMAKE_MODULE_PATH})
  set(CMAKE_PREFIX_PATH $ENV{CMAKE_MODULE_PATH})
endif()
if(CMAKE_PREFIX_PATH)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.21)
    file(REAL_PATH ${CMAKE_PREFIX_PATH} CMAKE_PREFIX_PATH EXPAND_TILDE)
  else()
    get_filename_component(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ABSOLUTE)
  endif()
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_PREFIX_PATH}/cmake)
endif()

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})

# --- check for updated external projects when "false"
set_directory_properties(PROPERTIES EP_UPDATE_DISCONNECTED false)

# --- read JSON with URLs for each library
file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json json_meta)
