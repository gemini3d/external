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
DEPENDS ${depends}
)
if(package)
  list(APPEND extproj_args INSTALL_COMMAND "")
endif()
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.18)
  list(APPEND extproj_args GIT_REMOTE_UPDATE_STRATEGY "CHECKOUT")
endif()

if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.20)
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
    message(FATAL_ERROR "${name}: Archive file does not exist under ${local}")
  endif()

  if(name STREQUAL "hdf5")
    # special handling due to custom HDF5 archive layout
    # need to strip extra directories HDF_Group/HDF5/${HDF5_VERSION}
    find_program(tar NAMES tar)
    if(NOT tar)
      message(FATAL_ERROR "Could not find tar program")
    endif()

    set(_ext_src ${PROJECT_BINARY_DIR}/${name}_archive)
    file(MAKE_DIRECTORY ${_ext_src})

    execute_process(
    COMMAND ${tar} --extract --strip-components=4 --directory ${_ext_src} --file ${${name}_archive}
    RESULT_VARIABLE ret
    )
    if(NOT ret EQUAL "0")
      message(FATAL_ERROR "${name}: could not extract source archive ${${name}_archive}")
    endif()

    message(STATUS "${name}: using extracted source ${_ext_src}")

    ExternalProject_Add(${name}
    SOURCE_DIR ${_ext_src}
    TEST_COMMAND ""
    ${extproj_args}
    )

  else()
    # default archive without extra custom top-level directories
    message(STATUS "${name}: using source archive ${${name}_archive}")

    ExternalProject_Add(${name}
    URL ${${name}_archive}
    TEST_COMMAND ""
    ${extproj_args}
    )
  endif()

elseif(url_type STREQUAL "git")

  get_tag(${name} ${json_meta})

  ExternalProject_Add(${name}
  GIT_REPOSITORY ${url}
  GIT_TAG ${tag}
  GIT_SHALLOW true
  GIT_PROGRESS true
  TEST_COMMAND ""
  ${extproj_args}
  )
elseif(url_type STREQUAL "archive")

  get_hash(${name} ${json_meta})

  ExternalProject_Add(${name}
  URL ${url}
  URL_HASH SHA256=${sha256}
  TEST_COMMAND ""
  ${extproj_args}
  )
else()
  message(FATAL_ERROR "${name}: unsure how to use resource of type ${url_type}")
endif()


if(package)

ExternalProject_Add_Step(${name} CPackSource
COMMAND ${CMAKE_COMMAND}
  -Dpkgdir:PATH=${PROJECT_BINARY_DIR}/package
  -Dbindir:PATH=<BINARY_DIR>
  -Dname=${name}
  -Dcfg_name=CPackSourceConfig.cmake
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
DEPENDEES "CPackSource;build"
)
# CPackSource is a dependee to avoid race condition in ${pkgdir}/_CPack_Packaging directory.

endif()

endfunction(extproj)
