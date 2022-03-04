string(JSON python_url GET ${json_meta} python url)
string(JSON python_sha256 GET ${json_meta} python sha256)

if(WIN32)
  # https://pythondev.readthedocs.io/windows.html

  message(WARNING "On Windows, Python is available from Microsoft Store.
Python building on Windows requires Visual Studio, which doesn't work with other external libraries.")

  ExternalProject_Add(python
  URL ${python_url}
  URL_HASH SHA256=${python_sha256}
  CONFIGURE_COMMAND ""
  BUILD_COMMAND <SOURCE_DIR>/PCBuild/build.bat
  INSTALL_COMMAND ""
  TEST_COMMAND ""
  CONFIGURE_HANDLED_BY_BUILD ON
  INACTIVITY_TIMEOUT 15
  )

else()
  # Linux prereqs: https://devguide.python.org/setup/#linux

  set(python_args
  --prefix=${CMAKE_INSTALL_PREFIX}
  CC=${CMAKE_C_COMPILER}
  CXX=${CMAKE_CXX_COMPILER}
  LDFLAGS=${CMAKE_LIBRARY_PATH_FLAG} ${CMAKE_INSTALL_PREFIX}/lib64 -Wl,-rpath ${CMAKE_INSTALL_PREFIX}/lib64
  )

  if(NOT MAKE_EXECUTABLE)
    message(FATAL_ERROR "Python requires GNU Make.")
  endif()

  include(cmake/expat.cmake)
  include(cmake/ffi.cmake)
  include(cmake/ssl.cmake)

  ExternalProject_Add(python
  URL ${python_url}
  URL_HASH SHA256=${python_sha256}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure ${python_args}
  BUILD_COMMAND ${MAKE_EXECUTABLE} -j
  INSTALL_COMMAND ${MAKE_EXECUTABLE} -j install
  TEST_COMMAND ""
  CONFIGURE_HANDLED_BY_BUILD ON
  INACTIVITY_TIMEOUT 15
  DEPENDS "expat;ffi;ssl;zlib"
  )

endif()
