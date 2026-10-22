package com.focuslock.focuslock

import org.junit.Assert.*
import org.junit.Test

class LockRulesTest {
    @Test fun callDoesNotRestartTheTenMinuteDeadline() {
        val start = 1000000L
        assertEquals(600000L, LockRules.remaining(start, 10, start))
        // A call starts after two minutes and ends after four minutes.
        assertEquals(480000L, LockRules.remaining(start, 10, start + 120000))
        assertEquals(360000L, LockRules.remaining(start, 10, start + 240000))
        assertEquals(0L, LockRules.remaining(start, 10, start + 600000))
        assertTrue(LockRules.remaining(start, 10, start + 600001) < 0)
    }

    @Test fun callsAndEmergencyScreensAreNeverRedirected() {
        assertFalse(LockRules.redirect(true, true, false, false, false))
        assertFalse(LockRules.redirect(true, false, true, false, false))
        assertFalse(LockRules.redirect(true, false, false, false, true))
    }

    @Test fun guardOnlyRedirectsOrdinaryAppsDuringALock() {
        assertTrue(LockRules.redirect(true, false, false, false, false))
        assertFalse(LockRules.redirect(false, false, false, false, false))
        assertFalse(LockRules.redirect(true, false, false, true, false))
    }
}
