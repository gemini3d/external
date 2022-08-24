# Creates archive file of archive filess from all packages Git tags.
# This is to avoid problems with having ~ million files in a single archive.
#
# this allows for an offline-installer script
#
# Usage:
#   cmake -Doutdir=~/gempkg -P scripts/package.cmake

cmake_minimum_required(VERSION 3.19...3.25)
# to save JSON metadata, we use CMake >= 3.19

include(${CMAKE_CURRENT_LIST_DIR}/../cmake/git.cmake)

if(NOT DEFINED outdir)
  set(outdir ~/gemini_package)
endif()
get_filename_component(outdir ${outdir} ABSOLUTE)

if(NOT DEFINED top_archive)
  set(top_archive ${outdir}/gemini_package.tar)
endif()

if(NOT DEFINED packages)

set(packages
gemini3d external
libsc p4est forestclaw
iniparser
ffilesystem
h5fortran hdf5 zlib
glow hwm14 msis
lapack lapack_src
scalapack scalapack_src
mumps mumps_src
)

endif()

set(CMAKE_TLS_VERIFY true)

# --- functions

function(tar_create pkg archive dir)

set(exclude --exclude-vcs --exclude=.github/)
if(pkg STREQUAL "hdf5")
  list(APPEND exclude --exclude=testfiles/ --exclude=doxygen/ --exclude=java/ --exclude=tools/test/ --exclude=release_docs/ --exclude=c++/ --exclude=examples/ --exclude=configure)
elseif(pkg STREQUAL "lapack_src")
  list(APPEND exclude --exclude=TESTING/ --exclude=LAPACKE/ --exclude=CBLAS/ --exclude=DOCS/ --exclude=CMAKE/)
elseif(pkg STREQUAL "scalapack_src")
  list(APPEND exclude --exclude=TESTING/ --exclude=TIMING/ --exclude=CMAKE/)
endif()

message(STATUS "${pkg}: create archive ${archive}")
execute_process(
COMMAND ${tar} --create --file ${archive} --bzip2 ${exclude} .
WORKING_DIRECTORY ${dir}
TIMEOUT 120
RESULT_VARIABLE ret
ERROR_VARIABLE err
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "${pkg}: Failed to create archive ${archive}:
  ${ret}: ${err}")
endif()

endfunction(tar_create)


function(download_archive pkg url archive sha256)

# assume archive directly
file(DOWNLOAD ${url} ${archive}
INACTIVITY_TIMEOUT 60
EXPECTED_HASH SHA256=${sha256}
SHOW_PROGRESS
STATUS ret
)
list(GET ret 0 stat)
if(stat EQUAL 0)
  message(STATUS "${pkg}: ${ret}")
else()
  message(FATAL_ERROR "${pkg}: archive download failed: ${ret}")
endif()

endfunction(download_archive)


function(system_meta jsonfile)

# metadata creation
if(EXISTS ${jsonfile})
  file(READ ${jsonfile} json)
else()
  set(json "{}")
endif()
message(STATUS "Writing package metadata to ${jsonfile}")

# system metadata
execute_process(COMMAND ${tar} --version
OUTPUT_VARIABLE tar_version
OUTPUT_STRIP_TRAILING_WHITESPACE
RESULT_VARIABLE ret
TIMEOUT 5
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "tar ${tar} isn't working")
endif()

string(JSON json SET ${json} "system" "{}")
string(JSON json SET ${json} "system" "cmake" \"${CMAKE_VERSION}\")
string(JSON json SET ${json} "system" "git" \"${GIT_VERSION_STRING}\")
string(JSON json SET ${json} "system" "tar" \"${tar_version}\")
string(TIMESTAMP time UTC)
string(JSON json SET ${json} "system" "time" \"${time}\")

string(JSON m ERROR_VARIABLE e GET "packages")
if(NOT m)
  string(JSON json SET ${json} "packages" "{}")
endif()

set(json ${json} PARENT_SCOPE)

endfunction(system_meta)


# --- main program

file(MAKE_DIRECTORY ${outdir})
message(STATUS "Packing archives under ${outdir}")

file(READ ${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json meta)

find_program(tar NAMES tar REQUIRED)

set(jsonfile ${outdir}/manifest.json)
set(manifest_txt ${outdir}/manifest.txt)

file(WRITE ${manifest_txt}
"manifest.json
")

system_meta(${jsonfile})


foreach(pkg IN LISTS packages)

set(wd ${outdir}/${pkg})

string(JSON url GET ${meta} ${pkg} url)


if(pkg STREQUAL "mumps_src")
  set(archive_name ${pkg}.tar.gz)
else()
  set(archive_name ${pkg}.tar.bz2)
endif()
set(archive ${outdir}/${archive_name})

if(url MATCHES "\.git$")
  # clone shallow, then make archive
  message(STATUS "${pkg}: Git: ${url}")

  string(JSON ${pkg}_tag GET ${meta} ${pkg} "tag")

  git_clone(${pkg} ${url} ${${pkg}_tag} ${wd})

  tar_create(${pkg} ${archive} ${wd})

else()
  message(STATUS "${pkg}: archive: ${url} => ${archive}")

  string(JSON ${pkg}_sha256 GET ${meta} ${pkg} sha256)

  download_archive(${pkg} ${url} ${archive} ${${pkg}_sha256})
endif()

# meta for this package
string(JSON json SET ${json} "packages" ${pkg} "{}")
string(JSON json SET ${json} "packages" ${pkg} "archive" \"${archive_name}\")

if(${pkg}_tag)
  string(JSON json SET ${json} "packages" ${pkg} "tag" \"${${pkg}_tag}\")
endif()

string(TIMESTAMP time UTC)
string(JSON json SET ${json} "packages" ${pkg} "time" \"${time}\")

file(SHA256 ${archive} sha256)
string(JSON json SET ${json} "packages" ${pkg} "sha256" \"${sha256}\")

message(DEBUG "${json}")
file(WRITE ${jsonfile} "${json}")
file(APPEND ${manifest_txt}
"${archive_name}
")
# write meta for each file in case of error, so that we don't waste prior effort

endforeach()

# append scripts/offline_install.cmake
file(APPEND ${manifest_txt}
"offline_install.cmake
")
file(COPY ${CMAKE_CURRENT_LIST_DIR}/offline_install.cmake DESTINATION ${outdir}/)


# --- create one big archive file of all the archive files above

message(STATUS "Creating top-level archive ${top_archive} of:
${packages}")

execute_process(
COMMAND ${tar} --create --file ${top_archive} --no-recursion --files-from ${manifest_txt}
RESULT_VARIABLE ret
TIMEOUT 120
RESULT_VARIABLE ret
ERROR_VARIABLE err
WORKING_DIRECTORY ${outdir}
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to create archive ${top_archive}:
  ${ret}: ${err}")
endif()
