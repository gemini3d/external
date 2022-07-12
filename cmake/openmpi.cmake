string(JSON mpi_url GET ${json_meta} openmpi url)
string(JSON mpi_tag GET ${json_meta} openmpi tag)

list(APPEND mpi_flags
--with-hwloc=internal
)
# internal HWLOC avoids error in MPI:
# ibopen-pal.a(topology-linux.o): multiple definition of `hwloc_linux_component'
#--with-hwloc-libdir=${CMAKE_INSTALL_PREFIX}/lib


find_package(ZLIB)
if(ZLIB_FOUND)
  cmake_path(GET ZLIB_LIBRARIES PARENT_PATH ZLIB_LIBDIR)
  string(APPEND mpi_ldflags " ${CMAKE_LIBRARY_PATH_FLAG}${ZLIB_LIBDIR}")
endif()

if(BUILD_SHARED_LIBS)
  list(APPEND mpi_flags --enable-shared --disable-static)
else()
  list(APPEND mpi_flags --disable-shared --enable-static)
endif()
# --disable-shared avoids:
# lib_gcc/lib/libz.a(deflate_medium.c.o): relocation R_X86_64_32S against internal symbol `zng_length_code' can not be used when making a shared objec
# https://github.com/zlib-ng/zlib-ng/wiki/Common-build-problems#relocation-error-in-compress2

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
)
