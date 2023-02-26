cmake_minimum_required(VERSION 3.13)

if(NOT bindir)
  find_program(mktemp NAMES mktemp)
  if(mktemp)
    execute_process(COMMAND mktemp -d OUTPUT_VARIABLE bindir OUTPUT_STRIP_TRAILING_WHITESPACE)
  else()
    string(RANDOM LENGTH 12 _s)
    if(DEFINED ENV{TEMP})
      set(bindir $ENV{TEMP}/${_s})
    elseif(IS_DIRECTORY "/tmp")
      set(bindir /tmp/${_s})
    else()
      set(bindir ${CMAKE_CURRENT_BINARY_DIR}/${_s})
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
if(WIN32 AND NOT DEFINED ENV{CMAKE_GENERATOR})
  list(APPEND args -G "MinGW Makefiles")
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-B${bindir}
-S${CMAKE_CURRENT_LIST_DIR}/install_ninja
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "Ninja install complete.")
else()
  execute_process(COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_LIST_DIR}/build_ninja.cmake)
endif()
