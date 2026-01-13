#==========================================
#
#	ODAMEX FOR ANDROID CMAKE FILE
#
#	This file configures the build for Android
#	using the Android NDK toolchain.
#
#	Usage:
#	cmake -DANDROID=ON -DCMAKE_TOOLCHAIN_FILE=android.cmake ..
#
#==========================================

message("Generating for Android")
message("Android NDK: ${ANDROID_NDK}")
message("Android ABI: ${ANDROID_ABI}")
message("Android Platform: ${ANDROID_PLATFORM}")
message("")

# Odamex specific settings for Android
set(BUILD_CLIENT 1)
set(BUILD_SERVER 0)
set(BUILD_MASTER 0)
set(BUILD_LAUNCHER 0)
set(USE_MINIUPNP 0)
set(ENABLE_PORTMIDI 0)

# This is a flag meaning we're compiling for a console/mobile platform
set(GCONSOLE 1)

# Use internal libraries for Android build
set(USE_INTERNAL_ZLIB 1)
set(USE_INTERNAL_PNG 1)
set(USE_INTERNAL_CURL 1)
set(USE_INTERNAL_JSONCPP 1)
set(USE_INTERNAL_CPPTRACE 1)
set(USE_INTERNAL_FLTK 0)  # Not needed for console builds
set(USE_INTERNAL_LIBADLMIDI 1)

# Android-specific compiler definitions
add_definitions("-DUNIX -DGCONSOLE -DANDROID")

# Android application info
set(ANDROID_APP_NAME "Odamex")
set(ANDROID_APP_PACKAGE "net.odamex.android")
set(ANDROID_APP_VERSION "12.1.0")

message("Android build configured successfully")
