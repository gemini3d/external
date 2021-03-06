# --- HDF5

set(hdf5_cmake_args
-DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON
-DZLIB_USE_EXTERNAL:BOOL=OFF
-DCMAKE_MODULE_PATH:PATH=${CMAKE_MODULE_PATH}
-DHDF5_GENERATE_HEADERS:BOOL=false
-DHDF5_DISABLE_COMPILER_WARNINGS:BOOL=true
-DBUILD_STATIC_LIBS:BOOL=$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>
-DHDF5_BUILD_FORTRAN:BOOL=true
-DHDF5_BUILD_CPP_LIB:BOOL=false
-DHDF5_BUILD_EXAMPLES:BOOL=false
-DUSE_LIBAEC:bool=true
-DHDF5_BUILD_TOOLS:BOOL=$<NOT:$<BOOL:${hdf5_parallel}>>
-DHDF5_ENABLE_PARALLEL:BOOL=$<BOOL:${hdf5_parallel}>
)
if(hdf5_parallel)
  list(APPEND hdf5_cmake_args -DMPI_ROOT:PATH=${CMAKE_INSTALL_PREFIX})
endif()

set(hdf5_deps zlib)
if(build_mpi AND hdf5_parallel)
  list(APPEND hdf5_deps mpi)
endif()

extproj(hdf5 git "${hdf5_cmake_args}" "${hdf5_deps}")
