# Creates archive file of archive files from CPack.
# This is to avoid problems with having ~ million files in a single archive.
# this allows for an offline-installer script
#
# The top-level package will be under this repo's build/gemini_package.tar
#
# Usage:
#   cmake -P scripts/package_cpack.cmake

cmake_minimum_required(VERSION 3.19...3.25)
# to save JSON metadata requires CMake >= 3.19

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/system_meta.cmake)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/../cmake)

set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

get_filename_component(build_dir ${CMAKE_CURRENT_LIST_DIR}/../build ABSOLUTE)
set(pkgdir ${build_dir}/package)

set(top_archive ${pkgdir}/gemini_package.tar)

# --- configure

set(args
-DCMAKE_INSTALL_PREFIX:PATH=${build_dir}
-DCMAKE_PREFIX_PATH:PATH=${build_dir}
-Dpackage:BOOL=true
)

message(STATUS "package Gemini3D external libraries in ${pkgdir} with options:
${args}")

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-B${build_dir}
-S${CMAKE_CURRENT_LIST_DIR}/..
RESULT_VARIABLE ret
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3D external libraries failed to configure.")
endif()

# --- build and CPack (via ExternalProject)

execute_process(
COMMAND ${CMAKE_COMMAND} --build ${build_dir}
RESULT_VARIABLE ret
)

if(ret EQUAL 0)
  message(STATUS "Gemini3D external libraries build complete.")
else()
  message(FATAL_ERROR "Gemini3D external libraries failed to build.")
endif()

# --- prepare for top archive

file(READ ${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json meta)

set(jsonfile ${pkgdir}/manifest.json)
set(manifest_txt ${pkgdir}/manifest.txt)

system_meta(${jsonfile})

file(APPEND ${manifest_txt}
"offline_install.cmake
libraries.json
")
file(COPY
${CMAKE_CURRENT_LIST_DIR}/offline_install.cmake
${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json
DESTINATION ${pkgdir}/
)

# --- create big archive file of CPack archive files

message(STATUS "Creating top-level source archive ${top_archive}")

execute_process(
COMMAND ${CMAKE_COMMAND} -E tar c ${top_archive} --files-from=${manifest_txt}
RESULT_VARIABLE ret
TIMEOUT 120
ERROR_VARIABLE err
WORKING_DIRECTORY ${pkgdir}
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to create archive ${top_archive}:
  ${ret}: ${err}")
endif()

# --- GPG sign big archive file
find_package(GPG)

if(GPG_FOUND)
  gpg_sign(${top_archive})
  file(COPY ${top_archive}.asc DESTINATION ${pkgdir}/)
else()
  message(WARNING "could not GPG sign ${top_archive} as GPG is not present/working.")
  return()
endif()
