### libcurl ###

if(BUILD_CLIENT)
  if(USE_INTERNAL_CURL)
    # [AM] Don't put an early return in this block, otherwise you run the risk
    #      of changes in the build cache not percolating down to the library.

    message(STATUS "Compiling internal CURL...")

    # Android: Use lib_buildgen/lib_build like other libraries
    if(ANDROID)
      if(WIN32)
        set(_COMPILE_CURL_WINSSL ON)
      else()
        set(_COMPILE_CURL_WINSSL OFF)
      endif()

      lib_buildgen(
        LIBRARY curl
        PARAMS "-DBUILD_CURL_EXE=OFF"
               "-DBUILD_EXAMPLES=OFF"
               "-DBUILD_LIBCURL_DOCS=OFF"
               "-DBUILD_MISC_DOCS=OFF"
               "-DBUILD_SHARED_LIBS=OFF"
               "-DBUILD_TESTING=OFF"
               "-DCURL_USE_LIBSSH2=OFF"
               "-DCURL_USE_SCHANNEL=${_COMPILE_CURL_WINSSL}"
               "-DCURL_USE_LIBPSL=OFF"
               "-DCURL_ZLIB=OFF"
               "-DCURL_DISABLE_LDAP=ON"
               "-DCURL_DISABLE_LDAPS=ON"
               "-DCURL_USE_OPENSSL=OFF"
               "-DCURL_USE_MBEDTLS=OFF"
               "-DCURL_CA_PATH=none"
               "-DHTTP_ONLY=ON")
      lib_build(LIBRARY curl)
      unset(_COMPILE_CURL_WINSSL)

      # Manually create CURL::libcurl target for Android
      if(NOT TARGET CURL::libcurl)
        add_library(CURL::libcurl STATIC IMPORTED GLOBAL)
        # CURL uses CMAKE_DEBUG_POSTFIX, so the library is libcurl-d.a in Debug builds
        set_target_properties(CURL::libcurl PROPERTIES
          IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/local/lib/libcurl-d${libsuffix}"
          INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_BINARY_DIR}/local/include"
        )
      endif()
    else()
      # Non-Android: Use original execute_process approach
      # Set vars so the finder can find them.
      set(CURL_INCLUDE_DIR
        "${CMAKE_CURRENT_BINARY_DIR}/local/include")
      set(CURL_LIBRARY
        "${CMAKE_CURRENT_BINARY_DIR}/local/lib/libcurl${libsuffix}")

      if(WIN32)
        set(_COMPILE_CURL_WINSSL ON)
      else()
        set(_COMPILE_CURL_WINSSL OFF)
      endif()

      # Generate the build.
      execute_process(COMMAND "${CMAKE_COMMAND}"
        -S "${CMAKE_CURRENT_SOURCE_DIR}/curl"
        -B "${CMAKE_CURRENT_BINARY_DIR}/curl-build"
        -G "${CMAKE_GENERATOR}"
        -A "${CMAKE_GENERATOR_PLATFORM}"
        -T "${CMAKE_GENERATOR_TOOLSET}"
        "-DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}"
        "-DCMAKE_LINKER=${CMAKE_LINKER}"
        "-DCMAKE_RC_COMPILER=${CMAKE_RC_COMPILER}"
        "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
        "-DCMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/local"
        "-DBUILD_CURL_EXE=OFF"
        "-DBUILD_EXAMPLES=OFF"
        "-DBUILD_LIBCURL_DOCS=OFF"
        "-DBUILD_MISC_DOCS=OFF"
        "-DBUILD_SHARED_LIBS=OFF"
        "-DBUILD_TESTING=OFF"
        "-DCURL_USE_LIBSSH2=OFF"
        "-DCURL_USE_SCHANNEL=${_COMPILE_CURL_WINSSL}"
        "-DCURL_USE_LIBPSL=OFF"
        "-DCURL_ZLIB=OFF"
        "-DHTTP_ONLY=ON")
      unset(_COMPILE_CURL_WINSSL)

      # Compile the library.
      execute_process(COMMAND "${CMAKE_COMMAND}"
        --build "${CMAKE_CURRENT_BINARY_DIR}/curl-build"
        --config RelWithDebInfo --target install)

      find_package(CURL)
    endif()
  endif()

  # Create curl_interface for all platforms
  if(TARGET CURL::libcurl)
    add_library(curl_interface INTERFACE)
    target_link_libraries(curl_interface INTERFACE CURL::libcurl)
    set_target_properties(curl_interface PROPERTIES GLOBAL True)
    if(WIN32)
      target_link_libraries(curl_interface INTERFACE ws2_32 crypt32)
    endif()
  endif()
endif()
