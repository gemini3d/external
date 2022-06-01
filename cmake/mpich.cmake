string(JSON mpi_url GET ${json_meta} mpich url)
string(JSON mpi_tag GET ${json_meta} mpich tag)

list(APPEND mpi_flags
--with-device=ch3
)

if(CMAKE_Fortran_COMPILER_ID STREQUAL GNU AND CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 10)
# need FCFLAGS and FFLAGS
  list(APPEND mpi_flags
  FCFLAGS=-fallow-argument-mismatch
  FFLAGS=-fallow-argument-mismatch
  )
endif()

ExternalProject_Add(mpi
GIT_REPOSITORY ${mpi_url}
GIT_TAG ${mpi_tag}
GIT_SHALLOW true
CONFIGURE_COMMAND <SOURCE_DIR>/configure ${mpi_flags} ${mpi_ldflags}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j${Ncpu}
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j${Ncpu} install
TEST_COMMAND ""
INACTIVITY_TIMEOUT 60
CONFIGURE_HANDLED_BY_BUILD ON
DEPENDS hwloc
)
