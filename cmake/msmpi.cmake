# MSMPI library comes from MSYS2
# This script would install mpiexec that doesn't come from MSYS2.
# However, this script doesn't work because msmpisetup.exe needs UAC
# and execute_process() can't handle the UAC popup.

if(NOT json_meta)
  file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json json_meta)
endif()

string(JSON mpi_url GET ${json_meta} msmpi url)

set(mpi_archive ${CMAKE_CURRENT_BINARY_DIR}/msmpisetup.exe)

if(NOT EXISTS ${mpi_archive})
file(DOWNLOAD ${mpi_url} ${mpi_archive} INACTIVITY_TIMEOUT 60 STATUS ret)
list(GET ret 0 stat)
if(NOT stat EQUAL 0)
  list(GET ret 1 err)
  message(FATAL_ERROR "MS-MPI download failed: ${err}")
endif()
endif()

execute_process(COMMAND ${mpi_archive} -unattend
RESULT_VARIABLE ret
)

message(STATUS "Failed to install MS-MPI: ${ret}")
