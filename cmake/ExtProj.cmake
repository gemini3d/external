include(ExternalProject)

function(extproj name url hash url_type cmake_args depends)

list(APPEND cmake_args
--install-prefix=${CMAKE_INSTALL_PREFIX}
-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
-DCMAKE_BUILD_TYPE=Release
-DBUILD_TESTING:BOOL=false
-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
-DCMAKE_Fortran_COMPILER=${CMAKE_Fortran_COMPILER}
)

if(url_type STREQUAL git)
  ExternalProject_Add(${name}
  GIT_REPOSITORY ${url}
  GIT_TAG ${hash}
  CMAKE_ARGS ${cmake_args}
  CMAKE_GENERATOR ${EXTPROJ_GEN}
  INACTIVITY_TIMEOUT 15
  CONFIGURE_HANDLED_BY_BUILD true
  TEST_COMMAND ""
  DEPENDS ${depends}
  )
elseif(url_type STREQUAL archive)
  ExternalProject_Add(${name}
  URL ${url}
  URL_HASH SHA256=${hash}
  CMAKE_ARGS ${cmake_args}
  CMAKE_GENERATOR ${EXTPROJ_GEN}
  INACTIVITY_TIMEOUT 15
  CONFIGURE_HANDLED_BY_BUILD true
  TEST_COMMAND ""
  DEPENDS ${depends}
  )
else()
  message(FATAL_ERROR "unsure how to use resource of type ${url_type")
endif()

endfunction(extproj)
