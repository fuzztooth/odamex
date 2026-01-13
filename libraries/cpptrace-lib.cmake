### cpptrace ###

if(BUILD_CLIENT OR BUILD_SERVER)
  if(USE_INTERNAL_CPPTRACE)
    # Android: disable zstd support (we don't have it)
    if(ANDROID OR USE_INTERNAL_ZSTD)
      set(CPPTRACE_USE_EXTERNAL_ZSTD OFF)
    else()
      set(CPPTRACE_USE_EXTERNAL_ZSTD ON)
    endif()
    
    # For Android, set up zstd paths for cpptrace's internal build
    set(CPPTRACE_EXTRA_PARAMS "")
    if(ANDROID)
      list(APPEND CPPTRACE_EXTRA_PARAMS 
        "-Dzstd_DIR=${CMAKE_CURRENT_BINARY_DIR}/local/lib/cmake/zstd"
        "-Dzstd_INCLUDE_DIR=${CMAKE_CURRENT_BINARY_DIR}/local/include"
        "-Dzstd_LIBRARY=${CMAKE_CURRENT_BINARY_DIR}/local/lib/libzstdd.a"
        "-DLIBDWARF_USE_ZLIB=OFF"
        "-DLIBDWARF_USE_ZSTD=OFF")
    endif()
    
    lib_buildgen(
      LIBRARY cpptrace
      PARAMS "-DCMAKE_DEBUG_POSTFIX=d"
             "-DCPPTRACE_USE_EXTERNAL_LIBDWARF=${USE_EXTERNAL_LIBDWARF}"
             "-DCPPTRACE_USE_EXTERNAL_ZSTD=${CPPTRACE_USE_EXTERNAL_ZSTD}"
             ${CPPTRACE_EXTRA_PARAMS})
    lib_build(LIBRARY cpptrace)
    
    # For Android: Instead of using find_package, manually import cpptrace
    # This avoids the zstd dependency issue since we built it internally
    if(ANDROID)
      # Import zstd first - set up CMAKE_PREFIX_PATH so libdwarf can find it
      set(CMAKE_PREFIX_PATH "${CMAKE_CURRENT_BINARY_DIR}/local" ${CMAKE_PREFIX_PATH})
      
      find_package(zstd REQUIRED CONFIG 
        PATHS "${CMAKE_CURRENT_BINARY_DIR}/local/lib/cmake/zstd" 
        NO_DEFAULT_PATH)
      
      # Don't use find_package for libdwarf - just link the library directly
      # to avoid the zstd dependency issue in libdwarfConfig.cmake
      
      # Manually create the cpptrace::cpptrace target
      add_library(cpptrace::cpptrace STATIC IMPORTED GLOBAL)
      set_target_properties(cpptrace::cpptrace PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/local/lib/libcpptraced.a"
        INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_BINARY_DIR}/local/include"
        INTERFACE_LINK_LIBRARIES "zstd::libzstd_static;${CMAKE_CURRENT_BINARY_DIR}/local/lib/libdwarfd.a"
      )
    else()
      find_package(cpptrace)
      if(TARGET cpptrace::cpptrace)
        set_target_properties(cpptrace::cpptrace PROPERTIES IMPORTED_GLOBAL True)
      endif()
    endif()
  endif()
endif()

if(USE_INTERNAL_ZLIB)
  # Set vars so the finder can find them.
  set(ZLIB_INCLUDE_DIR
  "${CMAKE_CURRENT_BINARY_DIR}/local/include" CACHE PATH "" FORCE)
  if(WIN32)
    set(ZLIB_LIBRARY
      "${CMAKE_CURRENT_BINARY_DIR}/local/lib/${libprefix}zlibstatic${libsuffix}"  CACHE PATH "" FORCE)
  else()
    set(ZLIB_LIBRARY
      "${CMAKE_CURRENT_BINARY_DIR}/local/lib/${libprefix}z${libsuffix}" CACHE PATH "" FORCE)
  endif()
endif()

