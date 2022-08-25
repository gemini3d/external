find_file(cfg
NAMES CPackSourceConfig.cmake
HINTS ${bindir}
NO_DEFAULT_PATH
)
if(NOT cfg)
  message(FATAL_ERROR "${name}: did not find CPackSourceConfig.cmake in ${bindir}")
endif()

execute_process(
COMMAND ${CMAKE_CPACK_COMMAND}
-G TZST
--config ${cfg}
-B ${proj_bindir}/package
TIMEOUT 30
RESULT_VARIABLE ret
ERROR_VARIABLE err
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "${name}: failed to package source ${err}")
endif()