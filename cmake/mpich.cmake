string(JSON mpi_url GET ${json_meta} mpich url)
string(JSON mpi_sha256 GET ${json_meta} mpich sha256)

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
URL ${mpi_url}
URL_HASH SHA256=${mpi_sha256}
CONFIGURE_COMMAND <SOURCE_DIR>/configure ${mpi_flags} ${mpi_ldflags}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j ${Ncpu}
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j ${Ncpu} install
TEST_COMMAND ""
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD ON
DEPENDS hwloc
)
