# SDL2 for Android - Using Prebuilt Libraries
#
# Prebuilt SDL2 .so files should be placed in:
#   android/app/src/main/jniLibs/arm64-v8a/
#   android/app/src/main/jniLibs/armeabi-v7a/
#
# These will be built by gradle task (buildSDL2)

if(ANDROID)
  message(STATUS "Configuring SDL2 for Android (prebuilt)")
  
  # Construct absolute path to jniLibs - CMAKE_SOURCE_DIR points to repo root
  set(JNI_LIBS_DIR "${CMAKE_SOURCE_DIR}/android/app/src/main/jniLibs")
  
  # Construct direct paths to SDL2 libraries (don't use find_library - it's unreliable in cross-compile context)
  set(SDL2_LIBRARY "${JNI_LIBS_DIR}/${ANDROID_ABI}/libSDL2.so")
  set(SDL2_MIXER_LIBRARY "${JNI_LIBS_DIR}/${ANDROID_ABI}/libSDL2_mixer.so")
  
  # Verify SDL2 library exists
  if(EXISTS "${SDL2_LIBRARY}")
    message(STATUS "Found SDL2: ${SDL2_LIBRARY}")
    
    # Set find_package style variables
    set(SDL2_FOUND TRUE)
    set(SDL2_INCLUDE_DIR "${JNI_LIBS_DIR}/../../../main/java/org/libsdl/app")
    set(SDL2_LIBRARIES "${SDL2_LIBRARY}")
    
    # Create imported library for SDL2
    if(NOT TARGET SDL2::SDL2)
      add_library(SDL2::SDL2 SHARED IMPORTED)
      set_target_properties(SDL2::SDL2 PROPERTIES
        IMPORTED_LOCATION "${SDL2_LIBRARY}"
      )
    endif()
  else()
    message(FATAL_ERROR "SDL2 library not found at ${SDL2_LIBRARY}. Run build-sdl2.sh first.")
  endif()
  
  # Verify SDL2_mixer library exists
  if(EXISTS "${SDL2_MIXER_LIBRARY}")
    message(STATUS "Found SDL2_mixer: ${SDL2_MIXER_LIBRARY}")
    
    # Set find_package style variables
    set(SDL2_MIXER_FOUND TRUE)
    set(SDL2_MIXER_INCLUDE_DIRS "${SDL2_INCLUDE_DIR}")
    set(SDL2_MIXER_LIBRARIES "${SDL2_MIXER_LIBRARY}")
    
    # Create imported library for SDL2_mixer with proper target name
    if(NOT TARGET SDL2_mixer::SDL2_mixer)
      add_library(SDL2_mixer::SDL2_mixer SHARED IMPORTED)
      set_target_properties(SDL2_mixer::SDL2_mixer PROPERTIES
        IMPORTED_LOCATION "${SDL2_MIXER_LIBRARY}"
        INTERFACE_LINK_LIBRARIES SDL2::SDL2
      )
    endif()
  else()
    message(WARNING "SDL2_mixer library not found at ${SDL2_MIXER_LIBRARY}. Audio mixing will be disabled.")
    
    # Set variables to indicate not found
    set(SDL2_MIXER_FOUND FALSE)
    
    # Create a dummy target so builds don't fail
    if(NOT TARGET SDL2_mixer::SDL2_mixer)
      add_library(SDL2_mixer::SDL2_mixer INTERFACE IMPORTED)
    endif()
  endif()

endif()
