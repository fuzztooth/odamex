# Version Dependencies Reference

This document catalogs all version numbers in the Odamex Android build system and explains the centralized version management system.

---

## ✅ Centralized Version Management

**All Android-related version numbers are now centralized in [gradle/dependencies.gradle](gradle/dependencies.gradle)**

### Benefits
- ✓ Update once, apply everywhere
- ✓ No version mismatches between Gradle and scripts  
- ✓ Easy to audit current versions
- ✓ Reduced maintenance burden

### Update Workflow

**Before (Multiple Files):**
```
SDL2 update requires editing:
  1. android/build-sdl2.sh (line 7, 8)
  2. android/app/build.gradle (line 190, 191)
```

**After (Single File):**
```
SDL2 update requires editing:
  1. gradle/dependencies.gradle (lines 15-16)
     ✓ Scripts automatically pick up new version
     ✓ Gradle automatically picks up new version
```

### How It Works

**Gradle Files** read variables from the parent project:
```groovy
compileSdk rootProject.ext.compileSdkVersion
minSdk rootProject.ext.minSdkVersion
implementation "androidx.appcompat:appcompat:${rootProject.ext.appCompatVersion}"
```

**Bash Scripts** parse the `.gradle` file using `sed`:
```bash
SDL_VERSION=$(grep "sdl2Version" "$GRADLE_DEPS" | sed "s/.*['\"]\\([0-9.]\\+\\)['\"].*/\\1/")
```

If the gradle file is missing, they fall back to hardcoded defaults.

**Exception:** Android Gradle Plugin version in `build.gradle:2` must remain hardcoded due to Gradle's plugin block restrictions.

---

## Quick Reference Table

**All versions below are now defined in [gradle/dependencies.gradle](gradle/dependencies.gradle)**

| Component | Current Version | Centralized? | Notes |
|-----------|----------------|--------------|-------|
| **Android SDK** |
| Compile SDK | 36 | ✅ Yes | Android 15 |
| Target SDK | 34 | ✅ Yes | Android 14 |
| Min SDK | 23 | ✅ Yes | Android 6.0 |
| **Android Build Tools** |
| Android Gradle Plugin | 8.13.2 | ⚠️ Hardcoded | `build.gradle:2` (Gradle limitation) |
| Gradle | 8.13 | No | `gradle-wrapper.properties:3` |
| Gradle Wrapper Bootstrap | 8.2.0 | No | Download scripts |
| CMake | 3.22.1 | ✅ Yes | NDK's bundled CMake |
| NDK | 27.0.12077973 | ✅ Yes | Must match installation |
| **SDL Libraries** |
| SDL2 | 2.30.8 | ✅ Yes | Core library |
| SDL2_mixer | 2.8.0 | ✅ Yes | Audio mixer |
| **Android Dependencies** |
| AndroidX AppCompat | 1.6.1 | ✅ Yes | Compatibility library |
| Material Components | 1.11.0 | ✅ Yes | Material Design |
| **Application** |
| Odamex Version | 12.1.0 | ✅ Yes | App version string |
| Version Code | 1 | ✅ Yes | Numeric version |

---

## Detailed Breakdown

### Central Version File: gradle/dependencies.gradle

All Android-related versions are defined here in the `ext {}` block:

```groovy
ext {
    // Android SDK versions
    compileSdkVersion = 36
    minSdkVersion = 23
    targetSdkVersion = 34
    
    // Application version
    appVersionCode = 1
    appVersionName = '12.1.0'
    
    // Build tools
    cmakeVersion = '3.22.1'
    ndkVersion = '27.0.12077973'
    
    // SDL libraries
    sdl2Version = '2.30.8'
    sdl2MixerVersion = '2.8.0'
    
    // AndroidX dependencies
    appCompatVersion = '1.6.1'
    materialVersion = '1.11.0'
}
```

These are automatically used by:
- **Gradle builds**: via `rootProject.ext.variableName`
- **Bash scripts**: via parsing with `grep` and `sed`

---

### 1. Android Build Configuration

**Referenced in: `android/app/build.gradle`**

```groovy
android {
    namespace 'net.odamex.android'
    compileSdk 36                    // Line 7 - Target API for compilation
    
    defaultConfig {
        applicationId "net.odamex.android"
        minSdk 23                    // Line 11 - Minimum supported Android version
        targetSdk 34                 // Line 12 - Target API for runtime
        versionCode 1                // Line 13 - Numeric version for Play Store
        versionName "12.1.0"         // Line 14 - Human-readable version
    }
    
    externalNativeBuild {
        cmake {
            version '3.22.1'         // Line 58 - Must match NDK's CMake
        }
    }
}
```

**Update Frequency:** 
- `compileSdk`: Update when new Android API released (annually)
- `targetSdk`: Update when Play Store requirements change
- `minSdk`: Rarely change (impacts user base)
- `versionCode`/`versionName`: Each release

---

### 2. Gradle Build System

**File: `android/build.gradle`**
```groovy
plugins {
    id 'com.android.application' version '8.13.2' apply false  // Line 2
}
```

**File: `android/gradle/wrapper/gradle-wrapper.properties`**
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.13-bin.zip
```

**File: `android/download-wrapper.sh` and `android/download-wrapper.ps1`**
```bash
WRAPPER_URL="https://raw.githubusercontent.com/gradle/gradle/v8.2.0/gradle/wrapper/gradle-wrapper.jar"
```

**Update Considerations:**
- Android Gradle Plugin and Gradle versions must be compatible
- See: https://developer.android.com/build/releases/gradle-plugin
- Wrapper bootstrap version (8.2.0) doesn't need frequent updates

---

### 3. SDL2 Libraries (Android Build)

**File: `android/build-sdl2.sh`**
```bash
SDL_VERSION="2.30.8"              # Line 7
MIXER_VERSION="2.8.0"             # Line 8
NDK_PATH="$ANDROID_HOME/ndk/27.0.12077973"  # Line 26
CMAKE_BIN="$ANDROID_HOME/cmake/3.22.1/bin/cmake"  # Line 34
```

**File: `android/app/build.gradle`**
```groovy
task downloadSDL2 {
    doLast {
        def sdlVersion = "2.30.8"     // Line 190
        def mixerVersion = "2.8.0"    // Line 191
    }
}
```

**Update Process:**
1. Check for new SDL2 releases: https://github.com/libsdl-org/SDL/releases
2. Check for new SDL2_mixer releases: https://github.com/libsdl-org/SDL_mixer/releases
3. Update both `build-sdl2.sh` and `app/build.gradle` in sync
4. Re-run `./build-sdl2.sh` to rebuild libraries
5. Test thoroughly (ABI compatibility)

**Critical Note:** SDL versions must match exactly between:
- Build script downloads
- CMake configuration
- Runtime expectations

---

### 4. NDK and CMake Versions

**NDK Version: 27.0.12077973**
- Location: `android/build-sdl2.sh:26`
- Install via Android Studio: Tools → SDK Manager → SDK Tools → NDK
- Must be installed before building

**CMake Version: 3.22.1**
- Location: `android/app/build.gradle:58`, `android/build-sdl2.sh:34`
- Bundled with NDK
- Install via Android Studio: SDK Manager → CMake checkbox

**Compatibility Matrix:**
| NDK Version | CMake Version | Gradle Plugin | Notes |
|-------------|---------------|---------------|-------|
| 27.0.x | 3.22.1 | 8.1+ | Current |
| 26.0.x | 3.22.1 | 8.0+ | Previous LTS |

---

### 5. Android Dependencies (Maven)

**File: `android/app/build.gradle`**
```groovy
dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'        // Line 216
    implementation 'com.google.android.material:material:1.11.0'  // Line 217
}
```

**Update Process:**
1. Check for updates: https://developer.android.com/jetpack/androidx/versions
2. Review migration guides for breaking changes
3. Update version numbers in `app/build.gradle`
4. Rebuild and test UI components

**Update Frequency:** 
- Check quarterly for security/bug fixes
- Major versions may require code changes

---

### 6. Desktop/Windows Libraries (Non-Android)

**File: `libraries/SDL-lib.cmake`**
```cmake
# SDL2 for Windows (Visual Studio)
https://www.libsdl.org/release/SDL2-devel-2.32.8-VC.zip      # Line 11

# SDL2 for MinGW
https://www.libsdl.org/release/SDL2-devel-2.32.8-mingw.tar.gz  # Line 29

# SDL2_mixer for Windows
https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-devel-2.8.1-VC.zip  # Line 88
```

**Note:** These are for desktop builds only, not Android. Different version (2.32.8 vs 2.30.8) is intentional.

**File: `libraries/wxWidgets-lib.cmake`**
```cmake
# wxWidgets 3.1.5 (for launcher GUI on desktop)
https://github.com/wxWidgets/wxWidgets/releases/download/v3.1.5/...
```

**Impact on Android:** None - these libraries are not used in Android builds.

---

## Version Update Checklist

✅ **Most versions now centralized in `gradle/dependencies.gradle`**

### Simple Version Update (Centralized)
For versions in `gradle/dependencies.gradle`:
- [ ] Edit `android/gradle/dependencies.gradle`
- [ ] Update the version number in the `ext {}` block
- [ ] Save the file
- [ ] Re-run build scripts if updating SDL/NDK/CMake
- [ ] Clean rebuild: `./gradlew clean assembleDebug`
- [ ] Test on device/emulator

**Applies to:** SDL2, SDL2_mixer, NDK, CMake, SDK versions, AndroidX dependencies, app version

---

### SDL2 Update (Now Centralized ✅)
- [ ] Edit `gradle/dependencies.gradle` → update `sdl2Version` and `sdl2MixerVersion`
- [ ] Re-run `./build-sdl2.sh` in Git Bash
- [ ] Clean rebuild: `./gradlew clean assembleDebug`
- [ ] Test on device/emulator

### Android SDK Update (Now Centralized ✅)
- [ ] Edit `gradle/dependencies.gradle` → update SDK versions
- [ ] Update `gradle.properties` suppressUnsupportedCompileSdk if needed
- [ ] Review Android behavior changes for new API level
- [ ] Test on device with new Android version

### Gradle Update (Partially Manual)
- [ ] Update `build.gradle` Android Gradle Plugin version (line 2) - **Manual, cannot be centralized**
- [ ] Update `gradle-wrapper.properties` Gradle distribution
- [ ] Check compatibility: https://developer.android.com/build/releases/gradle-plugin
- [ ] Update `download-wrapper.sh/ps1` if bootstrap version needed
- [ ] Test build: `./gradlew --version`

### NDK Update (Now Centralized ✅)
- [ ] Install new NDK via Android Studio SDK Manager
- [ ] Edit `gradle/dependencies.gradle` → update `ndkVersion`
- [ ] Check if CMake version changed → update `cmakeVersion` if needed
- [ ] Re-run `./build-sdl2.sh` to rebuild SDL with new NDK
- [ ] Clean rebuild entire project

### AndroidX Dependencies Update (Now Centralized ✅)
- [ ] Edit `gradle/dependencies.gradle` → update dependency versions
- [ ] Check for migration guides: https://developer.android.com/jetpack/androidx/versions
- [ ] Rebuild and test UI

---

## Centralization Opportunities

### Current State
Version numbers are **duplicated** in multiple locations:
- SDL versions appear in 2 files (`build-sdl2.sh`, `app/build.gradle`)
- NDK version hardcoded in build scripts
- CMake version in multiple places

### Possible Improvements

#### Option 1: Gradle Properties (Recommended for Android-specific versions)
Create `android/gradle/dependencies.gradle`:
```groovy
ext {
    // Android SDK
    compileSdkVersion = 36
    minSdkVersion = 23
    targetSdkVersion = 34
    
    // Build tools
    androidGradlePluginVersion = '8.13.2'
    cmakeVersion = '3.22.1'
    ndkVersion = '27.0.12077973'
    
    // SDL
    sdl2Version = '2.30.8'
    sdl2MixerVersion = '2.8.0'
    
    // AndroidX
    appCompatVersion = '1.6.1'
    materialVersion = '1.11.0'
}
```

Apply in `build.gradle`:
```groovy
apply from: 'gradle/dependencies.gradle'

plugins {
    id 'com.android.application' version androidGradlePluginVersion apply false
}
```

**Pros:**
- Single source of truth for Gradle builds
- Can be referenced in tasks and scripts
- Standard Gradle pattern

**Cons:**
- Bash scripts would still need separate definitions
- Adds complexity for a small project

#### Option 2: Environment Variables
Export versions in a sourced config file:
```bash
# android/build-config.sh
export SDL_VERSION="2.30.8"
export MIXER_VERSION="2.8.0"
export NDK_VERSION="27.0.12077973"
```

**Pros:**
- Shared between scripts
- Easy to override for testing

**Cons:**
- Requires sourcing before running scripts
- Gradle can't easily read these

#### Option 3: Keep Current (Status Quo)
**Pros:**
- Simple and explicit
- No indirection
- Easy to understand for contributors

**Cons:**
- Must update multiple files
- Risk of version mismatches

---

## Recommendation

✅ **IMPLEMENTED: Gradle Properties Centralization**

As of this version, Android-related version numbers are now centralized in **[gradle/dependencies.gradle](gradle/dependencies.gradle)**:

**Single Source of Truth:**
- Android SDK versions (compileSdk, minSdk, targetSdk)
- Application version (code & name)
- Build tool versions (CMake, NDK)
- SDL library versions (SDL2, SDL2_mixer)
- AndroidX dependency versions

**Automatic Propagation:**
- ✅ Gradle builds read from `gradle/dependencies.gradle`
- ✅ Bash scripts (`build-sdl2.sh`, `build-protoc.sh`) parse the same file
- ✅ Single file to update for version bumps
- ⚠️ Android Gradle Plugin version must remain hardcoded in `build.gradle` (Gradle limitation)

**To Update a Version:**
1. Edit `android/gradle/dependencies.gradle`
2. Change the version number in the `ext {}` block
3. Re-run build scripts if needed
4. All files automatically use the new version

**Exception:** The Android Gradle Plugin version in `build.gradle` line 2 cannot use a variable due to Gradle's plugins block restrictions. This must be updated manually.

---

## Version Compatibility Notes

### Tested Combinations (January 2026)
- ✅ Android SDK 36 (Android 15) + NDK 27.0.12077973 + CMake 3.22.1
- ✅ SDL 2.30.8 + SDL_mixer 2.8.0
- ✅ Gradle 8.13 + Android Gradle Plugin 8.13.2
- ✅ Min SDK 23 (covers 98%+ of Android devices)

### Known Issues
- NDK 26.x and older: May have issues with protobuf compilation
- Gradle Plugin < 8.0: Does not support CMake 3.22.1
- SDL 2.28.x and older: Missing Android API 33+ compatibility fixes

---

## External Resources

- **Android Gradle Plugin Releases:** https://developer.android.com/build/releases/gradle-plugin
- **NDK Releases:** https://developer.android.com/ndk/downloads/revision_history
- **SDL2 Releases:** https://github.com/libsdl-org/SDL/releases
- **SDL2_mixer Releases:** https://github.com/libsdl-org/SDL_mixer/releases
- **AndroidX Versions:** https://developer.android.com/jetpack/androidx/versions

---

## Maintenance Schedule

| Component | Check Frequency | Last Checked | Next Check |
|-----------|----------------|--------------|------------|
| Android SDK | Quarterly | Jan 2026 | Apr 2026 |
| NDK | Biannually | Jan 2026 | Jul 2026 |
| SDL2 | Biannually | Jan 2026 | Jul 2026 |
| Gradle | Quarterly | Jan 2026 | Apr 2026 |
| AndroidX | Quarterly | Jan 2026 | Apr 2026 |
