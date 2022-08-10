cmake_minimum_required(VERSION 3.13)

set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build/ninja_install)

execute_process(COMMAND ${CMAKE_COMMAND}
    -Dversion=${version}
    -B${bindir}
    -S${CMAKE_CURRENT_LIST_DIR}/install_ninja
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "Ninja install complete.")
else()
  execute_process(COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_LIST_DIR}/build_ninja.cmake)
endif()