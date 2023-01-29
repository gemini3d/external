# USAGE:
# cmake -Dprefix=~/mpich -P build_mpich.cmake


cmake_minimum_required(VERSION 3.19)

if(APPLE)
  find_program(gcc NAMES gcc-14 gcc-13 gcc-12 gcc-11 REQUIRED)
endif()

set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build/mpich_build)

set(args -Dmpich:BOOL=true -DCMAKE_C_COMPILER:FILEPATH=${gcc})

if(prefix)
  list(APPEND args -DCMAKE_INSTALL_PREFIX:PATH=${prefix})
endif()

execute_process(COMMAND ${CMAKE_COMMAND} ${args}
-B${bindir}
-S${CMAKE_CURRENT_LIST_DIR}/mpi
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "MPICH build")
else()
  message(FATAL_ERROR "MPICH failed to configure.")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} --build ${bindir}
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "MPICH install complete.")
else()
  message(FATAL_ERROR "MPICH failed to build and install.")
endif()
