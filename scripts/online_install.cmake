# Build Gemini3D external libraries using internet connection to download
# options:
#
# -Dprefix: where to install libraries under (default ~/libgem_<compiler_id>)

cmake_minimum_required(VERSION 3.13)

set(wd ${CMAKE_CURRENT_LIST_DIR}/../build)

# heuristic to determine compiler family.
if(NOT bindir)
  if(DEFINED ENV{MKLROOT})
    set(cc_name icx icc icl cc)
  else()
    set(cc_name cc)
  endif()
  find_program(CC NAMES $ENV{CC} ${cc_name})

  set(bin_name generic)
  if(CC)
    execute_process(
    COMMAND ${CC} ${CMAKE_CURRENT_LIST_DIR}/compiler_id.c -o ${wd}/compiler_id
    RESULT_VARIABLE ret
    TIMEOUT 20
    )
    if(ret EQUAL 0)
      execute_process(
      COMMAND ${wd}/compiler_id
      OUTPUT_VARIABLE out
      OUTPUT_STRIP_TRAILING_WHITESPACE
      RESULT_VARIABLE ret
      TIMEOUT 5
      )
    endif()
    message(DEBUG "Identify C compiler ${CC} with id ${out}:  ${ret}")
    if(ret EQUAL 0)
      set(bin_name ${out})
    endif()
  endif()

  set(bindir ${CMAKE_CURRENT_LIST_DIR}/../build_${bin_name})
endif()
get_filename_component(bindir ${bindir} ABSOLUTE)

# need to remove cache to avoid corner cases
file(REMOVE ${bindir}/CMakeCache.txt)

set(args)
if(prefix)
  list(APPEND args -DCMAKE_INSTALL_PREFIX:PATH=${prefix})
else()
  list(APPEND args -DCMAKE_INSTALL_PREFIX:PATH=~/libgem_${bin_name})
endif()


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
