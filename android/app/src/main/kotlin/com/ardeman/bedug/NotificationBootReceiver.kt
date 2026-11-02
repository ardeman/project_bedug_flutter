package com.ardeman.bedug

import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
import org.json.JSONArray
import java.time.Instant
import java.time.LocalDateTime
import java.time.ZoneId

/** Drops missed one-shot alerts before the plugin restores alarms after boot or an update. */
class NotificationBootReceiver : ScheduledNotificationBootReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in ACTIONS) return
        // flutter_local_notifications 22.x stores its pending alarms under this file/key.
        // Keep this schema check covered when upgrading the plugin.
        val preferences = context.getSharedPreferences(CACHE_KEY, Context.MODE_PRIVATE)
        val cached = preferences.getString(CACHE_KEY, null)
        if (cached != null) {
            preferences.edit()
                .putString(CACHE_KEY, futureNotifications(cached, Instant.now()))
                .apply()
        }
        super.onReceive(context, intent)
    }

    companion object {
        private const val CACHE_KEY = "scheduled_notifications"
        private val ACTIONS = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
        )

        internal fun futureNotifications(cached: String, now: Instant): String {
            val pending = JSONArray(cached)
            val future = JSONArray()
            for (index in 0 until pending.length()) {
                val notification = pending.getJSONObject(index)
                val scheduled = LocalDateTime.parse(notification.getString("scheduledDateTime"))
                    .atZone(ZoneId.of(notification.getString("timeZoneName")))
                    .toInstant()
                if (scheduled.isAfter(now)) future.put(notification)
            }
            return future.toString()
        }
    }
}
