# USAGE:
# cmake -Dprefix=~/mpi -P build_openmpi.cmake
cmake_minimum_required(VERSION 3.19)

if(NOT prefix)
  message(FATAL_ERROR "Must specify -Dprefix=<path> to install MPI.")
endif()

set(args
-Dmpich:BOOL=false
-DCMAKE_INSTALL_PREFIX:PATH=${prefix}
)

if(NOT bindir)
execute_process(COMMAND mktemp -d OUTPUT_VARIABLE bindir OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE ret)
if(NOT ret EQUAL 0)
  set(bindir /tmp/build_openmpi)
endif()
endif()

execute_process(COMMAND ${CMAKE_COMMAND}
  ${args}
  -B${bindir}
  -S${CMAKE_CURRENT_LIST_DIR}/mpi
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "MPI build in ${bindir}")
else()
  message(FATAL_ERROR "MPI failed to configure.")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} --build ${bindir}
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "MPI install complete.")
else()
  message(FATAL_ERROR "MPI failed to build and install.")
endif()
