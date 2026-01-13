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
#include <unistd.h>
#include <sys/stat.h>

#define ANDROID_LOG_TAG "Odamex"

namespace Android
{

static std::string s_internalDataPath;
static std::string s_externalDataPath;

// Initialize Android-specific paths
void InitializePaths()
{
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

#endif // ANDROID
