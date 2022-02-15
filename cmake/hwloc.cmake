find_package(LibXml2)

if(WIN32)

set(hwloc_cmake_args
-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
-DCMAKE_BUILD_TYPE=Release
-DHWLOC_ENABLE_TESTING:BOOL=off
)

if(NOT LibXml2_FOUND)
  list(APPEND hwloc_cmake_args --disable-libxml2)
endif()

ExternalProject_Add(HWLOC
URL ${hwloc_url}
URL_HASH SHA256=${hwloc_sha256}
CMAKE_ARGS ${hwloc_cmake_args}
CMAKE_GENERATOR ${EXTPROJ_GEN}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
TEST_COMMAND ""
SOURCE_SUBDIR contrib/windows-cmake
)

else()

if(NOT MAKE_EXECUTABLE)
  message(FATAL_ERROR "HWLOC requires GNU Make.")
endif()

if(BUILD_SHARED_LIBS)
  set(hwloc_args --enable-shared --disable-static)
else()
  set(hwloc_args --disable-shared --enable-static)
endif()

if(NOT LibXml2_FOUND)
  list(APPEND hwloc_args --disable-libxml2)
endif()

ExternalProject_Add(HWLOC
URL ${hwloc_url}
URL_HASH SHA256=${hwloc_sha256}
CONFIGURE_COMMAND ${PROJECT_BINARY_DIR}/HWLOC-prefix/src/HWLOC/configure --prefix=${CMAKE_INSTALL_PREFIX} ${hwloc_args}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j install
TEST_COMMAND ""
CONFIGURE_HANDLED_BY_BUILD ON
INACTIVITY_TIMEOUT 15
)

endif()
