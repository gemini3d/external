# USAGE:
# cmake -Dprefix=~/mpich -P build_mpich.cmake
cmake_minimum_required(VERSION 3.19)

if(NOT prefix)
  message(FATAL_ERROR "Must specify -Dprefix=<path> to install MPICH.")
endif()

if(APPLE)
  find_program(gcc NAMES gcc-14 gcc-13 gcc-12 gcc-11 REQUIRED)
endif()

set(args -Dmpich:BOOL=true -DCMAKE_INSTALL_PREFIX:PATH=${prefix})

if(gcc)
  list(APPEND args -DCMAKE_C_COMPILER:FILEPATH=${gcc})
endif()

if(NOT bindir)
  set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build/mpich_build)
endif()

execute_process(COMMAND ${CMAKE_COMMAND}
  ${args}
  -B${bindir}
  -S${CMAKE_CURRENT_LIST_DIR}/mpi
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "MPICH build in ${bindir}")
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
