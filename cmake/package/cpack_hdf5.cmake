set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

file(READ ${CMAKE_CURRENT_LIST_DIR}/../libraries.json meta)
string(JSON HDF5_VERSION GET ${meta} "hdf5" "version")

find_path(hdf5_top
NAMES CMakeLists.txt
PATHS ${CMAKE_INSTALL_PREFIX}/HDF_Group/HDF5/${HDF5_VERSION}
NO_DEFAULT_PATH
)

if(NOT hdf5_top)
  message(WARNING "cpack_hdf5: HDF5 CPack source layout not as expected, skipping patch.")
  return()
endif()

message(STATUS "cpack_hdf5: HDF5 CPack source layout found, moving ${hdf5_top} => ${CMAKE_INSTALL_PREFIX}")

# fails because "directory not empty"
#file(RENAME ${hdf5_top}/* ${CMAKE_INSTALL_PREFIX}/)
#execute_process(COMMAND ${CMAKE_COMMAND} -E rename ${hdf5_top} ${CMAKE_INSTALL_PREFIX})

if(UNIX)
  execute_process(COMMAND sh -c "mv ${hdf5_top}/* ${CMAKE_INSTALL_PREFIX}/"
  RESULT_VARIABLE ret
  )
elseif(WIN32)
  message(FATAL_ERROR "TODO: implement Windows version of cpack_hdf5")
endif()
if(NOT ret EQUAL "0")
  message(FATAL_ERROR "cpack_hdf5: failed to move HDF5 CPack source layout")
endif()
