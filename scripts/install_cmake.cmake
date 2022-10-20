cmake_minimum_required(VERSION 3.13)

if(NOT bindir)
  find_program(mktemp NAMES mktemp)
  if(mktemp)
    execute_process(COMMAND mktemp -d OUTPUT_VARIABLE bindir OUTPUT_STRIP_TRAILING_WHITESPACE)
  else()
    string(RANDOM LENGTH 12 _s)
    if(WIN32)
      set(bindir $ENV{TEMP}/cmake-${_s})
    else()
      set(bindir /tmp/cmake-${_s})
    endif()
  endif()
endif()

set(args)
if(version)
  list(APPEND args -Dversion=${version})
endif()
if(prefix)
  list(APPEND args -DCMAKE_INSTALL_PREFIX:PATH=${prefix})
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-B${bindir}
-S${CMAKE_CURRENT_LIST_DIR}/install_cmake
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "CMake install complete.")
else()
  message(FATAL_ERROR "CMake failed to install: ${ret}")
endif()
