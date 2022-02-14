set(_names
iniparser
glow hwm14 msis2
hwloc mpich openmpi
lapack mumps scalapack
nc4fortran h5fortran
ffilesystem
)

file(READ ${CMAKE_CURRENT_LIST_DIR}/libraries.json _libj)

foreach(n ${_names})
  foreach(t url git tag zip sha256)
    string(JSON m ERROR_VARIABLE e GET ${_libj} ${n} ${t})
    if(m)
      set(${n}_${t} ${m})
    endif()
  endforeach()
endforeach()

# --- Mumps
string(JSON MUMPS_UPSTREAM_VERSION GET ${_libj} mumps upstream_version)

# --- Zlib
if(zlib_legacy)
  string(JSON zlib_url GET ${_libj} zlib1 url)
  string(JSON zlib_sha256 GET ${_libj} zlib1 sha256)
else()
  string(JSON zlib_url GET ${_libj} zlib2 url)
  string(JSON zlib_sha256 GET ${_libj} zlib2 sha256)
endif()

# --- HDF5
string(JSON hdf5_url GET ${_libj} hdf5 ${HDF5_VERSION} url)
string(JSON hdf5_sha256 GET ${_libj} hdf5 ${HDF5_VERSION} sha256)

# --- download reference data JSON file (for previously generated data)
cmake_path(APPEND arc_json_file ${CMAKE_CURRENT_BINARY_DIR} ref_data.json)
if(NOT EXISTS ${arc_json_file})
  string(JSON url GET ${_libj} ref_data url)
  file(DOWNLOAD ${url} ${arc_json_file} INACTIVITY_TIMEOUT 15)
endif()
