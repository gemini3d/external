string(JSON python_url GET ${json_meta} python url)
string(JSON python_sha256 GET ${json_meta} python sha256)

if(WIN32)
  # https://pythondev.readthedocs.io/windows.html

  message(FATAL_ERROR "On Windows, Python is available from Microsoft Store.")
  # requires Visual Studio, which doesn't work with other external libraries

  # ExternalProject_Add(python
  # URL ${python_url}
  # URL_HASH SHA256=${python_sha256}
  # CONFIGURE_COMMAND ""
  # BUILD_COMMAND <SOURCE_DIR>/PCBuild/build.bat -p x64
  # INSTALL_COMMAND ""
  # TEST_COMMAND ""
  # CONFIGURE_HANDLED_BY_BUILD ON
  # INACTIVITY_TIMEOUT 15
  # )

else()
  # Linux prereqs: https://devguide.python.org/setup/#linux

  set(python_args)

  if(NOT MAKE_EXECUTABLE)
    message(FATAL_ERROR "Python requires GNU Make.")
  endif()

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

endif()
