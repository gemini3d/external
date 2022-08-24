cmake_minimum_required(VERSION 3.13)

set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build/ninja_build)

# need to remove cache to avoid corner cases
file(REMOVE ${bindir}/CMakeCache.txt)

set(args)
if(version)
  list(APPEND args -Dversion=${version})
endif()
if(prefix)
  list(APPEND args -DCMAKE_INSTALL_PREFIX:PATH=${prefix})
endif()

execute_process(COMMAND ${CMAKE_COMMAND} ${args} -B${bindir} -S${CMAKE_CURRENT_LIST_DIR}/build_ninja
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "Ninja build")
else()
  message(FATAL_ERROR "Ninja failed to configure.")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} --build ${bindir} --parallel
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "Ninja install complete.")
else()
  message(FATAL_ERROR "Ninja failed to build and install.")
endif()