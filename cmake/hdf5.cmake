include_guard()

set(hdf5_cmake_args
-DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=ON
-DZLIB_USE_EXTERNAL:BOOL=OFF
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
# https://github.com/HDFGroup/hdf5/issues/818  for broken ph5diff in HDF5_BUILD_TOOLS
if(MPI_ROOT)
  list(APPEND hdf5_cmake_args -DMPI_ROOT:PATH=${MPI_ROOT})
endif()

extproj(hdf5 git "${hdf5_cmake_args}" "zlib")
