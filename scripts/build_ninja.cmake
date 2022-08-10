cmake_minimum_required(VERSION 3.13)

set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build/ninja_build)

set(config_args
-Dversion=${version}
-B${bindir}
-S${CMAKE_CURRENT_LIST_DIR}/build_ninja
)

execute_process(COMMAND ${CMAKE_COMMAND} ${config_args}
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