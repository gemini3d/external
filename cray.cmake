# loads modules on Cray system
# canNOT use from Project CMakeLists.txt
# it's OK to run again if you're not sure if it was already run.

cmake_minimum_required(VERSION 3.20...3.23)

if(NOT CMAKE_INSTALL_PREFIX)
  message(FATAL_ERROR "Please specify libraries install directory:
  cmake -DCMAKE_INSTALL_PREFIX=<install_dir> -P ${CMAKE_CURRENT_LIST_FILE}")
endif()

# the module commands only affect the current process, not the parent shell
cmake_path(SET BINARY_DIR ${CMAKE_CURRENT_LIST_DIR}/build)

find_package(EnvModules REQUIRED)

env_module(load cpe/22.03
OUTPUT_VARIABLE out
RESULT_VARIABLE ret
)
if(ret)
  message(STATUS "load cpe/22.03 error ${ret}: ${out}")
endif()

env_module_swap(PrgEnv-cray PrgEnv-gnu
OUTPUT_VARIABLE out
RESULT_VARIABLE ret
)
if(ret)
  message(STATUS "swap PrgEnv-gnu error ${ret}: ${out}")
endif()

# too compiler specific
# env_module(load cray-hdf5
# OUTPUT_VARIABLE out
# RESULT_VARIABLE ret
# )
# if(ret)
#   message(STATUS "load cray-hdf5 error ${ret}: ${out}")
# endif()


env_module(load cray-mpich
OUTPUT_VARIABLE out
RESULT_VARIABLE ret
)
if(ret)
  message(STATUS "load cray-mpich error ${ret}: ${out}")
endif()


execute_process(
COMMAND ${CMAKE_COMMAND} -B${BINARY_DIR} -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
COMMAND_ERROR_IS_FATAL ANY
)

execute_process(
COMMAND ${CMAKE_COMMAND} --build ${BINARY_DIR}
COMMAND_ERROR_IS_FATAL ANY
)
