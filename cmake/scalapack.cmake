if(find OR CRAY OR DEFINED ENV{MKLROOT})
  find_package(SCALAPACK)
endif()
if(SCALAPACK_FOUND)
  add_custom_target(scalapack)
  return()
endif()

set(scalapack_args
-DBUILD_SINGLE:BOOL=false
-DBUILD_DOUBLE:BOOL=true
-DBUILD_COMPLEX:BOOL=false
-DBUILD_COMPLEX16:BOOL=false
)

set(scalapack_deps)
if(NOT LAPACK_FOUND)
  set(scalapack_deps lapack)
endif()

if(local)
  list(APPEND scalapack_args -Dlocal:PATH=${local})
endif()

extproj(scalapack ${scalapack_method} "${scalapack_args}" "${scalapack_deps}")
