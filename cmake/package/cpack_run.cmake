set(CMAKE_EXECUTE_PROCESS_COMMAND_ECHO STDOUT)

find_file(cfg
NAMES ${cfg_name}
HINTS ${bindir}
NO_DEFAULT_PATH
)
if(NOT cfg)
  message(FATAL_ERROR "${name}: did not find ${cfg_name} in ${bindir}")
endif()

execute_process(
COMMAND ${CMAKE_CPACK_COMMAND}
-G TBZ2
--config ${cfg}
-B ${bindir}
RESULT_VARIABLE ret
ERROR_VARIABLE err
)
# "-B ${bindir}" in case the sub-project has an arbitrary CPACK_PACKAGE_DIRECTORY specified in itself

# -DCPACK_PACKAGE_INSTALL_DIRECTORY="" didn't help for HDF5 with arbitrary source-package-only subdir HDF_Group/HDF5/${HDF5_VERSION}
if(cfg_name STREQUAL "hdf5")
  if(CMAKE_VERSION VERSION_LESS 3.19)
    message(FATAL_ERROR "CMake >= 3.19 required for full packaging")
  endif()

  file(READ ${CMAKE_CURRENT_LIST_DIR}/../libraries.json meta)
  string(JSON HDF5_VERSION GET ${meta} "hdf5" "version")

  find_path(hdf5_cmakelists
  NAMES CMakeLists.txt
  PATHS ${bindir}/HDF_Group/HDF5/${HDF5_VERSION}
  NO_DEFAULT_PATH
  )

  if(hdf5_cmakelists)
    set(CPACK_PRE_BUILD_SCRIPTS ${CMAKE_CURRENT_LIST_DIR}/cpack_hdf5.cmake)
  endif()
endif()

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "${name}: failed to package using ${cfg}: ${ret}:
  ${err}")
endif()

if(cfg MATCHES "CPackSourceConfig.cmake$")
  set(archive ${bindir}/${name}.tar.bz2)
else()
  set(archive ${bindir}/${name}-${sys_name}.tar.bz2)
endif()

if(NOT EXISTS ${archive})
  message(FATAL_ERROR "${name}: package archive not found: ${archive}")
endif()
file(COPY ${archive} DESTINATION ${pkgdir}/)
