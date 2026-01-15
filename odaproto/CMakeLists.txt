include(OdamexTargetSettings)

find_package(protobuf
  PATHS
    "${CMAKE_CURRENT_BINARY_DIR}/../libraries/protobuf-build/cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/../libraries/protobuf-build/lib/cmake/protobuf"
    "${CMAKE_CURRENT_BINARY_DIR}/../libraries/protobuf-build/lib64/cmake/protobuf"
  NO_DEFAULT_PATH)

# For Android cross-compilation, detect host protoc executable
if(ANDROID)
  # Detect host platform for correct executable extension
  if(CMAKE_HOST_WIN32)
    set(_PROTOC_EXE_EXT ".exe")
  else()
    set(_PROTOC_EXE_EXT "")
  endif()
  
  set(_HOST_PROTOC_PATH "${CMAKE_SOURCE_DIR}/libraries/protobuf-host/bin/protoc${_PROTOC_EXE_EXT}")
  set(_FALLBACK_PROTOC_PATH "${CMAKE_SOURCE_DIR}/android/app/src/main/cpp/protoc/protoc${_PROTOC_EXE_EXT}")
  
  if(EXISTS "${_HOST_PROTOC_PATH}")
    set(_ANDROID_PROTOC_EXE "${_HOST_PROTOC_PATH}")
  elseif(EXISTS "${_FALLBACK_PROTOC_PATH}")
    set(_ANDROID_PROTOC_EXE "${_FALLBACK_PROTOC_PATH}")
  else()
    message(FATAL_ERROR "Host protoc not found at ${_HOST_PROTOC_PATH} or ${_FALLBACK_PROTOC_PATH}. Run build-sdl2.sh first.")
  endif()
endif()

set(ODAPROTO_PROTOS common.proto server.proto)

if(ANDROID AND DEFINED _ANDROID_PROTOC_EXE)
  # For Android, use add_custom_command directly to bypass protobuf_generate issues
  set(ODAPROTO_SOURCES)
  foreach(_proto ${ODAPROTO_PROTOS})
    get_filename_component(_proto_name ${_proto} NAME_WE)
    set(_pb_cc "${CMAKE_CURRENT_BINARY_DIR}/${_proto_name}.pb.cc")
    set(_pb_h "${CMAKE_CURRENT_BINARY_DIR}/${_proto_name}.pb.h")
    add_custom_command(
      OUTPUT ${_pb_cc} ${_pb_h}
      COMMAND "${_ANDROID_PROTOC_EXE}"
      ARGS --cpp_out=${CMAKE_CURRENT_BINARY_DIR} -I${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${_proto}
      DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${_proto}
      COMMENT "Generating C++ protocol buffers for ${_proto}"
      VERBATIM
    )
    list(APPEND ODAPROTO_SOURCES ${_pb_cc} ${_pb_h})
  endforeach()
else()
  protobuf_generate(OUT_VAR ODAPROTO_SOURCES PROTOS ${ODAPROTO_PROTOS})
endif()

source_group("Definitions" FILES ${ODAPROTO_PROTOS})
source_group("Generated" FILES ${ODAPROTO_SOURCES})

add_library(odaproto STATIC ${ODAPROTO_SOURCES} ${ODAPROTO_PROTOS})
odamex_target_settings(odaproto)
target_include_directories(odaproto PUBLIC "${CMAKE_CURRENT_BINARY_DIR}")
target_link_libraries(odaproto protobuf::libprotobuf)

if(MSVC)
  # https://developercommunity.visualstudio.com/t/Visual-Studio-1740-no-longer-compiles-/10193665
  target_compile_definitions(odaproto PUBLIC "_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS")
endif()
