# Creates archive file of archive files from CPack.
# This is to avoid problems with having ~ million files in a single archive.
# this allows for an offline-installer script
#
# NOTE: before running this script, build gemini3d/external like
#
#   cmake -Bbuild -Dpackage=on
#   cmake --build build -j1
#
# Usage:
#   cmake -Doutdir=~/gempkg -P scripts/package.cmake

cmake_minimum_required(VERSION 3.19...3.25)
# to save JSON metadata requires CMake >= 3.19

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/system_meta.cmake)

if(NOT DEFINED outdir)
  set(outdir ~/gemini_package)
endif()
get_filename_component(outdir ${outdir} ABSOLUTE)

if(NOT DEFINED bindir)
  set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build/package)
endif()
get_filename_component(bindir ${bindir} ABSOLUTE)
if(NOT IS_DIRECTORY ${bindir})
  message(FATAL_ERROR "did not find CPack directory ${bindir}")
endif()

if(NOT DEFINED top_archive)
  set(top_archive ${outdir}/gemini_package.tar)
endif()

# --- main program

file(MAKE_DIRECTORY ${outdir})
message(STATUS "Packing archives under ${outdir}")

file(READ ${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json meta)

set(jsonfile ${outdir}/manifest.json)
set(manifest_txt ${outdir}/manifest.txt)

file(COPY ${bindir}/manifest.txt DESTINATION ${outdir}/)

system_meta(${jsonfile})

file(APPEND ${manifest_txt}
"offline_install.cmake
libraries.json
")
file(COPY
${CMAKE_CURRENT_LIST_DIR}/offline_install.cmake
${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json
DESTINATION ${bindir}/
)

# --- create big archive file of CPack archive files

message(STATUS "Creating top-level source archive ${top_archive}")

execute_process(
COMMAND ${CMAKE_COMMAND} -E tar c ${top_archive} --files-from=${manifest_txt}
RESULT_VARIABLE ret
TIMEOUT 120
ERROR_VARIABLE err
WORKING_DIRECTORY ${bindir}
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to create archive ${top_archive}:
  ${ret}: ${err}")
endif()
