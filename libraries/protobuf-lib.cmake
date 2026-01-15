### Protocol Buffers ###

if(BUILD_CLIENT OR BUILD_SERVER)
  # For Android cross-compilation, use the host protoc we built separately
  if(ANDROID)
    # Detect host platform for correct executable extension
    if(CMAKE_HOST_WIN32)
      set(_PROTOC_EXE_EXT ".exe")
    else()
      set(_PROTOC_EXE_EXT "")
    endif()
    
    set(_HOST_PROTOC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/protobuf-host/bin/protoc${_PROTOC_EXE_EXT}")
    set(_FALLBACK_PROTOC_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../android/app/src/main/cpp/protoc/protoc${_PROTOC_EXE_EXT}")
    
    if(EXISTS "${_HOST_PROTOC_PATH}")
      set(protobuf_PROTOC_EXECUTABLE "${_HOST_PROTOC_PATH}" CACHE FILEPATH "Host protoc compiler" FORCE)
      message(STATUS "Using host protoc: ${_HOST_PROTOC_PATH}")
    elseif(EXISTS "${_FALLBACK_PROTOC_PATH}")
      set(protobuf_PROTOC_EXECUTABLE "${_FALLBACK_PROTOC_PATH}" CACHE FILEPATH "Host protoc compiler" FORCE)
      message(STATUS "Using host protoc: ${_FALLBACK_PROTOC_PATH}")
    else()
      message(FATAL_ERROR "Host protoc not found at ${_HOST_PROTOC_PATH} or ${_FALLBACK_PROTOC_PATH}. Run build-sdl2.sh first.")
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
