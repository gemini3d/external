include(ExternalProject)

# PREPEND so that user arguments can override these defaults
set(python_cmake_args
-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
-DCMAKE_PREFIX_PATH:PATH=${CMAKE_INSTALL_PREFIX}
-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}
-DCMAKE_BUILD_TYPE=Release
)


string(JSON python_url GET ${json_meta} python git)
string(JSON python_tag GET ${json_meta} python tag)

ExternalProject_Add(python
GIT_REPOSITORY ${python_url}
GIT_TAG ${python_tag}
GIT_SHALLOW true
CMAKE_ARGS ${python_cmake_args}
CMAKE_GENERATOR ${EXTPROJ_GEN}
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD true
TEST_COMMAND ""
INSTALL_COMMAND ""
)
