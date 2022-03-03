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
  )

  if(NOT MAKE_EXECUTABLE)
    message(FATAL_ERROR "Python requires GNU Make.")
  endif()

  string(JSON ffi_url GET ${json_meta} ffi url)
  string(JSON ffi_sha256 GET ${json_meta} ffi sha256)

  set(ffi_args
  --prefix=${CMAKE_INSTALL_PREFIX}
  CC=${CMAKE_C_COMPILER}
  CXX=${CMAKE_CXX_COMPILER}
  )

  ExternalProject_Add(ffi
  URL ${ffi_url}
  URL_HASH SHA256=${ffi_sha256}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure ${ffi_args}
  BUILD_COMMAND ${MAKE_EXECUTABLE} -j
  INSTALL_COMMAND ${MAKE_EXECUTABLE} -j install
  TEST_COMMAND ""
  CONFIGURE_HANDLED_BY_BUILD ON
  INACTIVITY_TIMEOUT 15
  )

  ExternalProject_Add_Step(ffi
  autogen
  COMMAND <SOURCE_DIR>/autogen.sh
  DEPENDEES download
  DEPENDERS configure
  WORKING_DIRECTORY <SOURCE_DIR>
  )
  # autogen.sh needs to be executed in SOURCE_DIR, not in build directory


  ExternalProject_Add(python
  URL ${python_url}
  URL_HASH SHA256=${python_sha256}
  CONFIGURE_COMMAND <SOURCE_DIR>/configure ${python_args}
  BUILD_COMMAND ${MAKE_EXECUTABLE} -j
  INSTALL_COMMAND ${MAKE_EXECUTABLE} -j install
  TEST_COMMAND ""
  CONFIGURE_HANDLED_BY_BUILD ON
  INACTIVITY_TIMEOUT 15
  DEPENDS ffi
  )

endif()
