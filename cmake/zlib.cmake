include_guard()

set(zlib_cmake_args
-DZLIB_COMPAT:BOOL=on
-DZLIB_ENABLE_TESTS:BOOL=off
-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=on
)
# CMAKE_POSITION_INDEPENDENT_CODE=on is needed for Zlib even when using static libs.

extproj(zlib git "${zlib_cmake_args}" "")