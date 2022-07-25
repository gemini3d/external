# install a recent CMake version
# we didn't use -P script to enable nicer features

cmake_minimum_required(VERSION 3.13...3.24)

project(cmake LANGUAGES NONE)

include(FetchContent)

# --- version
if(CMAKE_VERSION VERSION_LESS 3.19)
  set(version 3.23.2)
else()
  file(READ ${CMAKE_CURRENT_SOURCE_DIR}/../versions.json _j)

  if(version VERSION_LESS 3.1)
    string(JSON version GET ${_j} cmake latest)
  endif()

  # only major.minor specified -- default to latest release known.
  string(LENGTH ${version} L)
  if (L LESS 5)  # 3.x or 3.xx
    string(JSON version GET ${_j} cmake ${version})
  endif()
endif()


function(unknown_archive)

message(FATAL_ERROR "No CMake ${version} binary download available for ${arch}.
Try building CMake from source:
  cmake -S ${CMAKE_CURRENT_SOURCE_DIR}/build_cmake -B build
or use Python:
  pip install cmake
or use Snap:
  snap install cmake"
)

endfunction(unknown_archive)


function(cmake_archive_name file_json out)
# CMake >= 3.20 dynamic filename

# system name to OS index
string(TOLOWER ${CMAKE_HOST_SYSTEM_NAME} sname)
string(REPLACE "darwin" "macos" sname ${sname})

# system arch to arch index
string(TOLOWER ${CMAKE_HOST_SYSTEM_PROCESSOR} arch)
if(WIN32)
  if(arch STREQUAL "x86")
    set(arch "i386")
  elseif(arch STREQUAL "amd64")
    set(arch "x86_64")
  endif()
endif()


function(iter_json json key pat out)

unset(${out} PARENT_SCOPE)

string(JSON L LENGTH ${json} ${key})

math(EXPR L "${L} - 1")

foreach(i RANGE ${L})
  string(JSON o GET ${json} ${key} ${i})
  # message(DEBUG "pat: ${pat}   o: ${o}")
  if(pat STREQUAL o)
    set(${out} ${o} PARENT_SCOPE)
    # message(DEBUG "${out}: ${o}")
    return()
  endif()
endforeach()

endfunction(iter_json)


file(READ ${file_json} json)

string(JSON Lf LENGTH ${json} "files")
math(EXPR Lf "${Lf} - 1")

foreach(i RANGE ${Lf})

  string(JSON d GET ${json} "files" ${i})
  iter_json("${d}" "os" "${sname}" "os_key")
  if(NOT os_key)
    continue()
  endif()
  # message(DEBUG "os_key: ${os_key}")

  string(JSON d GET ${json} "files" ${i})
  iter_json("${d}" "architecture" "${arch}" "arch_key")
  if(NOT arch_key)
    continue()
  endif()
  message(DEBUG "os_key: ${os_key}  arch_key: ${arch_key}")

  string(JSON c GET ${json} "files" ${i} "class")
  if(NOT c STREQUAL "archive")
    continue()
  endif()

  string(JSON filename GET ${json} "files" ${i} "name")
  break()

endforeach()

if(NOT filename)
  unknown_archive()
endif()

set(${out} ${filename} PARENT_SCOPE)

endfunction(cmake_archive_name)


function(cmake_legacy_name out)
# CMake < 3.20 static filename

if(APPLE)

if(version VERSION_LESS 3.19)
  set(file_arch Darwin-x86_64)
else()
  set(file_arch macos-universal)
endif()

elseif(UNIX)

if(version VERSION_LESS 3.20)
  set(file_arch L)
else()
  set(file_arch l)
endif()
string(APPEND file_arch inux-${CMAKE_HOST_SYSTEM_PROCESSOR})

elseif(WIN32)

if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "ARM64")
  if(version VERSION_GREATER_EQUAL 3.24)
    set(file_arch windows-arm64)
  endif()
elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "AMD64")
  if(version VERSION_LESS 3.6)
    set(file_arch win32-x86)
  elseif(version VERSION_LESS 3.20)
    set(file_arch win64-x64)
  else()
    set(file_arch windows-x86_64)
  endif()
elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86")
  if(version VERSION_LESS 3.20)
    set(file_arch win32-x86)
  else()
    set(file_arch windows-i386)
  endif()
endif()

endif()


if(NOT file_arch)
  unknown_archive()
endif()

if(UNIX)
  set(suffix .tar.gz)
else()
  set(suffix .zip)
endif()

set(${out} cmake-${version}-${file_arch}${suffix} PARENT_SCOPE)

endfunction(cmake_legacy_name)


if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  get_filename_component(p ~ ABSOLUTE)
  set(CMAKE_INSTALL_PREFIX ${p} CACHE PATH "install path" FORCE)
endif()

set(path ${CMAKE_INSTALL_PREFIX}/cmake-${version})

# --- auto-ignore build directory
if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/.gitignore)
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/.gitignore "*")
endif()

find_program(exe1
NAMES cmake
HINTS ${path}
PATH_SUFFIXES bin
NO_DEFAULT_PATH
NO_CACHE
)
if(exe1)
  message(STATUS "CMake already installed at ${exe1}")
  return()
endif()

set(url_stem https://github.com/Kitware/CMake/releases/download/v${version})

if(CMAKE_VERSION VERSION_LESS 3.19 OR version VERSION_LESS 3.20)
  cmake_legacy_name("archive")
else()
  set(json_name cmake-${version}-files-v1.json)
  set(json_file ${CMAKE_CURRENT_BINARY_DIR}/${json_name})
  set(json_url ${url_stem}/cmake-${version}-files-v1.json)

  message(STATUS "CMake ${version} metadata: ${json_url} => ${json_file}")
  file(DOWNLOAD ${json_url} ${json_file} INACTIVITY_TIMEOUT 60 TLS_VERIFY true STATUS ret)
  list(GET ret 0 stat)
  if(NOT stat EQUAL 0)
    list(GET ret 1 err)
    message(FATAL_ERROR "CMake metadata download failed: ${err}")
  endif()

  cmake_archive_name(${json_file} "archive")
endif()

set(archive_url ${url_stem}/${archive})

message(STATUS "Download CMake ${version}")

set(FETCHCONTENT_QUIET false)

FetchContent_Declare(cmake
URL ${archive_url}
TLS_VERIFY true
UPDATE_DISCONNECTED true
INACTIVITY_TIMEOUT 60
)

FetchContent_Populate(cmake)

message(STATUS "Install CMake ${version} under ${path}   (takes about a minute or so)")
file(MAKE_DIRECTORY ${path})
file(COPY ${cmake_SOURCE_DIR}/ DESTINATION ${path})
# must have trailing slash on source dir

# --- verify
find_program(exe2
NAMES cmake
HINTS ${path}
PATH_SUFFIXES bin
NO_DEFAULT_PATH
NO_CACHE
)
if(NOT exe2)
  message(FATAL_ERROR "failed to install CMake ${version} to ${path}")
endif()

message(STATUS "installed CMake ${version} to ${path}")

set(bindir ${path}/bin)

set(ep $ENV{PATH})
if(NOT ep MATCHES "${bindir}")
  message(STATUS "add to environment variable PATH ${bindir}")
endif()
