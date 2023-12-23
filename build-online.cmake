# Build Gemini3D external libraries using internet connection to download
# options:
#
# -Dprefix: where to install libraries under (default ~/libgem_<compiler_id>)

cmake_minimum_required(VERSION 3.19...3.28)

option(find "find bigger libraries like MPI and HDF5 if available")

include(${CMAKE_CURRENT_LIST_DIR}/cmake/git.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/compiler_id.cmake)

set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

# random build dir to avoid confusion with reused build dir
execute_process(COMMAND mktemp -d OUTPUT_VARIABLE bindir OUTPUT_STRIP_TRAILING_WHITESPACE RESULT_VARIABLE ret)
if(NOT ret EQUAL 0)
  string(RANDOM LENGTH 6 r)
  set(bindir /tmp/build_${r})
endif()

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
-DCMAKE_PREFIX_PATH:PATH=${prefix}
-Dfind:BOOL=${find}
)
if(DEFINED amr)
  list(APPEND args -Damr:BOOL=${amr})
endif()

message(STATUS "Building Gemini3D external libraries in ${bindir} with options:
${args}")

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-B${bindir}
-S${CMAKE_CURRENT_LIST_DIR}
RESULT_VARIABLE ret
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3D external libraries failed to configure: ${ret}")
endif()

# don't specify cmake --build --parallel to avoid confusion when build errors happen in one library
# each library itself is built in parallel,
# so adding --parallel here doesn't really help build speed.
execute_process(
COMMAND ${CMAKE_COMMAND} --build ${bindir}
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "Gemini3D external libraries install complete.")
else()
  message(FATAL_ERROR "Gemini3D external libraries failed to build/install: ${ret}")
endif()
