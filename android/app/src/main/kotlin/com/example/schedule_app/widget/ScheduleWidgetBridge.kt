package com.example.schedule_app.widget

import android.content.Context
import android.util.AtomicFile
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File
import java.io.IOException

internal object ScheduleWidgetBridge {
    private const val channel = "schedule_app/home_widget"
    private const val fileName = "schedule-widget-v1.json"
    private val snapshotLock = Any()

    fun register(context: Context, messenger: BinaryMessenger) {
        val queue = messenger.makeBackgroundTaskQueue()
        MethodChannel(messenger, channel, StandardMethodCodec.INSTANCE, queue)
            .setMethodCallHandler { call, result ->
                if (call.method != "publish") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val payload = call.arguments as? String
                if (payload == null) {
                    result.error("invalid_snapshot", null, null)
                    return@setMethodCallHandler
                }
                try {
                    writeSnapshot(context, payload)
                    ScheduleWidgetProvider.refreshAll(context)
                    result.success(null)
                } catch (_: IOException) {
                    result.error("snapshot_write_failed", null, null)
                } catch (_: RuntimeException) {
                    result.error("widget_refresh_failed", null, null)
                }
            }
    }

    fun readSnapshot(context: Context): String = synchronized(snapshotLock) {
        String(snapshotFile(context).readFully(), Charsets.UTF_8)
    }

    private fun writeSnapshot(context: Context, payload: String) = synchronized(snapshotLock) {
        val file = snapshotFile(context)
        val stream = file.startWrite()
        try {
            stream.write(payload.toByteArray(Charsets.UTF_8))
            file.finishWrite(stream)
        } catch (error: IOException) {
            file.failWrite(stream)
            throw error
        }
    }

    private fun snapshotFile(context: Context) = AtomicFile(File(context.filesDir, fileName))
}
