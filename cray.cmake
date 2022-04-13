# loads modules on Cray system
# canNOT use from Project CMakeLists.txt
# it's OK to run again if you're not sure if it was already run.

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

env_module(load cray-hdf5
OUTPUT_VARIABLE out
RESULT_VARIABLE ret
)
if(ret)
  message(STATUS "load cray-hdf5 error ${ret}: ${out}")
endif()


env_module(load cray-mpich
OUTPUT_VARIABLE out
RESULT_VARIABLE ret
)
if(ret)
  message(STATUS "load cray-mpich error ${ret}: ${out}")
endif()
