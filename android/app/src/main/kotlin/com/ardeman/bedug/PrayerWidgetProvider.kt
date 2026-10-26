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
import android.graphics.Path
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
                countdownDial(context, remaining.coerceIn(0f, 1f), accent, size.dialDp,
                    next.optString("key")))
        }
        when (size.schedule) {
            ScheduleStyle.ROW -> {
                views.setViewVisibility(R.id.widget_schedule, if (showSchedule) View.VISIBLE else View.GONE)
                views.removeAllViews(R.id.widget_schedule)
                if (showSchedule) upcoming.drop(1).forEach { prayer ->
                    val slot = RemoteViews(context.packageName, R.layout.prayer_widget_slot)
                    slot.setImageViewBitmap(R.id.slot_icon, prayerIcon(prayer.optString("key"), text))
                    slot.setTextViewText(R.id.slot_name, prayer.getString("name"))
                    slot.setTextViewText(R.id.slot_time, timeFormat.format(Date(prayer.getLong("time"))))
                    val ink = text
                    slot.setTextColor(R.id.slot_name, ink)
                    slot.setTextColor(R.id.slot_time, ink)
                    views.addView(R.id.widget_schedule, slot)
                }
            }
            ScheduleStyle.LIST -> {
                views.setViewVisibility(R.id.widget_list, if (showSchedule) View.VISIBLE else View.GONE)
                views.removeAllViews(R.id.widget_list)
                if (showSchedule) upcoming.drop(1).forEach { prayer ->
                    val row = RemoteViews(context.packageName, R.layout.prayer_widget_row)
                    row.setImageViewBitmap(R.id.row_icon, prayerIcon(prayer.optString("key"), text))
                    row.setTextViewText(R.id.row_name, prayer.getString("name"))
                    row.setTextViewText(R.id.row_time, timeFormat.format(Date(prayer.getLong("time"))))
                    if (colored) {
                        val ink = text
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

    private fun countdownDial(context: Context, remaining: Float, accent: Int, sizeDp: Int,
                              key: String): Bitmap {
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
        drawSky(canvas, key, paint)
        return bitmap
    }

    private fun prayerIcon(key: String, ink: Int): Bitmap {
        // Crop the 24-unit sky symbol out of the dial's 76-unit canvas.
        val bitmap = Bitmap.createBitmap(48, 48, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.scale(2f, 2f)
        canvas.translate(-26f, -26f)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = ink
            strokeWidth = 2f
            strokeCap = Paint.Cap.ROUND
            style = Paint.Style.STROKE
        }
        drawSky(canvas, key, paint)
        return bitmap
    }

    /** Match Prayer Times: moon, sun, cloud, moon with cloud, moon. */
    private fun drawSky(canvas: Canvas, key: String, paint: Paint) {
        when (key) {
            "dhuhr" -> drawSun(canvas, paint, core = 5.5f, rays = 8.5f..11.5f)
            "asr" -> drawCloud(canvas, paint)
            "maghrib" -> drawMaghrib(canvas, paint)
            "fajr" -> drawFajr(canvas, paint)
            "isha" -> drawIsha(canvas, paint)
            else -> {
                paint.style = Paint.Style.FILL
                canvas.drawCircle(38f, 38f, 3f, paint)
            }
        }
    }

    // Google Material Icons nights_stay_outlined, CC BY 4.0; normalized to the dial.
    // https://github.com/google/material-design-icons
    // https://creativecommons.org/licenses/by/4.0/
    private fun drawMaghrib(canvas: Canvas, paint: Paint) {
        val path = Path().apply {
            moveTo(45.78128f, 43.53128f)
            cubicTo(43.29680f, 43.53128f, 39.21872f, 42.17192f, 37.10936f, 38.09384f)
            cubicTo(34.76552f, 33.54680f, 36.59384f, 29.60936f, 37.62512f, 28.01552f)
            cubicTo(32.28128f, 28.20320f, 27.96872f, 32.60936f, 27.96872f, 38.00000f)
            cubicTo(27.96872f, 38.14064f, 28.01552f, 38.28128f, 28.01552f, 38.42192f)
            cubicTo(28.62512f, 38.14064f, 29.28128f, 38.00000f, 29.98448f, 38.00000f)
            cubicTo(29.98448f, 34.90616f, 31.71872f, 32.23448f, 34.29680f, 30.92192f)
            cubicTo(33.78128f, 33.07808f, 33.73448f, 35.93744f, 35.32808f, 38.98448f)
            cubicTo(36.87488f, 42.03128f, 39.50000f, 43.95320f, 42.12512f, 44.84384f)
            cubicTo(40.90616f, 45.59384f, 39.45320f, 46.01552f, 38.00000f, 46.01552f)
            cubicTo(37.48448f, 46.01552f, 36.96872f, 45.96872f, 36.50000f, 45.87488f)
            cubicTo(36.12512f, 46.57808f, 35.56256f, 47.14064f, 34.85936f, 47.51552f)
            cubicTo(35.84384f, 47.84384f, 36.92192f, 48.03128f, 38.00000f, 48.03128f)
            cubicTo(41.46872f, 48.03128f, 44.56256f, 46.20320f, 46.34384f, 43.48448f)
            cubicTo(46.20320f, 43.48448f, 45.96872f, 43.53128f, 45.78128f, 43.53128f)
            close()
            moveTo(32.98448f, 41.98448f)
            lineTo(32.79680f, 41.98448f)
            cubicTo(32.42192f, 40.85936f, 31.29680f, 40.01552f, 29.98448f, 40.01552f)
            cubicTo(28.34384f, 40.01552f, 26.98448f, 41.32808f, 26.98448f, 43.01552f)
            cubicTo(26.98448f, 44.65616f, 28.34384f, 46.01552f, 29.98448f, 46.01552f)
            cubicTo(30.64064f, 46.01552f, 32.46872f, 46.01552f, 32.98448f, 46.01552f)
            cubicTo(34.10936f, 46.01552f, 35.00000f, 45.07808f, 35.00000f, 44.00000f)
            cubicTo(35.00000f, 42.92192f, 34.10936f, 41.98448f, 32.98448f, 41.98448f)
            close()
        }
        paint.style = Paint.Style.FILL
        canvas.drawPath(path, paint)
    }

    // Material Icons bedtime_outlined; attribution and license above drawMaghrib.
    private fun drawFajr(canvas: Canvas, paint: Paint) {
        val path = Path().apply {
            moveTo(35.28128f, 30.50000f)
            cubicTo(33.64064f, 38.04680f, 39.03128f, 42.92192f, 42.92192f, 44.28128f)
            cubicTo(41.56256f, 45.35936f, 39.82808f, 46.01552f, 38.00000f, 46.01552f)
            cubicTo(33.59384f, 46.01552f, 29.98448f, 42.40616f, 29.98448f, 38.00000f)
            cubicTo(29.98448f, 34.53128f, 32.18744f, 31.57808f, 35.28128f, 30.50000f)
            close()
            moveTo(38.00000f, 28.01552f)
            cubicTo(32.42192f, 28.01552f, 28.01552f, 32.56256f, 28.01552f, 38.00000f)
            cubicTo(28.01552f, 43.53128f, 32.46872f, 47.98448f, 38.00000f, 47.98448f)
            cubicTo(41.70320f, 47.98448f, 44.93744f, 45.96872f, 46.67192f, 42.96872f)
            cubicTo(39.17192f, 42.73448f, 34.57808f, 34.53128f, 38.32808f, 28.01552f)
            cubicTo(38.23448f, 28.01552f, 38.09384f, 28.01552f, 38.00000f, 28.01552f)
            close()
        }
        paint.style = Paint.Style.FILL
        canvas.drawPath(path, paint)
    }

    // Material Icons dark_mode_outlined; attribution and license above drawMaghrib.
    private fun drawIsha(canvas: Canvas, paint: Paint) {
        val path = Path().apply {
            moveTo(35.37488f, 31.53128f)
            cubicTo(35.18744f, 32.14064f, 35.09384f, 32.79680f, 35.09384f, 33.50000f)
            cubicTo(35.09384f, 37.57808f, 38.42192f, 40.90616f, 42.50000f, 40.90616f)
            cubicTo(43.20320f, 40.90616f, 43.85936f, 40.81256f, 44.46872f, 40.62512f)
            cubicTo(43.43744f, 43.20320f, 40.95320f, 44.98448f, 38.00000f, 44.98448f)
            cubicTo(34.15616f, 44.98448f, 31.01552f, 41.84384f, 31.01552f, 38.00000f)
            cubicTo(31.01552f, 35.04680f, 32.79680f, 32.56256f, 35.37488f, 31.53128f)
            close()
            moveTo(38.00000f, 29.00000f)
            cubicTo(33.03128f, 29.00000f, 29.00000f, 33.03128f, 29.00000f, 38.00000f)
            cubicTo(29.00000f, 42.96872f, 33.03128f, 47.00000f, 38.00000f, 47.00000f)
            cubicTo(42.96872f, 47.00000f, 47.00000f, 42.96872f, 47.00000f, 38.00000f)
            cubicTo(47.00000f, 37.53128f, 46.95320f, 37.06256f, 46.90616f, 36.64064f)
            cubicTo(45.92192f, 38.00000f, 44.32808f, 38.89064f, 42.50000f, 38.89064f)
            cubicTo(39.50000f, 38.89064f, 37.10936f, 36.50000f, 37.10936f, 33.50000f)
            cubicTo(37.10936f, 31.67192f, 38.00000f, 30.07808f, 39.35936f, 29.09384f)
            cubicTo(38.93744f, 29.04680f, 38.46872f, 29.00000f, 38.00000f, 29.00000f)
            close()
        }
        paint.style = Paint.Style.FILL
        canvas.drawPath(path, paint)
    }

    private fun drawCloud(canvas: Canvas, paint: Paint) {
        val cloud = Path().apply {
            moveTo(32f, 47f)
            cubicTo(24f, 47f, 24f, 37f, 31f, 37f)
            cubicTo(31f, 28f, 43f, 28f, 45f, 37f)
            cubicTo(53f, 37f, 53f, 47f, 45f, 47f)
            close()
        }
        canvas.drawPath(cloud, paint)
    }

    private fun drawSun(canvas: Canvas, paint: Paint, core: Float,
                        rays: ClosedFloatingPointRange<Float>) {
        paint.style = Paint.Style.FILL
        canvas.drawCircle(38f, 38f, core, paint)
        paint.style = Paint.Style.STROKE
        repeat(8) { ray ->
            canvas.save()
            canvas.rotate(ray * 45f, 38f, 38f)
            canvas.drawLine(38f, 38f - rays.start, 38f, 38f - rays.endInclusive, paint)
            canvas.restore()
        }
    }

    private fun refreshIntent(context: Context) = PendingIntent.getBroadcast(context, 0,
        Intent(context, PrayerWidgetProvider::class.java).setAction(REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    companion object {
        private const val REFRESH = "com.ardeman.bedug.WIDGET_REFRESH"
        // About 16% of the accent behind the next prayer's row.
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
