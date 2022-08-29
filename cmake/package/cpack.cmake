set(CPACK_GENERATOR "TZST")
set(CPACK_SOURCE_GENERATOR "TZST")
set(CPACK_PACKAGE_CONTACT "Michael Hirsch")
set(CPACK_PACKAGE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/package)

# not .gitignore as its regex syntax is more advanced than CMake
set(CPACK_SOURCE_IGNORE_FILES .git/ .github/ .vscode/ .mypy_cache/ _CPack_Packages/
${CMAKE_BINARY_DIR}/ ${PROJECT_BINARY_DIR}/
archive/ build*/
)

include(CPack)