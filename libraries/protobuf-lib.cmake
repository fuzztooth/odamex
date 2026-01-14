### Protocol Buffers ###

if(BUILD_CLIENT OR BUILD_SERVER)
  # For Android cross-compilation, use the host protoc we built separately
  if(ANDROID)
    message(STATUS "************ ANDROID DETECTED - Setting up host protoc ************")
    set(_HOST_PROTOC_EXE "${CMAKE_CURRENT_SOURCE_DIR}/protobuf-host/bin/protoc.exe")
    set(_HOST_PROTOC "${CMAKE_CURRENT_SOURCE_DIR}/protobuf-host/bin/protoc")
    message(STATUS "Looking for protoc at: ${_HOST_PROTOC_EXE}")
    message(STATUS "Looking for protoc at: ${_HOST_PROTOC}")
    if(EXISTS "${_HOST_PROTOC_EXE}")
      set(_HOST_PROTOC_PATH "${_HOST_PROTOC_EXE}")
    elseif(EXISTS "${_HOST_PROTOC}")
      set(_HOST_PROTOC_PATH "${_HOST_PROTOC}")
    endif()
    if(DEFINED _HOST_PROTOC_PATH)
      set(protobuf_PROTOC_EXECUTABLE "${_HOST_PROTOC_PATH}" CACHE FILEPATH "Host protoc compiler" FORCE)
      set(protobuf_PROTOC_EXE "${_HOST_PROTOC_PATH}" CACHE FILEPATH "Host protoc compiler" FORCE)
      message(STATUS "********** Using host protoc: ${_HOST_PROTOC_PATH} **********")
    else()
      message(FATAL_ERROR "Host protoc not found at ${_HOST_PROTOC_EXE} or ${_HOST_PROTOC}. Run build-protoc.sh first.")
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
