package com.excellencecoachinghub.excellencecoachinghub

import android.os.Build
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for Android 15+ compatibility
        // This replaces the deprecated setStatusBarColor and setNavigationBarColor APIs
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Let Flutter's SystemChrome API handle system UI styling
        // The WindowInsetsControllerCompat is used by Flutter internally
    }
}
