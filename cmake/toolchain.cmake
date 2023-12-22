if(NOT DEFINED CMAKE_TOOLCHAIN_FILE AND DEFINED ENV{CMAKE_TOOLCHAIN_FILE})
  set(CMAKE_TOOLCHAIN_FILE $ENV{CMAKE_TOOLCHAIN_FILE})
endif()
if(CMAKE_TOOLCHAIN_FILE)
  get_filename_component(CMAKE_TOOLCHAIN_FILE ${CMAKE_TOOLCHAIN_FILE} ABSOLUTE)
endif()

if(NOT DEFINED CRAY AND DEFINED ENV{PE_ENV})
  set(CRAY true)
endif()

if(CRAY AND NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  set(CMAKE_TOOLCHAIN_FILE ${CMAKE_CURRENT_LIST_DIR}/cray.cmake)
endif()
