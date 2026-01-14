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
//	Android-specific system interface
//
//-----------------------------------------------------------------------------

#pragma once

#ifdef ANDROID

#include <string>
#include <android/log.h>

namespace Android
{

// Initialize Android-specific subsystems
void InitializePaths();

// Copy essential files from APK assets to internal storage
void CopyAssetFiles();

// Get platform-specific paths
const char* GetWadsPath();
const char* GetConfigPath();

// Logging
void LogMessage(int priority, const char* fmt, ...);

} // namespace Android

// Apply Android-specific defaults (call after cvar system initialized)
extern void Android_ApplyDefaults();

#endif // ANDROID
