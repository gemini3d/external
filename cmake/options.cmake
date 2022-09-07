message(STATUS "${PROJECT_NAME} CMake ${CMAKE_VERSION} Toolchain ${CMAKE_TOOLCHAIN_FILE}")

# --- user options

option(BUILD_SHARED_LIBS "Build shared libraries")

option(package "recursively create source and binary packages with CPack")
if(package AND CMAKE_VERSION VERSION_LESS 3.17)
  message(FATAL_ERROR "Packaging Gemini3D external libraries requires CMake >= 3.17")
endif()

if(local)
  get_filename_component(local ${local} ABSOLUTE)

  if(NOT IS_DIRECTORY ${local})
    message(FATAL_ERROR "Local directory ${local} does not exist")
  endif()
endif()

option(find "Attempt to find numeric libraries--saves CI build time, but may slow runtime performance.")

option(amr "build packages used for AMR")
# p4est is still moving target, leave off by default

set(arith "d")  # "d" == 64-bit
option(scotch "MUMPS scotch + METIS ordering (PORD is default and always used)")

option(build_mpi "build MPI")

option(hdf5_parallel "HDF5 parallel")

option(mpich "build MPICH instead of OpenMPI")

set(CMAKE_TLS_VERIFY true)

# --- config checks

if(CMAKE_GENERATOR MATCHES "Visual Studio")
  message(FATAL_ERROR "Visual Studio doesn't work with many libraries here. Please first install Ninja:
  cmake -S ${CMAKE_CURRENT_SOURCE_DIR}/scripts/install_ninja
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
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

# --- look in CMAKE_PREFIX_PATH for Find*.cmake as well
if(NOT DEFINED CMAKE_PREFIX_PATH AND DEFINED ENV{CMAKE_MODULE_PATH})
  set(CMAKE_PREFIX_PATH $ENV{CMAKE_MODULE_PATH})
endif()
if(CMAKE_PREFIX_PATH)
  get_filename_component(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ABSOLUTE)
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_PREFIX_PATH}/cmake)
endif()

get_filename_component(CMAKE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX} ABSOLUTE)
file(MAKE_DIRECTORY ${CMAKE_INSTALL_PREFIX}/cmake)  # ensure we have write access
message(STATUS "CMAKE_INSTALL_PREFIX: ${CMAKE_INSTALL_PREFIX}
ensure this is the directory you wish to install libraries to.")

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})

# --- auto-ignore build directory
if(NOT EXISTS ${PROJECT_BINARY_DIR}/.gitignore)
  file(WRITE ${PROJECT_BINARY_DIR}/.gitignore "*")
endif()

# --- check for updated external projects when "false"
set_property(DIRECTORY PROPERTY EP_UPDATE_DISCONNECTED true)

# --- read JSON with URLs for each library
file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json json_meta)
