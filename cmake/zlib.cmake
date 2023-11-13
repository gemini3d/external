include_guard()

set(zlib_cmake_args
-DZLIB_COMPAT:BOOL=on
-DZLIB_ENABLE_TESTS:BOOL=off
-DZLIBNG_ENABLE_TESTS:BOOL=off
-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=on
)
# CMAKE_POSITION_INDEPENDENT_CODE=on is needed for Zlib even when using static libs.

git_submodule(${PROJECT_SOURCE_DIR}/zlib)
extproj(${PROJECT_SOURCE_DIR}/zlib "${zlib_cmake_args}" "")
