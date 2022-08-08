# prints Gemini3D prereqs on stdout
#  cmake -P scripts/requirements.cmake

cmake_minimum_required(VERSION 3.11...3.25)

if(CMAKE_VERSION VERSION_LESS 3.19)
  include(${CMAKE_CURRENT_LIST_DIR}/../cmake/Modules/JsonParse.cmake)
endif()

set(prereq_file ${CMAKE_CURRENT_LIST_DIR}/requirements.json)

# --- helper functions

function(read_prereqs sys_id)

  file(READ ${prereq_file} json)

  set(prereqs)

  if(CMAKE_VERSION VERSION_LESS 3.19)
    sbeParseJson(meta json)
    foreach(i IN LISTS meta.${sys_id}.pkgs)
      list(APPEND prereqs ${meta.${sys_id}.pkgs_${i}})
    endforeach()

    set(cmd ${meta.${sys_id}.cmd})
  else()
    string(JSON N LENGTH ${json} ${sys_id} pkgs)
    math(EXPR N "${N}-1")
    foreach(i RANGE ${N})
      string(JSON _u GET ${json} ${sys_id} pkgs ${i})
      list(APPEND prereqs ${_u})
    endforeach()

    string(JSON cmd GET ${json} ${sys_id} cmd)
  endif()

  string(REPLACE ";" " " prereqs "${prereqs}")
  set(prereqs ${prereqs} PARENT_SCOPE)
  set(cmd ${cmd} PARENT_SCOPE)

endfunction(read_prereqs)

# --- main program

execute_process(COMMAND uname -s OUTPUT_VARIABLE id TIMEOUT 5)

if(id MATCHES "^MINGW64")
  read_prereqs("msys2")
  execute_process(COMMAND ${CMAKE_COMMAND} -E echo "${cmd} ${prereqs}" TIMEOUT 2)
  return()
endif()

if(APPLE)
  set(names brew port)
elseif(UNIX)
  set(names apt yum pacman zypper)
elseif(WIN32)
  message(FATAL_ERROR "Windows: suggest Windows Subsystem for Linux (WSL) https://aka.ms/wsl ")
endif()

foreach(t IN LISTS names)
  find_program(${t} NAMES ${t})
  if(${t})
    read_prereqs(${t})
    execute_process(COMMAND ${CMAKE_COMMAND} -E echo "${cmd} ${prereqs}" TIMEOUT 2)
    return()
  endif()
endforeach()

message(FATAL_ERROR "Package manager not found ${names}")
