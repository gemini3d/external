if(find)
  find_package(MUMPS COMPONENTS ${arith})
endif()
if(MUMPS_FOUND)
  add_custom_target(mumps)
  return()
endif()

set(mumps_cmake_args
-Dscotch:BOOL=${scotch}
-Dopenmp:BOOL=false
-Dparallel:BOOL=true
-Darith=${arith}
)
if(build_mpi)
  list(APPEND mumps_cmake_args -DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX})
endif()

if(MSVC AND BUILD_SHARED_LIBS)
  # long-standing bug in MUMPS that can't handle shared libraries with MSVC (Windows Intel oneAPI)
  list(APPEND mumps_cmake_args -DBUILD_SHARED_LIBS:BOOL=false)
endif()

if(NOT SCALAPACK_FOUND)
  set(mumps_deps scalapack)
endif()

if(NOT LAPACK_FOUND)
  list(APPEND mumps_deps lapack)
endif()

extproj(mumps git "${mumps_cmake_args}" "${mumps_deps}")
