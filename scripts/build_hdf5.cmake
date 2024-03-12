# USAGE:
# cmake -Dprefix=~/hdf5 -P build_hdf5.cmake
cmake_minimum_required(VERSION 3.20)

option(hdf5_parallel "Build parallel hdf5")

if(NOT prefix)
  message(FATAL_ERROR "Must specify -Dprefix=<path> to install library.")
endif()

set(args -DCMAKE_INSTALL_PREFIX:PATH=${prefix})

if(DEFINED hdf5_parallel)
  list(APPEND args -Dhdf5_parallel:BOOL=${hdf5_parallel})
endif()

if(NOT bindir)
  execute_process(COMMAND mktemp -d OUTPUT_VARIABLE bindir OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE ret)
  if(NOT ret EQUAL 0)
    string(RANDOM LENGTH 6 r)
    set(bindir /tmp/build_${r})
  endif()
endif()

set(srcdir ${CMAKE_CURRENT_LIST_DIR}/../h5fortran/scripts)
if(NOT IS_DIRECTORY ${srcdir})
  message(FATAL_ERROR "need to update Git submodules
  git submodule update --init --recursive")
endif()

execute_process(COMMAND ${CMAKE_COMMAND}
  ${args}
  -B${bindir}
  -S${srcdir}
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "build in ${bindir}")
else()
  message(FATAL_ERROR "failed to configure.")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} --build ${bindir}
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "install complete.")
else()
  message(FATAL_ERROR "failed to build and install.")
endif()
