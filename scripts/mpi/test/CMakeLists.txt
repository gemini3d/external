cmake_minimum_required(VERSION 3.19)

project(MPItest LANGUAGES Fortran)

enable_testing()

include(CheckSourceCompiles)

if(NOT DEFINED MPI_ROOT AND DEFINED ENV{MPI_ROOT})
  set(MPI_ROOT $ENV{MPI_ROOT})
endif()
if(NOT MPI_ROOT)
  message(STATUS "MPI_ROOT not set, using default MPI search paths")
endif()

find_package(MPI COMPONENTS Fortran REQUIRED)


find_file(mpi_f08_mod NAMES mpi_f08.mod
REQUIRED
NO_DEFAULT_PATH
HINTS ${MPI_Fortran_INCLUDE_DIRS}
)

message(STATUS "MPI-3 test:
MPI libs: ${MPI_Fortran_LIBRARIES}
MPI include: ${MPI_Fortran_INCLUDE_DIRS}
MPI_f08 module: ${mpi_f08_mod}"
)

check_source_compiles(Fortran
[=[
program test
use mpi_f08, only : mpi_comm_rank, mpi_real, mpi_comm_world, mpi_init, mpi_finalize
implicit none
call mpi_init
call mpi_finalize
end program
]=]
MPI_Fortran_HAVE_F08_MODULE
)

if(NOT MPI_Fortran_HAVE_F08_MODULE)
  message(FATAL_ERROR "Fortran MPI ${MPI_Fortran_VERSION} doesn't have MPI-3")
endif()

add_executable(mpi3 mpi3.f90)
target_link_libraries(mpi3 PRIVATE MPI::MPI_Fortran)

add_test(NAME MPI-3-Fortran
COMMAND ${MPIEXEC_EXECUTABLE}  ${MPIEXEC_NUMPROC_FLAG} ${MPIEXEC_MAX_NUMPROCS} $<TARGET_FILE:mpi3>
)
