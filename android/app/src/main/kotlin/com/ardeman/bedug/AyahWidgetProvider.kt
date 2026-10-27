package com.ardeman.bedug

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/** The verse of the day, from the week of days Flutter shares under `ayah_widget`. */
class AyahWidgetProvider : HomeWidgetProvider() {
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
            JSONObject(widgetData.getString("ayah_widget", "{}") ?: "{}")
        }.getOrDefault(JSONObject())
        val key = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val days = data.optJSONArray("days")
        val day = (0 until (days?.length() ?: 0)).asSequence()
            .mapNotNull { days?.optJSONObject(it) }
            .firstOrNull { it.optString("date") == key }
        val mode = data.optInt("themeMode")
        val dark = mode == 2 || (mode == 0 &&
            context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES)
        val prefix = if (dark) "dark" else "light"
        appWidgetIds.forEach { id ->
            val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // The launcher picks the largest layout that fits the widget's current size.
                RemoteViews(AyahSize.entries.associate { size ->
                    SizeF(size.width, size.height) to render(context, size, data, day, prefix)
                })
            } else {
                val options = appWidgetManager.getAppWidgetOptions(id)
                // Use the minimum size so the layout also fits after rotation.
                render(context, AyahSize.forSize(
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180),
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)),
                    data, day, prefix)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
        scheduleMidnight(context)
    }

    override fun onDisabled(context: Context) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(refreshIntent(context))
        super.onDisabled(context)
    }

    private fun render(context: Context, size: AyahSize, data: JSONObject, day: JSONObject?,
                       prefix: String): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.ayah_widget)
        val arabicReader = data.optString("locale") == "ar"
        views.setInt(R.id.widget_root, "setLayoutDirection",
            if (arabicReader) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
        // Colors are supplied by AppColors in Flutter, including dark variants.
        if (data.has(prefix + "Background")) {
            val text = data.getLong(prefix + "Text").toInt()
            views.setInt(R.id.widget_background, "setColorFilter",
                data.getLong(prefix + "Background").toInt())
            for (view in intArrayOf(R.id.widget_title, R.id.widget_reference,
                    R.id.widget_arabic, R.id.widget_translation)) {
                views.setTextColor(view, text)
            }
            views.setTextColor(R.id.widget_why, data.getLong(prefix + "Accent").toInt())
        }
        if (data.has("title")) views.setTextViewText(R.id.widget_title, data.getString("title"))
        if (day == null) {
            views.setTextViewText(R.id.widget_reference, "")
            views.setViewVisibility(R.id.widget_why, View.GONE)
            views.setViewVisibility(R.id.widget_arabic, View.GONE)
            views.setTextViewText(R.id.widget_translation, data.optString("refresh", "Bedug"))
            views.setOnClickPendingIntent(R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            return views
        }
        val translation = day.optString("translation")
        // Small sizes keep to the meaning; Arabic readers read the text itself.
        val showArabic = !size.compact || arabicReader
        views.setTextViewText(R.id.widget_reference, day.optString("reference"))
        views.setTextViewText(R.id.widget_why, day.optString("why"))
        views.setViewVisibility(R.id.widget_why, if (size.compact) View.GONE else View.VISIBLE)
        views.setTextViewText(R.id.widget_arabic, day.optString("arabic"))
        views.setViewVisibility(R.id.widget_arabic, if (showArabic) View.VISIBLE else View.GONE)
        views.setInt(R.id.widget_arabic, "setMaxLines",
            if (translation.isEmpty()) size.arabicLines * 2 else size.arabicLines)
        views.setTextViewText(R.id.widget_translation, translation)
        views.setViewVisibility(R.id.widget_translation,
            if (translation.isEmpty()) View.GONE else View.VISIBLE)
        views.setInt(R.id.widget_translation, "setMaxLines", size.translationLines)
        views.setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse(day.optString("link"))))
        return views
    }

    /** Moves to the next day's verse at midnight; inexact, so it may come a little late. */
    private fun scheduleMidnight(context: Context) {
        val midnight = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .set(AlarmManager.RTC, midnight.timeInMillis, refreshIntent(context))
    }

    private fun refreshIntent(context: Context) = PendingIntent.getBroadcast(context, 0,
        Intent(context, AyahWidgetProvider::class.java).setAction(REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    companion object {
        private const val REFRESH = "com.ardeman.bedug.AYAH_WIDGET_REFRESH"
    }
}

/** Size breakpoints in dp, smallest first, with how many lines each text gets. */
private enum class AyahSize(val width: Float, val height: Float, val compact: Boolean,
                            val arabicLines: Int, val translationLines: Int) {
    SMALL(110f, 110f, true, 2, 5),
    WIDE(250f, 110f, false, 1, 2),
    MEDIUM(250f, 180f, false, 2, 4),
    LARGE(250f, 300f, false, 4, 9);

    companion object {
        fun forSize(width: Int, height: Int): AyahSize =
            entries.filter { width >= it.width && height >= it.height }
                .maxByOrNull { it.width * it.height } ?: SMALL
    }
}
