cmake_minimum_required(VERSION 3.13)

set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build/cmake_install)

execute_process(COMMAND ${CMAKE_COMMAND}
    -Dversion=${version}
    -B${bindir}
    -S${CMAKE_CURRENT_LIST_DIR}/install_cmake
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "CMake install complete.")
else()
  message(FATAL_ERROR "CMake failed to install.")
endif()