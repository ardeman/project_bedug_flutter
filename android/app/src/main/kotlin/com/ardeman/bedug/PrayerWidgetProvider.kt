package com.ardeman.bedug

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.DateFormat
import java.util.Date
import java.util.Locale

class PrayerWidgetProvider : HomeWidgetProvider() {
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

    override fun onUpdate(context: Context, manager: AppWidgetManager,
                          ids: IntArray, widgetData: SharedPreferences) {
        if (ids.isEmpty()) return
        val data = runCatching {
            JSONObject(widgetData.getString("prayer_widget", "{}") ?: "{}")
        }.getOrDefault(JSONObject())
        val now = System.currentTimeMillis()
        val prayers = data.optJSONArray("prayers")
        val next = (0 until (prayers?.length() ?: 0)).asSequence()
            .mapNotNull { prayers?.optJSONObject(it) }
            .firstOrNull { it.optLong("time") > now }
        val mode = data.optInt("themeMode")
        val dark = mode == 2 || (mode == 0 &&
            context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES)
        val prefix = if (dark) "dark" else "light"
        val locale = Locale.forLanguageTag(data.optString("locale", "id"))
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)
        views.setInt(R.id.widget_root, "setLayoutDirection",
            if (locale.language == "ar") View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
        // Colors are supplied by AppColors in Flutter, including dark variants.
        if (data.has(prefix + "Background")) {
            views.setInt(R.id.widget_background, "setColorFilter", data.getLong(prefix + "Background").toInt())
            for (id in intArrayOf(R.id.widget_title, R.id.widget_prayer,
                    R.id.widget_countdown, R.id.widget_location)) {
                views.setTextColor(id, data.getLong(prefix + "Text").toInt())
            }
            views.setTextColor(R.id.widget_prayer, data.getLong(prefix + "Accent").toInt())
        }
        views.setTextViewText(R.id.widget_title, data.optString("title", "Bedug"))
        views.setTextViewText(R.id.widget_location, data.optString("location"))
        views.setViewVisibility(R.id.widget_countdown, if (next == null) View.GONE else View.VISIBLE)
        if (next != null) {
            val time = next.getLong("time")
            val formatted = DateFormat.getTimeInstance(DateFormat.SHORT, locale).format(Date(time))
            views.setTextViewText(R.id.widget_prayer, "${next.getString("name")} · $formatted")
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
        ids.forEach { manager.updateAppWidget(it, views) }
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

    private fun refreshIntent(context: Context) = PendingIntent.getBroadcast(context, 0,
        Intent(context, PrayerWidgetProvider::class.java).setAction(REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    companion object {
        private const val REFRESH = "com.ardeman.bedug.WIDGET_REFRESH"
    }
}
