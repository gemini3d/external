# installs Expat

string(JSON expat_url GET ${json_meta} expat git)
string(JSON expat_tag GET ${json_meta} expat tag)

set(expat_args
-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
-DCMAKE_BUILD_TYPE=Release
-DEXPAT_BUILD_DOCS:BOOL=false
-DEXPAT_BUILD_EXAMPLES:BOOL=false
-DEXPAT_BUILD_TESTS:BOOL=false
-DEXPAT_BUILD_TOOLS:BOOL=false
-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
)

ExternalProject_Add(expat
GIT_REPOSITORY ${expat_url}
GIT_TAG ${expat_tag}
GIT_SHALLOW true
TEST_COMMAND ""
CMAKE_ARGS ${expat_args}
SOURCE_SUBDIR expat
CONFIGURE_HANDLED_BY_BUILD ON
INACTIVITY_TIMEOUT 15
)
