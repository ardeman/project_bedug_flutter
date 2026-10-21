package com.ardeman.bedug

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.DateFormat
import java.util.Date
import java.util.Locale

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager,
                                          id: Int, options: Bundle) {
        super.onAppWidgetOptionsChanged(context, manager, id, options)
        onUpdate(context, manager, intArrayOf(id), HomeWidgetPlugin.getData(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in setOf(REFRESH, Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED)) {
            val manager = AppWidgetManager.getInstance(context)
            onUpdate(context, manager,
                manager.getAppWidgetIds(ComponentName(context, javaClass)),
                HomeWidgetPlugin.getData(context))
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager,
                          appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val manager = appWidgetManager
        val ids = appWidgetIds
        if (ids.isEmpty()) return
        val data = runCatching {
            JSONObject(widgetData.getString("prayer_widget", "{}") ?: "{}")
        }.getOrDefault(JSONObject())
        val now = System.currentTimeMillis()
        val prayers = data.optJSONArray("prayers")
        val schedule = (0 until (prayers?.length() ?: 0)).asSequence()
            .mapNotNull { prayers?.optJSONObject(it) }
            .toList()
        val upcoming = schedule.filter { it.optLong("time") > now }.take(5)
        val next = upcoming.firstOrNull()
        val mode = data.optInt("themeMode")
        val dark = mode == 2 || (mode == 0 &&
            context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES)
        val prefix = if (dark) "dark" else "light"
        val locale = Locale.forLanguageTag(data.optString("locale", "id"))
        ids.forEach { id ->
            val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // The launcher picks the largest layout that fits the widget's current size.
                RemoteViews(WidgetSize.entries.associate { size ->
                    SizeF(size.width, size.height) to
                        render(context, size, data, schedule, upcoming, now, prefix, locale)
                })
            } else {
                val options = manager.getAppWidgetOptions(id)
                // Use the minimum size so the layout also fits after rotation.
                render(context, WidgetSize.forSize(
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180),
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 140)),
                    data, schedule, upcoming, now, prefix, locale)
            }
            manager.updateAppWidget(id, views)
        }
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = refreshIntent(context)
        alarms.cancel(pending)
        if (next != null) {
            // Inexact by design: no extra permission, and Android may defer in Doze.
            alarms.setAndAllowWhileIdle(AlarmManager.RTC, next.getLong("time"), pending)
        }
    }

    override fun onDisabled(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(refreshIntent(context))
        super.onDisabled(context)
    }

    private fun render(context: Context, size: WidgetSize, data: JSONObject,
                       schedule: List<JSONObject>, upcoming: List<JSONObject>, now: Long,
                       prefix: String, locale: Locale): RemoteViews {
        val next = upcoming.firstOrNull()
        val views = RemoteViews(context.packageName, size.layout)
        val text = data.optLong(prefix + "Text").toInt()
        val accent = data.optLong(prefix + "Accent").toInt()
        val colored = data.has(prefix + "Background")
        val timeFormat = DateFormat.getTimeInstance(DateFormat.SHORT, locale)
        views.setInt(R.id.widget_root, "setLayoutDirection",
            if (locale.language == "ar") View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
        // Colors are supplied by AppColors in Flutter, including dark variants.
        if (colored) {
            views.setInt(R.id.widget_background, "setColorFilter", data.getLong(prefix + "Background").toInt())
            for (id in intArrayOf(R.id.widget_title, R.id.widget_prayer,
                    R.id.widget_countdown, R.id.widget_location, R.id.widget_time)) {
                views.setTextColor(id, text)
            }
            views.setTextColor(R.id.widget_prayer, accent)
        }
        views.setTextViewText(R.id.widget_title, data.optString("title", "Bedug"))
        views.setTextViewText(R.id.widget_location, data.optString("location"))
        views.setViewVisibility(R.id.widget_countdown, if (next == null) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.widget_time,
            if (size.compact && next != null) View.VISIBLE else View.GONE)
        if (next != null) {
            val time = next.getLong("time")
            val formatted = timeFormat.format(Date(time))
            views.setTextViewText(R.id.widget_prayer,
                if (size.compact) next.getString("name") else "${next.getString("name")} · $formatted")
            views.setTextViewText(R.id.widget_time, formatted)
            views.setChronometer(R.id.widget_countdown,
                SystemClock.elapsedRealtime() + time - now, null, true)
            views.setChronometerCountDown(R.id.widget_countdown, true)
        } else {
            views.setTextViewText(R.id.widget_prayer, data.optString("refresh", "Bedug"))
        }
        val launch = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        views.setOnClickPendingIntent(R.id.widget_root, PendingIntent.getActivity(
            context, 0, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        val showDial = next != null && size.dialDp > 0 && data.optBoolean("showAnalog", true)
        val showSchedule = next != null && data.optBoolean("showSchedule", true)
        views.setViewVisibility(R.id.widget_dial, if (showDial) View.VISIBLE else View.GONE)
        if (showDial) {
            val start = schedule.lastOrNull { it.optLong("time") <= now }?.optLong("time")
                ?: data.optLong("intervalStart", now)
            val end = next!!.getLong("time")
            val remaining = if (end > start) (end - now).toFloat() / (end - start) else 1f
            views.setImageViewBitmap(R.id.widget_dial,
                countdownDial(context, remaining.coerceIn(0f, 1f), accent, size.dialDp))
        }
        when (size.schedule) {
            ScheduleStyle.ROW -> {
                views.setViewVisibility(R.id.widget_schedule, if (showSchedule) View.VISIBLE else View.GONE)
                views.removeAllViews(R.id.widget_schedule)
                if (showSchedule) upcoming.forEachIndexed { index, prayer ->
                    val slot = RemoteViews(context.packageName, R.layout.prayer_widget_slot)
                    slot.setTextViewText(R.id.slot_name, prayer.getString("name"))
                    slot.setTextViewText(R.id.slot_time, timeFormat.format(Date(prayer.getLong("time"))))
                    val ink = if (index == 0) accent else text
                    slot.setTextColor(R.id.slot_name, ink)
                    slot.setTextColor(R.id.slot_time, ink)
                    views.addView(R.id.widget_schedule, slot)
                }
            }
            ScheduleStyle.LIST -> {
                views.setViewVisibility(R.id.widget_list, if (showSchedule) View.VISIBLE else View.GONE)
                views.removeAllViews(R.id.widget_list)
                if (showSchedule) upcoming.forEachIndexed { index, prayer ->
                    val row = RemoteViews(context.packageName, R.layout.prayer_widget_row)
                    row.setTextViewText(R.id.row_name, prayer.getString("name"))
                    row.setTextViewText(R.id.row_time, timeFormat.format(Date(prayer.getLong("time"))))
                    if (index == 0) {
                        row.setViewVisibility(R.id.row_highlight, View.VISIBLE)
                        row.setInt(R.id.row_highlight, "setColorFilter", accent)
                        row.setInt(R.id.row_highlight, "setImageAlpha", HIGHLIGHT_ALPHA)
                    }
                    if (colored) {
                        val ink = if (index == 0) accent else text
                        row.setTextColor(R.id.row_name, ink)
                        row.setTextColor(R.id.row_time, ink)
                    }
                    views.addView(R.id.widget_list, row)
                }
            }
            ScheduleStyle.NONE -> Unit
        }
        return views
    }

    private fun countdownDial(context: Context, remaining: Float, accent: Int, sizeDp: Int): Bitmap {
        val size = (sizeDp * context.resources.displayMetrics.density).toInt().coerceAtLeast(sizeDp)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        // Draw in density-independent coordinates, leaving space for the dial ticks.
        canvas.scale(size / 76f, size / 76f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = accent
            style = Paint.Style.STROKE
            strokeWidth = 5f
            strokeCap = Paint.Cap.ROUND
        }
        val ring = RectF(10f, 10f, 66f, 66f)
        paint.alpha = 35
        canvas.drawOval(ring, paint)
        paint.alpha = 255
        canvas.drawArc(ring, -90f, remaining * 360, false, paint)
        paint.strokeWidth = 1.5f
        repeat(12) { tick ->
            canvas.save()
            canvas.rotate(tick * 30f, 38f, 38f)
            paint.alpha = 120
            canvas.drawLine(38f, 1f, 38f, if (tick % 3 == 0) 6f else 4f, paint)
            canvas.restore()
        }
        paint.alpha = 255
        paint.strokeWidth = 2f
        // A timer hand shows the remaining fraction, with noon at the top.
        canvas.save()
        canvas.rotate(remaining * 360, 38f, 38f)
        canvas.drawLine(38f, 38f, 38f, 19f, paint)
        canvas.restore()
        paint.style = Paint.Style.FILL
        canvas.drawCircle(38f, 38f, 3f, paint)
        return bitmap
    }

    private fun refreshIntent(context: Context) = PendingIntent.getBroadcast(context, 0,
        Intent(context, PrayerWidgetProvider::class.java).setAction(REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    companion object {
        private const val REFRESH = "com.ardeman.bedug.WIDGET_REFRESH"
        // About 16% of the accent behind the next prayer's row.
        private const val HIGHLIGHT_ALPHA = 40
    }
}

private enum class ScheduleStyle { NONE, ROW, LIST }

/**
 * Size breakpoints in dp, smallest first; a dial of 0 hides it. Every size that fits both a
 * tall narrow and a short wide breakpoint also fits a larger one, so the launcher's pick is
 * unambiguous. TINY covers one landscape row, where Pixel rows are only about 60dp tall.
 */
private enum class WidgetSize(val width: Float, val height: Float, val layout: Int,
                              val compact: Boolean, val schedule: ScheduleStyle, val dialDp: Int) {
    TINY(110f, 40f, R.layout.prayer_widget_tiny, true, ScheduleStyle.NONE, 0),
    SMALL(110f, 90f, R.layout.prayer_widget_small, true, ScheduleStyle.NONE, 0),
    SMALL_WIDE(200f, 90f, R.layout.prayer_widget_small, true, ScheduleStyle.NONE, 56),
    COMPACT(180f, 140f, R.layout.prayer_widget_compact, true, ScheduleStyle.NONE, 48),
    COMPACT_TALL(180f, 250f, R.layout.prayer_widget_compact, true, ScheduleStyle.LIST, 48),
    WIDE(280f, 140f, R.layout.prayer_widget, false, ScheduleStyle.NONE, 76),
    WIDE_SCHEDULE(280f, 180f, R.layout.prayer_widget, false, ScheduleStyle.ROW, 76),
    LARGE(280f, 320f, R.layout.prayer_widget_large, false, ScheduleStyle.LIST, 104);

    companion object {
        fun forSize(width: Int, height: Int): WidgetSize =
            entries.filter { width >= it.width && height >= it.height }
                .maxByOrNull { it.width * it.height } ?: TINY
    }
}
