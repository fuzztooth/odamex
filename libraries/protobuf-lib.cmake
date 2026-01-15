### Protocol Buffers ###

if(BUILD_CLIENT OR BUILD_SERVER)
  # For Android cross-compilation, use the host protoc we built separately
  if(ANDROID)
    message(STATUS "************ ANDROID DETECTED - Setting up host protoc ************")
    set(_HOST_PROTOC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/protobuf-host/bin/protoc${CMAKE_EXECUTABLE_SUFFIX}")
    set(_FALLBACK_PROTOC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../android/app/src/main/cpp/protoc/protoc${CMAKE_EXECUTABLE_SUFFIX}")
    message(STATUS "Looking for protoc at: ${_HOST_PROTOC_PATH}")
    message(STATUS "Looking for protoc at: ${_FALLBACK_PROTOC_PATH}")
    if(EXISTS "${_HOST_PROTOC_PATH}")
      set(_PROTOC_PATH "${_HOST_PROTOC_PATH}")
    elseif(EXISTS "${_FALLBACK_PROTOC_PATH}")
      set(_PROTOC_PATH "${_FALLBACK_PROTOC_PATH}")
    endif()
    if(DEFINED _PROTOC_PATH)
      set(protobuf_PROTOC_EXECUTABLE "${_PROTOC_PATH}" CACHE FILEPATH "Host protoc compiler" FORCE)
      set(protobuf_PROTOC_EXE "${_PROTOC_PATH}" CACHE FILEPATH "Host protoc compiler" FORCE)
      message(STATUS "********** Using host protoc: ${_PROTOC_PATH} **********")
    else()
      message(FATAL_ERROR "Host protoc not found. Checked: ${_HOST_PROTOC_PATH}, ${_FALLBACK_PROTOC_PATH}. Run build-protoc.sh first.")
    endif()
  endif()

  set(_PROTOBUF_BUILDGEN_PARAMS
    "-Dprotobuf_BUILD_SHARED_LIBS=OFF"
    "-Dprotobuf_BUILD_TESTS=OFF"
    "-Dprotobuf_MSVC_STATIC_RUNTIME=OFF")

  if(MSVC)
    # https://developercommunity.visualstudio.com/t/Visual-Studio-1740-no-longer-compiles-/10193665
    set(protobuf_CXXFLAGS "/D_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS")
  endif()

  lib_buildgen(
    LIBRARY protobuf
    SRCDIR "${CMAKE_CURRENT_SOURCE_DIR}/protobuf/cmake"
    PARAMS ${_PROTOBUF_BUILDGEN_PARAMS}
    CXXFLAGS ${protobuf_CXXFLAGS})
  lib_build(LIBRARY protobuf)
endif()
