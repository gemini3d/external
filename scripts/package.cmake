# Creates Zstd archives from all packages Git tags using "git archive"
# this allows for an offline-installer script
#
# Usage:
#   cmake -Doutdir=~/gempkg -P scripts/package.cmake

cmake_minimum_required(VERSION 3.19...3.25)
# to save JSON metadata, we use CMake >= 3.19

if(NOT DEFINED outdir)
  set(outdir ~/gemini_package)
endif()

set(CMAKE_TLS_VERIFY true)

get_filename_component(outdir ${outdir} ABSOLUTE)
file(MAKE_DIRECTORY ${outdir})
message(STATUS "Packing archives under ${outdir}")

file(READ ${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json meta)

set(packages
iniparser
ffilesystem
h5fortran hdf5 zlib
glow hwm14 msis
lapack lapack_src
scalapack scalapack_src
mumps mumps_src
)

# --- functions

function(git_clone pkg url tag dir)

# NOTE: "git archive" doesn't work with most modern servers.

if(IS_DIRECTORY ${dir})
  execute_process(COMMAND ${GIT_EXECUTABLE} -C ${dir} describe --tags
  RESULT_VARIABLE ret
  OUTPUT_STRIP_TRAILING_WHITESPACE
  OUTPUT_VARIABLE out
  TIMEOUT 5
  )
  if(ret EQUAL 0 AND out STREQUAL "${tag}")
    message(STATUS "${pkg}: Already up-to-date")
    return()
  endif()
endif()

execute_process(
COMMAND ${GIT_EXECUTABLE} clone ${url} --depth 1 --branch ${tag} --single-branch ${dir}
TIMEOUT 120
RESULT_VARIABLE ret
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "${pkg}: Failed to Git clone ${url} to ${dir}")
endif()

endfunction(git_clone)


function(tar_create pkg archive dir)

set(exclude --exclude-vcs --exclude=.github/)
if(pkg STREQUAL "hdf5")
  list(APPEND exclude --exclude=testfiles/ --exclude=doxygen/ --exclude=java/ --exclude=tools/test/ --exclude=release_docs/ --exclude=c++/ --exclude=examples/ --exclude=configure)
elseif(pkg STREQUAL "lapack_src")
  list(APPEND exclude --exclude=TESTING/ --exclude=LAPACKE/ --exclude=CBLAS/ --exclude=DOCS/ --exclude=CMAKE/)
elseif(pkg STREQUAL "scalapack_src")
  list(APPEND exclude --exclude=TESTING/ --exclude=TIMING/ --exclude=CMAKE/)
endif()

message(STATUS "Creating archive ${archive}")
execute_process(
COMMAND ${tar} --create --file ${archive} --bzip2 ${exclude} .
WORKING_DIRECTORY ${dir}
TIMEOUT 120
COMMAND_ECHO STDOUT
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

find_package(Git REQUIRED)
find_program(tar NAMES tar REQUIRED)

set(jsonfile ${outdir}/manifest.json)

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
elseif(${pkg}_sha256)
  string(JSON json SET ${json} "packages" ${pkg} "sha256" \"${${pkg}_sha256}\")
endif()

string(TIMESTAMP time UTC)
string(JSON json SET ${json} "packages" ${pkg} "time" \"${time}\")

file(SHA256 ${archive} sha256)
string(JSON json SET ${json} "packages" ${pkg} "sha256" \"${sha256}\")

message(DEBUG "${json}")
file(WRITE ${jsonfile} "${json}")
# write meta for each file in case of error, so that we don't waste prior effort

endforeach()
