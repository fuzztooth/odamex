// Emacs style mode select   -*- C++ -*-
//-----------------------------------------------------------------------------
//
// Copyright (C) 2006-2026 by The Odamex Team.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//	Android-specific I/O and initialization
//
//-----------------------------------------------------------------------------

#include "android_system.h"

#ifdef ANDROID

#include <SDL.h>
#include <android/log.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <jni.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fstream>

#define ANDROID_LOG_TAG "Odamex"

namespace Android
{

static std::string s_internalDataPath;
static std::string s_externalDataPath;

// Initialize Android-specific paths
void InitializePaths()
{
	// Force OpenGL ES2 renderer BEFORE any SDL video initialization
	SDL_SetHint(SDL_HINT_RENDER_DRIVER, "opengles2");
	__android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, 
		"Set SDL_HINT_RENDER_DRIVER=opengles2 (early init)");
	
	// Get internal storage path from SDL
	const char* internal = SDL_AndroidGetInternalStoragePath();
	if (internal)
	{
		s_internalDataPath = internal;
		__android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, 
			"Internal storage: %s", internal);
	}

	// Get external storage path from SDL
	const char* external = SDL_AndroidGetExternalStoragePath();
	if (external)
	{
		s_externalDataPath = external;
		__android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, 
			"External storage: %s", external);
	}

	// Create necessary directories
	std::string wadsDir = s_internalDataPath + "/wads";
	mkdir(wadsDir.c_str(), 0755);
	
	std::string configDir = s_internalDataPath + "/config";
	mkdir(configDir.c_str(), 0755);
	
	// Copy essential WAD files from assets
	CopyAssetFiles();
}

// Helper function to copy a file from assets to internal storage
static bool CopyAssetFile(JNIEnv* env, jobject assetManager, 
	const char* assetName, const std::string& destPath)
{
	// Get the AAssetManager from the Java AssetManager object
	AAssetManager* mgr = AAssetManager_fromJava(env, assetManager);
	if (!mgr)
	{
		__android_log_print(ANDROID_LOG_ERROR, ANDROID_LOG_TAG, 
			"Failed to get AAssetManager");
		return false;
	}
	
	// Open the asset file
	AAsset* asset = AAssetManager_open(mgr, assetName, AASSET_MODE_BUFFER);
	if (!asset)
	{
		__android_log_print(ANDROID_LOG_ERROR, ANDROID_LOG_TAG, 
			"Failed to open asset: %s", assetName);
		return false;
	}
	
	// Get the file size
	off_t size = AAsset_getLength(asset);
	
	// Read the asset data
	const void* buffer = AAsset_getBuffer(asset);
	if (!buffer)
	{
		__android_log_print(ANDROID_LOG_ERROR, ANDROID_LOG_TAG, 
			"Failed to read asset buffer: %s", assetName);
		AAsset_close(asset);
		return false;
	}
	
	// Write to destination file
	std::ofstream out(destPath, std::ios::binary);
	if (!out)
	{
		__android_log_print(ANDROID_LOG_ERROR, ANDROID_LOG_TAG, 
			"Failed to create destination file: %s", destPath.c_str());
		AAsset_close(asset);
		return false;
	}
	
	out.write(static_cast<const char*>(buffer), size);
	out.close();
	AAsset_close(asset);
	
	__android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, 
		"Copied asset %s to %s (%ld bytes)", assetName, destPath.c_str(), (long)size);
	
	return true;
}

// Copy essential WAD files from APK assets to internal storage
void CopyAssetFiles()
{
	// Get the JNI environment
	JNIEnv* env = (JNIEnv*)SDL_AndroidGetJNIEnv();
	if (!env)
	{
		__android_log_print(ANDROID_LOG_ERROR, ANDROID_LOG_TAG, 
			"Failed to get JNI environment");
		return;
	}
	
	// Get the Activity's AssetManager
	jobject activity = (jobject)SDL_AndroidGetActivity();
	if (!activity)
	{
		__android_log_print(ANDROID_LOG_ERROR, ANDROID_LOG_TAG, 
			"Failed to get Android activity");
		return;
	}
	
	jclass activityClass = env->GetObjectClass(activity);
	jmethodID getAssets = env->GetMethodID(activityClass, "getAssets", 
		"()Landroid/content/res/AssetManager;");
	jobject assetManager = env->CallObjectMethod(activity, getAssets);
	
	// Copy odamex.wad if it doesn't exist
	std::string wadsDir = s_internalDataPath + "/wads";
	std::string odamexWadPath = wadsDir + "/odamex.wad";
	
	// Check if file already exists
	struct stat buffer;
	if (stat(odamexWadPath.c_str(), &buffer) != 0)
	{
		__android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, 
			"Copying odamex.wad from assets...");
		CopyAssetFile(env, assetManager, "odamex.wad", odamexWadPath);
	}
	else
	{
		__android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, 
			"odamex.wad already exists in internal storage");
	}
	
	// Set TIMIDITY_CFG for SDL_mixer - point to assets
	// SDL_mixer on Android reads from assets, not filesystem
	std::string timidityConfig = "timidity/timidity.cfg";
	
	SDL_setenv("TIMIDITY_CFG", timidityConfig.c_str(), 1);
	__android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, 
		"Set TIMIDITY_CFG=%s (in assets)", timidityConfig.c_str());
	
	// Clean up local references
	env->DeleteLocalRef(assetManager);
	env->DeleteLocalRef(activityClass);
	env->DeleteLocalRef(activity);
}

// Get the path where WAD files should be stored/loaded
const char* GetWadsPath()
{
	static std::string wadsPath;
	if (wadsPath.empty())
	{
		wadsPath = s_internalDataPath + "/wads";
	}
	return wadsPath.c_str();
}

// Get the path where config files should be stored
const char* GetConfigPath()
{
	static std::string configPath;
	if (configPath.empty())
	{
		configPath = s_internalDataPath + "/config";
	}
	return configPath.c_str();
}

// Android logging wrapper
void LogMessage(int priority, const char* fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	__android_log_vprint(priority, ANDROID_LOG_TAG, fmt, args);
	va_end(args);
}

} // namespace Android

// Apply Android-specific defaults (call after cvar system is initialized)
void Android_ApplyDefaults()
{
	extern void AddCommandString(const std::string &cmd, uint32_t key);
	
	AddCommandString("vid_32bpp 1", 0);
	AddCommandString("vid_displayfps 2", 0);
	AddCommandString("r_optimize detect", 0);
	
	__android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, 
		"Applied Android defaults: vid_32bpp=1, vid_displayfps=2, r_optimize=detect");
}

#endif // ANDROID
