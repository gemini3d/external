if(WIN32)
  message(FATAL_ERROR "On Windows, Python is available from Microsoft Store.")
endif()

if(NOT MAKE_EXECUTABLE)
  message(FATAL_ERROR "Python requires GNU Make.")
endif()


string(JSON python_url GET ${json_meta} python url)
string(JSON python_sha256 GET ${json_meta} python sha256)

set(python_args
--enable-optimizations
)

ExternalProject_Add(python
URL ${python_url}
URL_HASH SHA256=${python_sha256}
CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=${CMAKE_INSTALL_PREFIX} ${python_args}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j install
TEST_COMMAND ""
CONFIGURE_HANDLED_BY_BUILD ON
INACTIVITY_TIMEOUT 15
)
