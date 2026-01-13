package net.odamex.android;

import org.libsdl.app.SDLActivity;
import android.os.Bundle;

public class MainActivity extends SDLActivity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    protected String[] getLibraries() {
        return new String[] {
            "SDL2",
            "SDL2_mixer",
            "odamex"
        };
    }

    @Override
    protected String getMainSharedObject() {
        return getContext().getApplicationInfo().nativeLibraryDir + "/libodamex.so";
    }
}
