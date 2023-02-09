# USAGE:
# cmake -Dprefix=~/mpi -P build_openmpi.cmake
cmake_minimum_required(VERSION 3.19)

if(NOT prefix)
  message(FATAL_ERROR "Must specify -Dprefix=<path> to install MPI.")
endif()

if(APPLE)
  find_program(gcc NAMES gcc-14 gcc-13 gcc-12 gcc-11 gcc-10 REQUIRED)
endif()

set(args -Dmpich:BOOL=false -DCMAKE_INSTALL_PREFIX:PATH=${prefix})

if(gcc)
  list(APPEND args -DCMAKE_C_COMPILER:FILEPATH=${gcc})
endif()

if(NOT bindir)
  if(DEFINED ENV{TMPDIR})
    set(bindir $ENV{TMPDIR}/openmpi_build)
  else()
    set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build/openmpi_build)
  endif()
endif()

execute_process(COMMAND ${CMAKE_COMMAND}
  ${args}
  -B${bindir}
  -S${CMAKE_CURRENT_LIST_DIR}/mpi
  -G "Unix Makefiles"
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
