include(ExternalProject)

if(CMAKE_VERSION VERSION_LESS 3.19)
  include(${CMAKE_CURRENT_LIST_DIR}/Modules/JsonParse.cmake)
endif()


function(get_tag name)

if(CMAKE_VERSION VERSION_LESS 3.19)
  set(tag ${meta.${name}.tag})
else()
  string(JSON tag GET ${json_meta} ${name} tag)
endif()

set(tag ${tag} PARENT_SCOPE)

endfunction(get_tag)


function(get_hash name)

if(CMAKE_VERSION VERSION_LESS 3.19)
  set(sha256 ${meta.${name}.sha256})
else()
  string(JSON sha256 GET ${json_meta} ${name} sha256)
endif()

set(sha256 ${sha256} PARENT_SCOPE)

endfunction(get_hash)


function(extproj name url_type cmake_args depends)

# PREPEND so that user arguments can override these defaults
list(INSERT cmake_args 0
-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
-DCMAKE_PREFIX_PATH:PATH=${CMAKE_INSTALL_PREFIX}
-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
-DBUILD_TESTING:BOOL=false
)
if(CMAKE_TOOLCHAIN_FILE)
  list(APPEND cmake_args -DCMAKE_TOOLCHAIN_FILE:FILEPATH=${CMAKE_TOOLCHAIN_FILE})
endif()
if(package)
  list(APPEND cmake_args
  -DCPACK_SOURCE_PACKAGE_FILE_NAME=${name}
  -DCPACK_PACKAGE_FILE_NAME=${name}-${CMAKE_SYSTEM_NAME}
  )
  file(APPEND ${manifest_txt}
  "${name}.tar.bz2
${name}-${CMAKE_SYSTEM_NAME}.tar.bz2
")
endif()

set(extproj_args
CMAKE_ARGS ${cmake_args}
TLS_VERIFY true
TEST_COMMAND ""
DEPENDS ${depends}
)
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.18)
  list(APPEND extproj_args GIT_REMOTE_UPDATE_STRATEGY "CHECKOUT")
endif()

if(CMAKE_VERSION VERSION_LESS 3.19)
  sbeParseJson(meta json_meta)
  set(url ${meta.${name}.url})
else()
  string(JSON url GET ${json_meta} ${name} url)
  list(APPEND extproj_args
  INACTIVITY_TIMEOUT 60
  CONFIGURE_HANDLED_BY_BUILD true
  )
endif()


if(local)
  # archive file on this computer or network drive

  find_file(${name}_archive
  NAMES ${name}.tar.bz2 ${name}.tar.gz ${name}.tar ${name}.zip ${name}.zstd ${name}.tar.xz
  HINTS ${local}
  NO_DEFAULT_PATH
  )

  if(NOT ${name}_archive)
    message(FATAL_ERROR "Archive file for ${name} does not exist under ${local}")
  endif()

  message(STATUS "${name}: using source archive ${${name}_archive}")

  ExternalProject_Add(${name}
  URL ${${name}_archive}
  ${extproj_args}
  )

elseif(url_type STREQUAL "git")

  get_tag(${name})

  ExternalProject_Add(${name}
  GIT_REPOSITORY ${url}
  GIT_TAG ${tag}
  GIT_SHALLOW true
  ${extproj_args}
  )
elseif(url_type STREQUAL "archive")

  get_hash(${name})

  ExternalProject_Add(${name}
  URL ${url}
  URL_HASH SHA256=${sha256}
  ${extproj_args}
  )
else()
  message(FATAL_ERROR "unsure how to use resource of type ${url_type}")
endif()


if(package)

# for project not controlled by us, CPack may not be enabled
# no problem, we override with our CPackConfig

ExternalProject_Add_Step(${name} CPackSource
COMMAND ${CMAKE_COMMAND}
  -Dpkgdir:PATH=${PROJECT_BINARY_DIR}/package
  -Dbindir:PATH=<BINARY_DIR>
  -Dname=${name}
  -Dcfg_name=CPackSourceConfig.cmake
  -Dsys_name=${CMAKE_SYSTEM_NAME}
  -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/package/cpack_run.cmake
DEPENDEES configure
)

ExternalProject_Add_Step(${name} CPackBinary
COMMAND ${CMAKE_COMMAND}
  -Dpkgdir:PATH=${PROJECT_BINARY_DIR}/package
  -Dbindir:PATH=<BINARY_DIR>
  -Dname=${name}
  -Dcfg_name=CPackConfig.cmake
  -Dsys_name=${CMAKE_SYSTEM_NAME}
  -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/package/cpack_run.cmake
DEPENDEES build
)

endif()

endfunction(extproj)


function(fetch_source name url_type)

set(extproj_args
CMAKE_ARGS ${cmake_args}
TLS_VERIFY true
UPDATE_DISCONNECTED true
TEST_COMMAND ""
)
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.18)
  list(APPEND extproj_args GIT_REMOTE_UPDATE_STRATEGY "CHECKOUT")
endif()

if(CMAKE_VERSION VERSION_LESS 3.19)
  sbeParseJson(meta json_meta)
  set(url ${meta.${name}.url})
else()
  string(JSON url GET ${json_meta} ${name} url)
  list(APPEND extproj_args
  INACTIVITY_TIMEOUT 60
  CONFIGURE_HANDLED_BY_BUILD true
  )
endif()

if(url_type STREQUAL "git")

get_tag(${name})

ExternalProject_Add(${name}
GIT_REPOSITORY ${url}
GIT_TAG ${tag}
GIT_SHALLOW true
GIT_PROGRESS true
${extproj_args}
CONFIGURE_COMMAND ""
BUILD_COMMAND ${CMAKE_COMMAND} -Dpkg=${name} -Darchive=${PROJECT_BINARY_DIR}/package/${name}.tar.bz2 -Ddir:PATH=<SOURCE_DIR> -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/tar.cmake
INSTALL_COMMAND ""
)

elseif(url_type STREQUAL "archive")

get_hash(${name})

ExternalProject_Add(${name}
URL ${url}
URL_HASH SHA256=${sha256}
${extproj_args}
CONFIGURE_COMMAND ""
BUILD_COMMAND ${CMAKE_COMMAND} -E copy <DOWNLOADED_FILE> ${PROJECT_BINARY_DIR}/package/
INSTALL_COMMAND ""
DOWNLOAD_NO_EXTRACT true
DOWNLOAD_NAME ${name}.bz2
)

endif()


endfunction(fetch_source)
