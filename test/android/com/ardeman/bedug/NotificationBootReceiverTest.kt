package com.ardeman.bedug

import org.json.JSONArray
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Instant

class NotificationBootReceiverTest {
    private val now = Instant.parse("2026-11-02T05:00:00Z")

    @Test
    fun `restart drops missed alerts and preserves future alerts with their details`() {
        // Include all reminder kinds: restoration must depend only on their due time.
        val cached = """[
            {"id":1,"scheduledDateTime":"2026-10-31T04:30:00","timeZoneName":"Asia/Jakarta"},
            {"id":2,"scheduledDateTime":"2026-11-02T11:59:00","timeZoneName":"Asia/Jakarta"},
            {"id":3,"scheduledDateTime":"2026-11-02T12:00:00","timeZoneName":"Asia/Jakarta"},
            {"id":4,"scheduledDateTime":"2026-11-02T12:01:00","timeZoneName":"Asia/Jakarta","body":"reminder","sound":"bedug"},
            {"id":5,"scheduledDateTime":"2026-11-03T04:30:00","timeZoneName":"Asia/Jakarta"}
        ]"""
        val result = JSONArray(NotificationBootReceiver.futureNotifications(cached, now))
        assertEquals(2, result.length())
        assertEquals(4, result.getJSONObject(0).getInt("id"))
        assertEquals("reminder", result.getJSONObject(0).getString("body"))
        assertEquals("bedug", result.getJSONObject(0).getString("sound"))
        assertEquals(5, result.getJSONObject(1).getInt("id"))
    }

    @Test
    fun `compares instants across time zones rather than local clock times`() {
        val cached = """[
            {"id":1,"scheduledDateTime":"2026-11-02T06:00:00","timeZoneName":"Asia/Jakarta"},
            {"id":2,"scheduledDateTime":"2026-11-02T01:00:00","timeZoneName":"America/New_York"}
        ]"""
        val result = JSONArray(NotificationBootReceiver.futureNotifications(cached, now))
        assertEquals(1, result.length())
        assertEquals(2, result.getJSONObject(0).getInt("id"))
    }

    @Test
    fun `empty and fully expired schedules restore nothing`() {
        assertEquals("[]", NotificationBootReceiver.futureNotifications("[]", now))
        val expired = """[
            {"id":1,"scheduledDateTime":"2026-11-01T04:30:00","timeZoneName":"Asia/Jakarta"}
        ]"""
        assertEquals("[]", NotificationBootReceiver.futureNotifications(expired, now))
    }
}
