file(READ ${CMAKE_CURRENT_LIST_DIR}/../libraries.json meta)
string(JSON HDF5_VERSION GET ${meta} "hdf5" "version")

find_path(hdf5_top
NAMES CMakeLists.txt
PATHS ${bindir}/HDF_Group/HDF5/${HDF5_VERSION}
NO_DEFAULT_PATH
)

if(NOT hdf5_top)
  message(WARNING "cpack_hdf5: HDF5 CPack source layout not as expected, skipping patch.")
  return()
endif()

file(RENAME ${hdf5_top} ${bindir})
