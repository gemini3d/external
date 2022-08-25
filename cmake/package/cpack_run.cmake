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
-B ${proj_bindir}/package
TIMEOUT 30
RESULT_VARIABLE ret
ERROR_VARIABLE err
)

if(NOT ret EQUAL 0)
  message(FATAL_ERROR "${name}: failed to package ${err}")
endif()
