package com.ardeman.bedug

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.DateFormat
import java.util.Date
import java.util.Locale

/**
 * The Ramadan countdown, from the week of fasts Flutter shares under `prayer_widget`'s
 * `ramadan`: to imsak from Maghrib the evening before, then to iftar.
 */
class RamadanWidgetProvider : HomeWidgetProvider() {
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
        if (appWidgetIds.isEmpty()) return
        val data = runCatching {
            JSONObject(widgetData.getString("prayer_widget", "{}") ?: "{}")
        }.getOrDefault(JSONObject())
        val ramadan = data.optJSONObject("ramadan") ?: JSONObject()
        val fasts = ramadan.optJSONArray("fasts")
        val week = (0 until (fasts?.length() ?: 0)).mapNotNull { fasts?.optJSONObject(it) }
        val now = System.currentTimeMillis()
        val views = render(context, data, ramadan, week, now)
        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }

        // Switch at the next sahur start, imsak or iftar, or when the week runs out.
        val next = (week.flatMap {
            listOf(it.optLong("since"), it.optLong("imsak"), it.optLong("iftar"))
        } + ramadan.optLong("until")).filter { it > now }.minOrNull()
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = refreshIntent(context)
        alarms.cancel(pending)
        if (next != null) {
            // Inexact by design: no extra permission, and Android may defer in Doze.
            alarms.setAndAllowWhileIdle(AlarmManager.RTC, next, pending)
        }
    }

    override fun onDisabled(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(refreshIntent(context))
        super.onDisabled(context)
    }

    private fun render(context: Context, data: JSONObject, ramadan: JSONObject,
                       week: List<JSONObject>, now: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.ramadan_widget)
        val locale = Locale.forLanguageTag(data.optString("locale", "id"))
        views.setInt(R.id.widget_root, "setLayoutDirection",
            if (locale.language == "ar") View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
        val mode = data.optInt("themeMode")
        val dark = mode == 2 || (mode == 0 &&
            context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES)
        val prefix = if (dark) "dark" else "light"
        // Colors are supplied by AppColors in Flutter, including dark variants.
        if (data.has(prefix + "Background")) {
            val text = data.getLong(prefix + "Text").toInt()
            val accent = data.getLong(prefix + "Accent").toInt()
            views.setInt(R.id.widget_background, "setColorFilter",
                data.getLong(prefix + "Background").toInt())
            for (id in intArrayOf(R.id.widget_title, R.id.widget_countdown,
                    R.id.widget_detail, R.id.widget_message)) {
                views.setTextColor(id, text)
            }
            views.setTextColor(R.id.widget_label, accent)
            // Older Android keeps the layout's accent tint.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColorStateList(R.id.widget_progress, "setProgressTintList",
                    ColorStateList.valueOf(accent))
            }
        }
        views.setOnClickPendingIntent(R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))

        val timeFormat = DateFormat.getTimeInstance(DateFormat.SHORT, locale)
        fun time(millis: Long) = timeFormat.format(Date(millis))
        var phase: Triple<JSONObject, Boolean, Long>? = null
        for (fast in week) {
            if (now >= fast.optLong("since") && now < fast.optLong("imsak")) {
                phase = Triple(fast, true, fast.optLong("since")); break
            }
            if (now >= fast.optLong("imsak") && now < fast.optLong("iftar")) {
                phase = Triple(fast, false, fast.optLong("imsak")); break
            }
        }
        val counting = phase != null
        for (id in intArrayOf(R.id.widget_label, R.id.widget_countdown,
                R.id.widget_detail, R.id.widget_progress)) {
            views.setViewVisibility(id, if (counting) View.VISIBLE else View.GONE)
        }
        views.setViewVisibility(R.id.widget_message, if (counting) View.GONE else View.VISIBLE)
        if (phase == null) {
            views.setTextViewText(R.id.widget_title, ramadan.optString("title", "Bedug"))
            val expired = !ramadan.has("until") || now >= ramadan.optLong("until")
            val next = ramadan.optString("next")
            views.setTextViewText(R.id.widget_message,
                if (expired || next.isEmpty()) data.optString("refresh", "Bedug")
                else next.replace("{date}", DateFormat.getDateInstance(DateFormat.LONG, locale)
                    .format(Date(ramadan.optLong("nextStart")))))
            return views
        }
        val (fast, isSahur, start) = phase
        val target = fast.optLong(if (isSahur) "imsak" else "iftar")
        views.setTextViewText(R.id.widget_title, fast.optString("title"))
        views.setTextViewText(R.id.widget_label,
            ramadan.optString(if (isSahur) "untilImsak" else "untilIftar"))
        views.setTextViewText(R.id.widget_detail, if (isSahur) {
            "${ramadan.optString("imsak")} ${time(target)} · " +
                "${ramadan.optString("fajr")} ${time(fast.optLong("fajr"))}"
        } else {
            "${ramadan.optString("maghrib")} ${time(target)}"
        })
        views.setChronometer(R.id.widget_countdown,
            SystemClock.elapsedRealtime() + target - now, null, true)
        views.setChronometerCountDown(R.id.widget_countdown, true)
        // A snapshot: the bar moves at each refresh, not every second.
        val elapsed = if (target > start) (now - start) * 1000 / (target - start) else 1000
        views.setProgressBar(R.id.widget_progress, 1000, elapsed.toInt().coerceIn(0, 1000), false)
        return views
    }

    private fun refreshIntent(context: Context) = PendingIntent.getBroadcast(context, 0,
        Intent(context, RamadanWidgetProvider::class.java).setAction(REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    companion object {
        private const val REFRESH = "com.ardeman.bedug.RAMADAN_WIDGET_REFRESH"
    }
}
