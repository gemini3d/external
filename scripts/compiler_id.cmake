cmake_minimum_required(VERSION 3.13)

function(compiler_id outvar)

set(wd ${CMAKE_CURRENT_LIST_DIR}/../build)

set(${outvar} generic PARENT_SCOPE)

if(DEFINED ENV{CC})
  set(cc_name $ENV{CC})
elseif(DEFINED ENV{MKLROOT})
  set(cc_name icx icc icl cc)
else()
  set(cc_name cc)
endif()

find_program(CC
NAMES ${cc_name}
)

message(DEBUG "Identify C compiler ${CC} from names ${cc_name}")

if(NOT CC)
  return()
endif()

execute_process(
COMMAND ${CC} ${CMAKE_CURRENT_LIST_DIR}/compiler_id.c -o ${wd}/compiler_id
RESULT_VARIABLE ret
ERROR_VARIABLE err
TIMEOUT 20
)
message(DEBUG "Build compiler_id: ${ret}  ${err}")
if(NOT ret EQUAL 0)
  return()
endif()

execute_process(
COMMAND ${wd}/compiler_id
OUTPUT_VARIABLE out
OUTPUT_STRIP_TRAILING_WHITESPACE
RESULT_VARIABLE ret
TIMEOUT 5
)

message(DEBUG "Identify C compiler ${CC} with id ${out}:  ${ret}")

if(ret EQUAL 0)
  set(${outvar} ${out} PARENT_SCOPE)
endif()

endfunction(compiler_id)