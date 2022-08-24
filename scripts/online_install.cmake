# Build Gemini3D external libraries using internet connection to download
# options:
#
# -Dprefix: where to install libraries under (default ~/libgem_<compiler_id>)

cmake_minimum_required(VERSION 3.17)

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/compiler_id.cmake)

set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

# heuristic to determine compiler family.
if(NOT bindir)
  compiler_id(bin_name)
  set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build_${bin_name})
endif()
get_filename_component(bindir ${bindir} ABSOLUTE)

if(NOT prefix)
  if(NOT bin_name)
    compiler_id(bin_name)
  endif()
  set(prefix ~/libgem_${bin_name})
endif()
get_filename_component(prefix ${prefix} ABSOLUTE)
file(MAKE_DIRECTORY ${prefix}/bin)

if(compiler_id_exe)
  file(COPY ${compiler_id_exe} DESTINATION ${prefix}/bin/)
endif()

set(args
-DCMAKE_INSTALL_PREFIX:PATH=${prefix}
)

message(STATUS "Building in ${bindir} with options:
${args}")

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-B${bindir}
-S${CMAKE_CURRENT_LIST_DIR}/..
RESULT_VARIABLE ret
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3D external libraries failed to configure.")
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} --build ${bindir}
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "Gemini3D external libraries install complete.")
else()
  message(FATAL_ERROR "Gemini3D external libraries failed to build/install.")
endif()
