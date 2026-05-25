package com.example.mobile_controller

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var musicDetectionHandler: MusicDetectionHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        musicDetectionHandler = MusicDetectionHandler(this)
        musicDetectionHandler.configureFlutterEngine(flutterEngine)
    }
}