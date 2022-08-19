# Creates Zstd archives from all packages Git tags using "git archive"
# this allows for an offline-installer script
#
# Usage:
#   cmake -Doutdir=~/gempkg -P scripts/package.cmake

cmake_minimum_required(VERSION 3.19...3.25)

if(NOT DEFINED outdir)
  set(outdir ~/gemini_package)
endif()

set(CMAKE_TLS_VERIFY true)

get_filename_component(outdir ${outdir} ABSOLUTE)
file(MAKE_DIRECTORY ${outdir})
message(STATUS "Packing archives under ${outdir}")

file(READ ${CMAKE_CURRENT_LIST_DIR}/../cmake/libraries.json meta)

set(package_names
iniparser
ffilesystem
h5fortran hdf5 zlib
glow hwm14 msis
lapack lapack_src
scalapack scalapack_src
mumps mumps_src
)

# --- main program

find_program(git NAMES git REQUIRED)
find_program(tar NAMES tar REQUIRED)

foreach(p IN LISTS package_names)

set(wd ${outdir}/${p})
if(IS_DIRECTORY ${wd})
  message(STATUS "${p}: ${wd} exists, SKIPPING package")
  continue()
endif()

if(p STREQUAL "mumps_src")
  set(pfile ${outdir}/${p}.tar.gz)
else()
  set(pfile ${outdir}/${p}.tar.bz2)
endif()

set(exclude --exclude-vcs --exclude=.github/)
if(p STREQUAL "hdf5")
  list(APPEND exclude --exclude=testfiles/ --exclude=doxygen/ --exclude=java/ --exclude=tools/test/ --exclude=release_docs/ --exclude=c++/ --exclude=examples/ --exclude=configure)
elseif(p STREQUAL "lapack_src")
  list(APPEND exclude --exclude=TESTING/ --exclude=LAPACKE/ --exclude=CBLAS/ --exclude=DOCS/ --exclude=CMAKE/)
elseif(p STREQUAL "scalapack_src")
  list(APPEND exclude --exclude=TESTING/ --exclude=TIMING/ --exclude=CMAKE/)
endif()

string(JSON url GET ${meta} ${p} url)



if(url MATCHES "\.git$")
  # clone shallow, then make archive
  message(STATUS "${p}: Git: ${url}")

  string(JSON tag GET ${meta} ${p} tag)

  # NOTE: "git archive" doesn't work with most modern servers.
  execute_process(
  COMMAND ${git} clone ${url} --depth 1 --branch ${tag} --single-branch ${wd}
  TIMEOUT 120
  )

  message(STATUS "Creating archive ${pfile}")
  execute_process(
  COMMAND ${tar} --create --file ${pfile} --bzip2 ${exclude} .
  WORKING_DIRECTORY ${wd}
  TIMEOUT 120
  COMMAND_ECHO STDOUT
  )

else()

  message(STATUS "${p}: archive: ${url} => ${pfile}")

  string(JSON sha256 GET ${meta} ${p} sha256)

  # assume archive directly
  file(DOWNLOAD ${url} ${pfile}
  INACTIVITY_TIMEOUT 60
  EXPECTED_HASH SHA256=${sha256}
  SHOW_PROGRESS
  STATUS ret
  )
  list(GET ret 0 stat)
  if(stat EQUAL 0)
    message(STATUS "${p}: ${ret}")
  else()
    message(FATAL_ERROR "${p}: archive download failed: ${ret}")
  endif()

endif()



endforeach()
