package com.ytscrollingkiller.ytscrolling_killer

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Watches supported browsers for YouTube Shorts URLs and opens this app.
 */
class ShortsAccessibilityService : AccessibilityService() {

    private var lastVideoId: String? = null
    private var lastLaunchElapsedMs: Long = 0L

    override fun onServiceConnected() {
        serviceInfo = serviceInfo?.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = flags or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg !in WATCHED_PACKAGES) return

        val root = rootInActiveWindow ?: return
        try {
            val url = findUrl(root) ?: return
            val videoId = extractShortsId(url) ?: return
            maybeLaunch(videoId)
        } finally {
            root.recycle()
        }
    }

    override fun onInterrupt() {
        // No-op
    }

    private fun maybeLaunch(videoId: String) {
        val now = SystemClock.elapsedRealtime()
        if (videoId == lastVideoId && now - lastLaunchElapsedMs < DEBOUNCE_MS) {
            return
        }
        lastVideoId = videoId
        lastLaunchElapsedMs = now

        val uri = Uri.parse("ytsk://short/$videoId")
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            setPackage(packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open short $videoId", e)
        }
    }

    private fun findUrl(root: AccessibilityNodeInfo): String? {
        for (viewId in URL_BAR_IDS) {
            val nodes = root.findAccessibilityNodeInfosByViewId(viewId)
            if (nodes.isNullOrEmpty()) continue
            for (node in nodes) {
                val text = node.text?.toString()
                node.recycle()
                if (!text.isNullOrBlank()) {
                    return normalizeUrl(text)
                }
            }
        }

        // Fallback: scan for a node whose text looks like a YouTube Shorts URL.
        return findUrlRecursive(root, 0)
    }

    private fun findUrlRecursive(node: AccessibilityNodeInfo, depth: Int): String? {
        if (depth > 12) return null
        val text = node.text?.toString()
        if (!text.isNullOrBlank() && text.contains("shorts", ignoreCase = true) &&
            (text.contains("youtube", ignoreCase = true) || text.contains("youtu.be", ignoreCase = true))
        ) {
            return normalizeUrl(text)
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try {
                val found = findUrlRecursive(child, depth + 1)
                if (found != null) return found
            } finally {
                child.recycle()
            }
        }
        return null
    }

    companion object {
        private const val TAG = "ShortsA11y"
        private const val DEBOUNCE_MS = 2500L

        private val WATCHED_PACKAGES = setOf(
            "com.android.chrome",
            "com.chrome.beta",
            "com.chrome.dev",
            "com.chrome.canary",
            "org.mozilla.firefox",
            "org.mozilla.firefox_beta",
            "com.microsoft.emmx",
            "com.brave.browser",
            "com.opera.browser",
            "com.sec.android.app.sbrowser",
            "com.android.browser",
        )

        private val URL_BAR_IDS = listOf(
            "com.android.chrome:id/url_bar",
            "com.chrome.beta:id/url_bar",
            "org.mozilla.firefox:id/url_bar_title",
            "org.mozilla.firefox:id/mozac_browser_toolbar_url_view",
            "com.sec.android.app.sbrowser:id/location_bar_edit_text",
            "com.microsoft.emmx:id/url_bar",
            "com.brave.browser:id/url_bar",
            "com.opera.browser:id/url_field",
        )

        private val SHORTS_REGEX =
            Regex("""(?:youtube\.com|youtu\.be)/shorts/([\w-]{11})""", RegexOption.IGNORE_CASE)

        fun extractShortsId(raw: String): String? {
            val normalized = normalizeUrl(raw)
            return SHORTS_REGEX.find(normalized)?.groupValues?.getOrNull(1)
        }

        fun normalizeUrl(raw: String): String {
            val trimmed = raw.trim()
            return when {
                trimmed.startsWith("http://") || trimmed.startsWith("https://") -> trimmed
                trimmed.startsWith("www.") || trimmed.contains("youtube") || trimmed.contains("youtu.be") ->
                    "https://$trimmed"
                else -> trimmed
            }
        }
    }
}
