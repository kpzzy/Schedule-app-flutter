package com.example.schedule_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.schedule_app.widget.ScheduleWidgetBridge

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ScheduleWidgetBridge.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}
