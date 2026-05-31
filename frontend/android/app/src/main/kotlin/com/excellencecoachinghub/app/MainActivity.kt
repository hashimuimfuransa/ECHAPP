package com.excellencecoachinghub.app

import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // Enable edge-to-edge display for Android 15+ compatibility
        // This provides better backward compatibility
        enableEdgeToEdge()
        
        super.onCreate(savedInstanceState)
    }
}
