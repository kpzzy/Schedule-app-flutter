package com.example.schedule_app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews
import com.example.schedule_app.MainActivity
import com.example.schedule_app.R
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.GregorianCalendar
import java.util.Locale

internal enum class ScheduleWidgetMode(val label: Int) {
    DAILY(R.string.schedule_widget_daily),
    WEEKLY(R.string.schedule_widget_weekly),
    MONTHLY(R.string.schedule_widget_monthly);

    fun store(context: Context, id: Int) {
        settings(context).edit().putString(id.toString(), name).apply()
    }

    companion object {
        private fun settings(context: Context) = context.getSharedPreferences("schedule_widget_views", Context.MODE_PRIVATE)

        fun forId(context: Context, id: Int): ScheduleWidgetMode {
            val name = settings(context).getString(id.toString(), null)
            return entries.firstOrNull { it.name == name } ?: DAILY
        }

        fun remove(context: Context, ids: IntArray) {
            val editor = settings(context).edit()
            ids.forEach { editor.remove(it.toString()) }
            editor.apply()
        }
    }
}

class ScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        refresh(context, manager, ids)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        refresh(context, manager, intArrayOf(id), options)
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        ScheduleWidgetMode.remove(context, ids)
    }

    override fun onRestored(context: Context, oldWidgetIds: IntArray, newWidgetIds: IntArray) {
        val modes = oldWidgetIds.map { ScheduleWidgetMode.forId(context, it) }
        ScheduleWidgetMode.remove(context, oldWidgetIds)
        newWidgetIds.zip(modes).forEach { (id, mode) -> mode.store(context, id) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_TIMEZONE_CHANGED || intent.action == Intent.ACTION_TIME_CHANGED) {
            refreshAll(context)
        }
    }

    companion object {
        internal fun component(context: Context) = ComponentName(context, ScheduleWidgetProvider::class.java)

        internal fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            refresh(context, manager, manager.getAppWidgetIds(component(context)))
        }

        internal fun refresh(context: Context, manager: AppWidgetManager, ids: IntArray, resized: Bundle? = null) {
            if (ids.isEmpty()) return
            val data = try {
                val json = JSONObject(ScheduleWidgetBridge.readSnapshot(context))
                json.takeIf { it.optInt("version") == 1 }
            } catch (_: IOException) {
                null
            } catch (_: JSONException) {
                null
            }
            val renderer = WidgetRenderer(context, data)
            for (id in ids) {
                val options = resized ?: manager.getAppWidgetOptions(id)
                manager.updateAppWidget(id, renderer.forOptions(id, ScheduleWidgetMode.forId(context, id), options))
            }
        }
    }
}

private class WidgetRenderer(private val context: Context, private val data: JSONObject?) {
    private val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT)
    private val today = GregorianCalendar()
    private val todayKey = key(today)
    private val weekdays = context.resources.getStringArray(R.array.schedule_widget_weekdays)
    private val days = data?.optJSONObject("days")

    fun forOptions(id: Int, mode: ScheduleWidgetMode, options: Bundle): RemoteViews {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val sizes = sizes(options)
            if (!sizes.isNullOrEmpty() && sizes.size <= 16) {
                return RemoteViews(sizes.associateWith { render(id, mode, it.width.toInt(), it.height.toInt()) })
            }
        }
        val portrait = render(id, mode,
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180),
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 110))
        val landscape = render(id, mode,
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 180),
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110))
        return RemoteViews(landscape, portrait)
    }

    @Suppress("DEPRECATION")
    private fun sizes(options: Bundle): List<SizeF>? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            options.getParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES, SizeF::class.java)
        } else {
            options.getParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES)
        }

    private fun render(id: Int, mode: ScheduleWidgetMode, width: Int, height: Int): RemoteViews {
        val root = RemoteViews(context.packageName, R.layout.schedule_widget)
        root.setOnClickPendingIntent(R.id.widget_root, PendingIntent.getActivity(context, id,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
        root.setOnClickPendingIntent(R.id.widget_configure, PendingIntent.getActivity(context, id,
            Intent(context, ScheduleWidgetConfigurationActivity::class.java)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))

        val monday = offset(today, -mondayIndex(today))
        val month = (today.clone() as Calendar).apply { set(Calendar.DAY_OF_MONTH, 1) }
        val title = context.getString(mode.label)
        val fullTitle = when (mode) {
            ScheduleWidgetMode.DAILY -> "$title · ${shortDate(today)}"
            ScheduleWidgetMode.WEEKLY -> "$title · ${shortDate(monday)}–${shortDate(offset(monday, 6))}"
            ScheduleWidgetMode.MONTHLY -> "$title · ${context.getString(R.string.schedule_widget_month,
                month.get(Calendar.YEAR), month.get(Calendar.MONTH) + 1)}"
        }
        root.setTextViewText(R.id.widget_title, if (width >= 156) fullTitle else title)
        val count = when (mode) {
            ScheduleWidgetMode.DAILY -> days?.optJSONObject(todayKey)?.optInt("count", -1) ?: -1
            ScheduleWidgetMode.WEEKLY -> data?.optJSONObject("weeks")?.optInt(key(monday), -1) ?: -1
            ScheduleWidgetMode.MONTHLY -> data?.optJSONObject("months")?.optInt(key(month).take(7), -1) ?: -1
        }
        root.setTextViewText(R.id.widget_summary, when (count) {
            -1 -> context.getString(R.string.schedule_widget_open)
            0 -> context.getString(R.string.schedule_widget_empty)
            else -> context.getString(R.string.schedule_widget_count, count)
        })
        if (count < 0) return root

        // Reserve header space and scale row capacity with the launcher's font settings.
        val fontScale = context.resources.configuration.fontScale.coerceAtLeast(1f)
        val rows = ((height - 52 * fontScale) / (22 * fontScale)).toInt().coerceIn(0, 7)
        when (mode) {
            ScheduleWidgetMode.DAILY -> {
                val items = days?.optJSONObject(todayKey)?.optJSONArray("items")
                for (index in 0 until minOf(rows, items?.length() ?: 0)) {
                    val item = items?.optJSONObject(index) ?: continue
                    val done = if (item.optBoolean("done")) "✓ " else ""
                    line(root, "${item.optString("lead")}  $done${item.optString("title")}")
                }
            }
            ScheduleWidgetMode.WEEKLY -> {
                val week = (0..6).map { offset(monday, it) }
                if (width >= 220 * fontScale && rows >= 2) {
                    gridRow(root, week, showWeekday = true)
                } else {
                    val start = if (rows < 7) mondayIndex(today).coerceAtMost(7 - rows) else 0
                    week.drop(start).take(rows).forEach { day -> line(root, daySummary(day)) }
                }
            }
            ScheduleWidgetMode.MONTHLY -> {
                if (width >= 220 * fontScale && height >= 238 * fontScale) {
                    val first = offset(month, -mondayIndex(month))
                    val header = RemoteViews(context.packageName, R.layout.schedule_widget_grid_row)
                    weekdays.forEachIndexed { index, weekday -> addCell(header, weekday, weekdayIndex = index) }
                    root.addView(R.id.widget_details, header)
                    for (week in 0..5) {
                        gridRow(root, (0..6).map { offset(first, week * 7 + it) }, month = month.get(Calendar.MONTH))
                    }
                } else {
                    val remaining = today.getActualMaximum(Calendar.DAY_OF_MONTH) - today.get(Calendar.DAY_OF_MONTH) + 1
                    (0 until remaining).asSequence().map { offset(today, it) }.filter { dayCount(it) > 0 }
                        .take(rows).forEach { line(root, daySummary(it)) }
                }
            }
        }
        return root
    }

    private fun dayCount(day: Calendar) = days?.optJSONObject(key(day))?.optInt("count") ?: 0
    private fun weekday(day: Calendar) = weekdays[mondayIndex(day)]
    private fun shortDate(day: Calendar) = context.getString(R.string.schedule_widget_short_date,
        day.get(Calendar.MONTH) + 1, day.get(Calendar.DAY_OF_MONTH))
    private fun daySummary(day: Calendar) = "${shortDate(day)} (${weekday(day)})  ${context.getString(R.string.schedule_widget_count, dayCount(day))}"

    private fun line(root: RemoteViews, text: String) {
        val row = RemoteViews(context.packageName, R.layout.schedule_widget_line)
        row.setTextViewText(R.id.widget_line_text, text)
        root.addView(R.id.widget_details, row)
    }

    private fun gridRow(root: RemoteViews, dates: List<Calendar>, showWeekday: Boolean = false, month: Int? = null) {
        val row = RemoteViews(context.packageName, R.layout.schedule_widget_grid_row)
        for (day in dates) {
            if (month == null || month == day.get(Calendar.MONTH)) {
                val count = dayCount(day)
                val number = day.get(Calendar.DAY_OF_MONTH)
                val label = if (showWeekday) "${weekday(day)} $number\n$count" else "$number${if (count > 0) "\n$count" else ""}"
                addCell(row, label, daySummary(day), key(day) == todayKey, mondayIndex(day))
            } else {
                addCell(row, "")
            }
        }
        root.addView(R.id.widget_details, row)
    }

    private fun addCell(row: RemoteViews, label: String, description: String = label, highlight: Boolean = false, weekdayIndex: Int? = null) {
        val cell = RemoteViews(context.packageName, R.layout.schedule_widget_grid_cell)
        cell.setTextViewText(R.id.widget_grid_cell, label)
        cell.setContentDescription(R.id.widget_grid_cell, description)
        when (weekdayIndex) {
            5 -> cell.setTextColor(R.id.widget_grid_cell, Color.rgb(35, 86, 170))
            6 -> cell.setTextColor(R.id.widget_grid_cell, Color.rgb(174, 39, 48))
        }
        if (highlight) {
            cell.setInt(R.id.widget_grid_cell, "setBackgroundResource", R.drawable.schedule_widget_today)
        }
        row.addView(R.id.widget_grid_row, cell)
    }

    private fun key(day: Calendar): String = formatter.format(day.time)
    private fun mondayIndex(day: Calendar) = (day.get(Calendar.DAY_OF_WEEK) + 5) % 7
    private fun offset(day: Calendar, amount: Int) = (day.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, amount) }
}
