package com.example.schedule_app.widget

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import com.example.schedule_app.R

class ScheduleWidgetConfigurationActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        setResult(RESULT_CANCELED, result)

        val manager = AppWidgetManager.getInstance(this)
        if (intent.action != AppWidgetManager.ACTION_APPWIDGET_CONFIGURE ||
            manager.getAppWidgetInfo(widgetId)?.provider != ScheduleWidgetProvider.component(this)) {
            finish()
            return
        }

        val modes = ScheduleWidgetMode.entries
        var selection = ScheduleWidgetMode.forId(this, widgetId).ordinal
        AlertDialog.Builder(this)
            .setTitle(R.string.schedule_widget_configure)
            .setSingleChoiceItems(modes.map { getString(it.label) }.toTypedArray(), selection) { _, position ->
                selection = position
            }
            .setNegativeButton(android.R.string.cancel) { _, _ -> finish() }
            .setPositiveButton(android.R.string.ok) { _, _ ->
                modes[selection].store(this, widgetId)
                ScheduleWidgetProvider.refresh(this, manager, intArrayOf(widgetId))
                setResult(RESULT_OK, result)
                finish()
            }
            .setOnCancelListener { finish() }
            .show()
    }
}
