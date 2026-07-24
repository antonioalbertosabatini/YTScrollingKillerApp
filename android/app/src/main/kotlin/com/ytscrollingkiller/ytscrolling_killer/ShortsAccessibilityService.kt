package com.ytscrollingkiller.ytscrolling_killer

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.FrameLayout

/**
 * Lets the user watch one YouTube Short in the browser. When the Shorts id
 * changes (swipe / related / autoplay), shows a blocking overlay and offers
 * only "Close tab".
 */
class ShortsAccessibilityService : AccessibilityService() {

    private enum class Mode { Idle, Watching, Blocked }

    private var mode: Mode = Mode.Idle
    private var activeShortId: String? = null
    private var browserPackage: String? = null

    private var overlayView: FrameLayout? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        serviceInfo = serviceInfo?.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_SCROLLED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = flags or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (mode == Mode.Blocked) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg !in WATCHED_PACKAGES) return

        val root = rootInActiveWindow ?: return
        try {
            val url = findUrl(root)
            handleUrl(pkg, url)
        } finally {
            root.recycle()
        }
    }

    override fun onInterrupt() {
        // No-op
    }

    override fun onDestroy() {
        dismissOverlay()
        super.onDestroy()
    }

    private fun handleUrl(pkg: String, url: String?) {
        val shortId = url?.let { extractShortsId(it) }

        when (mode) {
            Mode.Idle -> {
                if (shortId != null) {
                    activeShortId = shortId
                    browserPackage = pkg
                    mode = Mode.Watching
                    Log.d(TAG, "Watching short $shortId")
                }
            }

            Mode.Watching -> {
                if (shortId == null) {
                    Log.d(TAG, "Left Shorts")
                    activeShortId = null
                    browserPackage = null
                    mode = Mode.Idle
                    return
                }
                val current = activeShortId
                if (current != null && shortId != current) {
                    Log.d(TAG, "Short changed $current -> $shortId; blocking")
                    browserPackage = pkg
                    enterBlocked()
                }
            }

            Mode.Blocked -> Unit
        }
    }

    private fun enterBlocked() {
        if (mode == Mode.Blocked) return
        mode = Mode.Blocked
        mainHandler.post { showOverlay() }
    }

    private fun showOverlay() {
        if (overlayView != null) return

        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        val view = LayoutInflater.from(this)
            .inflate(R.layout.scroll_block_overlay, null) as FrameLayout

        view.findViewById<Button>(R.id.scroll_block_close_button).setOnClickListener {
            onCloseTabClicked()
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        // Must be focusable for the button; clear NOT_FOCUSABLE after create.
        params.flags = WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS

        try {
            wm.addView(view, params)
            overlayView = view
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show overlay", e)
            mode = Mode.Idle
            activeShortId = null
        }
    }

    private fun dismissOverlay() {
        val view = overlayView ?: return
        overlayView = null
        try {
            val wm = getSystemService(WINDOW_SERVICE) as WindowManager
            wm.removeView(view)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to remove overlay", e)
        }
    }

    private fun onCloseTabClicked() {
        dismissOverlay()
        // Let the browser regain the active window after overlay removal.
        mainHandler.postDelayed({
            val closed = tryCloseCurrentTab()
            if (!closed) {
                navigateBrowserToYoutubeHome()
            }
            activeShortId = null
            browserPackage = null
            mode = Mode.Idle
        }, 250L)
    }

    private fun tryCloseCurrentTab(): Boolean {
        val root = rootInActiveWindow ?: return false
        try {
            // Common close-tab / close-button labels and view ids.
            if (clickByViewIds(root, CLOSE_TAB_VIEW_IDS)) return true
            if (clickByContentDescriptions(root, CLOSE_TAB_DESCRIPTIONS)) return true
            if (clickByText(root, CLOSE_TAB_TEXTS)) return true
        } finally {
            root.recycle()
        }
        return false
    }

    private fun navigateBrowserToYoutubeHome(): Boolean {
        val root = rootInActiveWindow ?: return false
        try {
            val urlBar = findUrlBarNode(root) ?: return false
            urlBar.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
            urlBar.performAction(AccessibilityNodeInfo.ACTION_CLICK)

            val args = android.os.Bundle().apply {
                putCharSequence(
                    AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                    YOUTUBE_HOME,
                )
            }
            val set = urlBar.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
            if (!set) {
                urlBar.recycle()
                return false
            }

            // Try IME enter / click go if available.
            val entered = urlBar.performAction(
                AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER.id,
            )
            urlBar.recycle()
            if (entered) return true

            // Fallback: global back is wrong; try finding a "go"/"enter" button.
            val root2 = rootInActiveWindow ?: return false
            try {
                return clickByContentDescriptions(root2, listOf("Go", "Enter", "Navigate"))
            } finally {
                root2.recycle()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Navigate home failed", e)
            return false
        } finally {
            root.recycle()
        }
    }

    private fun findUrlBarNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        for (viewId in URL_BAR_IDS) {
            val nodes = root.findAccessibilityNodeInfosByViewId(viewId)
            if (nodes.isNullOrEmpty()) continue
            val node = nodes.firstOrNull() ?: continue
            // Recycle extras
            for (i in 1 until nodes.size) nodes[i].recycle()
            return node
        }
        return null
    }

    private fun clickByViewIds(root: AccessibilityNodeInfo, ids: List<String>): Boolean {
        for (id in ids) {
            val nodes = root.findAccessibilityNodeInfosByViewId(id) ?: continue
            for (node in nodes) {
                val clicked = performClick(node)
                node.recycle()
                if (clicked) return true
            }
        }
        return false
    }

    private fun clickByContentDescriptions(
        root: AccessibilityNodeInfo,
        descriptions: List<String>,
    ): Boolean {
        return clickMatching(root, 0) { node ->
            val desc = node.contentDescription?.toString()?.lowercase() ?: return@clickMatching false
            descriptions.any { desc.contains(it.lowercase()) }
        }
    }

    private fun clickByText(root: AccessibilityNodeInfo, texts: List<String>): Boolean {
        for (text in texts) {
            val nodes = root.findAccessibilityNodeInfosByText(text) ?: continue
            for (node in nodes) {
                val clicked = performClick(node)
                node.recycle()
                if (clicked) return true
            }
        }
        return false
    }

    private fun clickMatching(
        node: AccessibilityNodeInfo,
        depth: Int,
        predicate: (AccessibilityNodeInfo) -> Boolean,
    ): Boolean {
        if (depth > 18) return false
        if (predicate(node) && performClick(node)) return true
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try {
                if (clickMatching(child, depth + 1, predicate)) return true
            } finally {
                child.recycle()
            }
        }
        return false
    }

    private fun performClick(node: AccessibilityNodeInfo): Boolean {
        var current: AccessibilityNodeInfo? = AccessibilityNodeInfo.obtain(node)
        try {
            while (current != null) {
                if (current.isClickable) {
                    return current.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                }
                val parent = current.parent
                if (current !== node) current.recycle()
                current = parent
            }
        } finally {
            current?.recycle()
        }
        return false
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
        private const val YOUTUBE_HOME = "https://www.youtube.com/"

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

        private val CLOSE_TAB_VIEW_IDS = listOf(
            "com.android.chrome:id/close_button",
            "com.android.chrome:id/close_tab_button",
            "com.chrome.beta:id/close_button",
            "org.mozilla.firefox:id/mozac_browser_tabstray_close",
            "org.mozilla.firefox:id/close_tab_button",
        )

        private val CLOSE_TAB_DESCRIPTIONS = listOf(
            "Close tab",
            "Close",
            "Chiudi scheda",
            "Chiudi",
        )

        private val CLOSE_TAB_TEXTS = listOf(
            "Close tab",
            "Close",
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
                trimmed.startsWith("www.") ||
                    trimmed.contains("youtube") ||
                    trimmed.contains("youtu.be") -> "https://$trimmed"
                else -> trimmed
            }
        }
    }
}
