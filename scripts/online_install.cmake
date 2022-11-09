# Build Gemini3D external libraries using internet connection to download
# options:
#
# -Dprefix: where to install libraries under (default ~/libgem_<compiler_id>)

cmake_minimum_required(VERSION 3.14)
# Gemini3D currently requires CMake 3.14+

if(CMAKE_VERSION VERSION_LESS 3.19)
  include(${CMAKE_CURRENT_LIST_DIR}/../cmake/Modules/JsonParse.cmake)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/git.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../cmake/compiler_id.cmake)

set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

# controlled parallel build (avoid too many HDF5 build threads with Make)
if(DEFINED ENV{CMAKE_BUILD_PARALLEL_LEVEL})
  set(Ncpu $ENV{CMAKE_BUILD_PARALLEL_LEVEL})
else()
  cmake_host_system_information(RESULT Ncpu QUERY NUMBER_OF_PHYSICAL_CORES)
endif()

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
-DCMAKE_PREFIX_PATH:PATH=${prefix}
)

message(STATUS "Building Gemini3D external libraries in ${bindir} with options:
${args}")

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-B${bindir}
-S${CMAKE_CURRENT_LIST_DIR}/..
RESULT_VARIABLE ret
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3D external libraries failed to configure: ${ret}")
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} --build ${bindir} --parallel ${Ncpu}
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "Gemini3D external libraries install complete.")
else()
  message(FATAL_ERROR "Gemini3D external libraries failed to build/install: ${ret}")
endif()

# --- Gemini3D

set(gemini3d_src ${bindir}/gemini3d-prefix)
set(gemini3d_bin ${gemini3d_src}/build)

message(STATUS "Building Gemini3D in ${gemini3d_src} with options:
${args}")

file(READ ${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json json_meta)
if(CMAKE_VERSION VERSION_LESS 3.19)
  sbeParseJson(meta json_meta)
  set(url ${meta.gemini3d.url})
  set(tag ${meta.gemini3d.tag})
else()
  string(JSON url GET ${json_meta} "gemini3d" "url")
  string(JSON tag GET ${json_meta} "gemini3d" "tag")
endif()

git_clone("gemini3d" ${url} ${tag} ${gemini3d_src})

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-B${gemini3d_bin}
-S${gemini3d_src}
RESULT_VARIABLE ret
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3D failed to configure: ${ret}")
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} --build ${gemini3d_bin} --parallel ${Ncpu}
RESULT_VARIABLE ret
)
if(ret EQUAL 0)
  message(STATUS "Gemini3D build complete.")
else()
  message(FATAL_ERROR "Gemini3D failed to build: ${ret}")
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} --install ${gemini3d_bin}
RESULT_VARIABLE ret
)
if(ret EQUAL 0)
  message(STATUS "Gemini3D install complete.")
else()
  message(FATAL_ERROR "Gemini3D failed to install: ${ret}")
endif()
