include(ExternalProject)

include(${CMAKE_CURRENT_LIST_DIR}/GetJson.cmake)


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

if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.19)
  list(APPEND extproj_args
  INACTIVITY_TIMEOUT 60
  CONFIGURE_HANDLED_BY_BUILD true
  )
endif()

get_url(${name} ${json_meta})

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

  get_tag(${name} ${json_meta})

  ExternalProject_Add(${name}
  GIT_REPOSITORY ${url}
  GIT_TAG ${tag}
  GIT_SHALLOW true
  ${extproj_args}
  )
elseif(url_type STREQUAL "archive")

  get_hash(${name} ${json_meta})

  ExternalProject_Add(${name}
  URL ${url}
  URL_HASH SHA256=${sha256}
  ${extproj_args}
  )
else()
  message(FATAL_ERROR "unsure how to use resource of type ${url_type}")
endif()


if(package)

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
