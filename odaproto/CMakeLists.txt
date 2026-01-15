include(OdamexTargetSettings)

# For Android cross-compilation, use host protoc
if(ANDROID)
  set(_HOST_PROTOC_PATH "${CMAKE_SOURCE_DIR}/libraries/protobuf-host/bin/protoc${CMAKE_EXECUTABLE_SUFFIX}")
  set(_FALLBACK_PROTOC_PATH "${CMAKE_SOURCE_DIR}/android/app/src/main/cpp/protoc/protoc${CMAKE_EXECUTABLE_SUFFIX}")
  if(EXISTS "${_HOST_PROTOC_PATH}")
    set(protobuf_PROTOC_EXE "${_HOST_PROTOC_PATH}" CACHE FILEPATH "Host protoc for cross-compilation" FORCE)
    message(STATUS "odaproto: Using host protoc at ${_HOST_PROTOC_PATH}")
  elseif(EXISTS "${_FALLBACK_PROTOC_PATH}")
    set(protobuf_PROTOC_EXE "${_FALLBACK_PROTOC_PATH}" CACHE FILEPATH "Host protoc for cross-compilation" FORCE)
    message(STATUS "odaproto: Using host protoc at ${_FALLBACK_PROTOC_PATH}")
  else()
    message(FATAL_ERROR "Host protoc not found. Checked: ${_HOST_PROTOC_PATH}, ${_FALLBACK_PROTOC_PATH}. Run build-protoc.sh first.")
  endif()
endif()

find_package(protobuf
  PATHS
    "${CMAKE_CURRENT_BINARY_DIR}/../libraries/protobuf-build/cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/../libraries/protobuf-build/lib/cmake/protobuf"
    "${CMAKE_CURRENT_BINARY_DIR}/../libraries/protobuf-build/lib64/cmake/protobuf"
  NO_DEFAULT_PATH)

set(ODAPROTO_PROTOS common.proto server.proto)

protobuf_generate(OUT_VAR ODAPROTO_SOURCES PROTOS ${ODAPROTO_PROTOS})

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
