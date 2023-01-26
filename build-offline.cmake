# Build Gemini3D external libraries using local tarfile without internet.
#
# options:
#
# -Dprefix: where to install libraries under (default ~/libgem)
# -Dtarfile: where is the tarfile (default ./gemini_package.tar or ~/gemini_package.tar)

cmake_minimum_required(VERSION 3.14...3.25)
# Gemini3D currently requires CMake 3.14+

set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

# parallel build
if(CMAKE_GENERATOR MATCHES "Makefiles" AND NOT DEFINED ENV{CMAKE_BUILD_PARALLEL_LEVEL})
  cmake_host_system_information(RESULT Ncpu QUERY NUMBER_OF_PHYSICAL_CORES)
endif()

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

# extract big tarfile
message(STATUS "Extract ${tarfile} to ${arcdir}")
execute_process(
COMMAND ${CMAKE_COMMAND} -E tar x ${tarfile}
WORKING_DIRECTORY ${arcdir}
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Failed to extract ${tarfile} to ${arcdir}: ${ret}")
endif()

# build Gemini3D external libraries
set(gemini_ext_tar ${arcdir}/external.tar.bz2)

message(STATUS "Extract Gemini3D/external project ${gemini_ext_tar} in ${arcdir}")
execute_process(
COMMAND ${CMAKE_COMMAND} -E tar x ${gemini_ext_tar}
WORKING_DIRECTORY ${arcdir}
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3d/external tar failed to extract in ${arcdir}: ${ret}")
endif()

set(args
-DCMAKE_INSTALL_PREFIX:PATH=${prefix}
-DCMAKE_PREFIX_PATH:PATH=${prefix}
)

set(srcdir ${arcdir}/external)
set(bindir ${srcdir}/build)

message(STATUS "offline: build Gemini3D external libraries in ${bindir} with options:
${args}")

execute_process(
COMMAND ${CMAKE_COMMAND} ${args}
-Dlocal:PATH=${arcdir}
-B${bindir}
-S${srcdir}
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3D external libraries failed to configure.")
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

# --- build Gemini3D itself
set(gemini3d_tar ${arcdir}/gemini3d.tar.bz2)

message(STATUS "Extract Gemini3D project ${gemini3d_tar} in ${arcdir}")
execute_process(
COMMAND ${CMAKE_COMMAND} -E tar x ${gemini3d_tar}
WORKING_DIRECTORY ${arcdir}
RESULT_VARIABLE ret
)
if(NOT ret EQUAL 0)
  message(FATAL_ERROR "Gemini3d tar failed to extract in ${arcdir}: ${ret}")
endif()

set(gemini3d_src ${arcdir}/gemini3d)
set(gemini3d_bin ${gemini3d_src}/build)

message(STATUS "Building Gemini3D in ${gemini3d_src} with options:
${args}")

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