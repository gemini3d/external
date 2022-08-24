# Build Gemini3D external libraries using local tarfile without internet.
#
# options:
#
# -Dprefix: where to install libraries under (default ~/libgem)
# -Dtarfile: where is the tarfile (default ./gemini_package.tar or ~/gemini_package.tar)
# -Dbindir: where to build libraries under

cmake_minimum_required(VERSION 3.17)

set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

if(NOT bindir)
  set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build)
endif()
get_filename_component(bindir ${bindir} ABSOLUTE)

if(NOT prefix)
  set(prefix ~/libgem)
endif()
get_filename_component(prefix ${prefix} ABSOLUTE)

# find tarfile
if(NOT tarfile)
  find_file(tarfile NAMES gemini_package.tar
  PATHS . ENV HOME ENV USERPROFILE
  NO_DEFAULT_PATH
  )
  if(NOT tarfile)
    message(FATAL_ERROR "Could not find gemini_package.tar
    Specify like:
    cmake -Dtarfile=<fullpath to gemini_package.tar> -P ${CMAKE_CURRENT_LIST_FILE}")
  endif()
endif()
get_filename_component(tarfile ${tarfile} ABSOLUTE)
get_filename_component(arcdir ${tarfile} DIRECTORY)

# extract tarfile
message(STATUS "Extracting ${tarfile} to ${arcdir}")
execute_process(
COMMAND ${CMAKE_COMMAND} -E tar x ${tarfile}
WORKING_DIRECTORY ${arcdir}
TIMEOUT 120
)

set(args
-Dlocal:BOOL=${arcdir}
-DCMAKE_INSTALL_PREFIX:PATH=${prefix}
-DCMAKE_PREFIX_PATH:PATH=${prefix}
)

message(STATUS "offline: build Gemini3D external libraries in ${bindir} with options:
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

# --- Gemini3D

set(gemini3d_src ${arcdir})
set(gemini3d_bin ${gemini3d_src}/build)

message(STATUS "Building Gemini3D in ${gemini3d_src} with options:
${args}")

execute_process(
COMMAND ${CMAKE_COMMAND} -E tar x gemini3d.tar.bz2
WORKING_DIRECTORY ${arcdir}
TIMEOUT 120
)

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-B${gemini3d_bin}
-S${gemini3d_src}
RESULT_VARIABLE ret
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3D failed to configure.")
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} --build ${gemini3d_bin}
RESULT_VARIABLE ret
)
if(ret EQUAL 0)
  message(STATUS "Gemini3D build complete.")
else()
  message(FATAL_ERROR "Gemini3D failed to build.")
endif()

execute_process(
COMMAND ${CMAKE_COMMAND} --install ${gemini3d_bin}
RESULT_VARIABLE ret
)
if(ret EQUAL 0)
  message(STATUS "Gemini3D install complete.")
else()
  message(FATAL_ERROR "Gemini3D failed to install.")
endif()
