if(find OR CRAY OR DEFINED ENV{MKLROOT})
  find_package(SCALAPACK)
endif()
if(SCALAPACK_FOUND)
  add_custom_target(scalapack)
  return()
endif()

set(scalapack_args
-Darith=${arith}
)

if(NOT LAPACK_FOUND)
  set(scalapack_deps lapack)
endif()
if(build_mpi)
  list(APPEND scalapack_deps mpi)
  list(APPEND scalapack_args -DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX})
endif()

extproj(scalapack git "${scalapack_args}" "${scalapack_deps}")
