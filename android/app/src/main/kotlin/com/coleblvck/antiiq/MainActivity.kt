package com.coleblvck.antiiq

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: AudioServiceActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the custom audio metadata plugin
        flutterEngine.plugins.add(AudioMetadataPlugin())
    }
}