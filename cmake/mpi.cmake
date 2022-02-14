if(NOT (openmpi OR mpich))
  set(openmpi true)
endif()

if(NOT MAKE_EXECUTABLE)
  message(FATAL_ERROR "MPI build requires GNU Make.")
endif()


if(openmpi)

set(openmpi_flags
--prefix=${CMAKE_INSTALL_PREFIX}
--with-hwloc-libdir=${CMAKE_INSTALL_PREFIX}/lib
)
if(BUILD_SHARED_LIBS)
  list(APPEND openmpi_flags --enable-shared --disable-static)
else()
  list(APPEND openmpi_flags --disable-shared --enable-static)
endif()
# --disable-shared avoids:
# lib_gcc/lib/libz.a(deflate_medium.c.o): relocation R_X86_64_32S against internal symbol `zng_length_code' can not be used when making a shared objec
# https://github.com/zlib-ng/zlib-ng/wiki/Common-build-problems#relocation-error-in-compress2

ExternalProject_Add(OPENMPI
URL ${openmpi_url}
URL_HASH SHA256=${openmpi_sha256}
CONFIGURE_COMMAND ${PROJECT_BINARY_DIR}/OPENMPI-prefix/src/OPENMPI/configure ${openmpi_flags}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j install
TEST_COMMAND ""
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD ON
DEPENDS HWLOC
)

elseif(mpich)

set(mpich_flags --prefix=${CMAKE_INSTALL_PREFIX} --with-device=ch3)

if(CMAKE_Fortran_COMPILER_ID STREQUAL GNU)
  if(CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 10)
    list(APPEND mpich_flags FFLAGS=-fallow-argument-mismatch)
  endif()
endif()

ExternalProject_Add(MPICH
URL ${mpich_url}
URL_HASH SHA256=${mpich_sha256}
CONFIGURE_COMMAND ${PROJECT_BINARY_DIR}/MPICH-prefix/src/MPICH/configure ${mpich_flags}
BUILD_COMMAND ${MAKE_EXECUTABLE} -j
INSTALL_COMMAND ${MAKE_EXECUTABLE} -j install
TEST_COMMAND ""
INACTIVITY_TIMEOUT 15
CONFIGURE_HANDLED_BY_BUILD ON
DEPENDS HWLOC
)

endif()
