if(CRAY)
  add_custom_target(lapack)
  return()
endif()

if(find OR DEFINED ENV{MKLROOT})
  find_package(LAPACK)
endif()
if(LAPACK_FOUND)
  add_custom_target(lapack)
  return()
  # dummy target to avoid error if user `cmake --build --target lapack`
endif()

set(lapack_args
-Dlocal:PATH=${local}
-DBUILD_SINGLE:BOOL=false
-DBUILD_DOUBLE:BOOL=true
-DBUILD_COMPLEX:BOOL=false
-DBUILD_COMPLEX16:BOOL=false
-DTEST_FORTRAN_COMPILER:BOOL=false
)
# don't run their Fortran tests as they error build on test_zminMax.err
extproj(lapack ${lapack_method} "${lapack_args}" "")
