find_package(LibXml2)

string(JSON hwloc_url GET ${json_meta} hwloc url)
string(JSON hwloc_sha256 GET ${json_meta} hwloc sha256)

if(WIN32)

set(hwloc_cmake_args
-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
-DCMAKE_PREFIX_PATH:PATH=${CMAKE_INSTALL_PREFIX}
-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
-DHWLOC_ENABLE_TESTING:BOOL=off
)

if(LibXml2_FOUND)
  list(APPEND hwloc_cmake_args -DHWLOC_WITH_LIBXML2:BOOL=true)
endif()

ExternalProject_Add(hwloc
URL ${hwloc_url}
URL_HASH SHA256=${hwloc_sha256}
CMAKE_ARGS ${hwloc_cmake_args}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
TEST_COMMAND ""
SOURCE_SUBDIR contrib/windows-cmake
)

else()

if(NOT MAKE_EXECUTABLE)
  message(FATAL_ERROR "HWLOC requires GNU Make.")
endif()
if(NOT Autotools_FOUND)
  message(FATAL_ERROR "HWLOC on Unix-like systems requires Autotools")
endif()

if(BUILD_SHARED_LIBS)
  set(hwloc_args --enable-shared --disable-static)
else()
  set(hwloc_args --disable-shared --enable-static)
endif()

if(NOT LibXml2_FOUND)
  list(APPEND hwloc_args --disable-libxml2)
endif()

ExternalProject_Add(hwloc
URL ${hwloc_url}
URL_HASH SHA256=${hwloc_sha256}
CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX} ${hwloc_args}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j install
TEST_COMMAND ""
CONFIGURE_HANDLED_BY_BUILD ON
INACTIVITY_TIMEOUT 15
)

endif()
