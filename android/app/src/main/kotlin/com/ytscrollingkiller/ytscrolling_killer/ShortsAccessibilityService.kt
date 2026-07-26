package com.ytscrollingkiller.ytscrolling_killer

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.graphics.Path
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.animation.DecelerateInterpolator
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout

/**
 * Lets the user watch one YouTube Short in the browser. When the Shorts id
 * changes (swipe / related / autoplay), pauses playback, shows a blocking
 * overlay, and offers only "Close tab".
 */
class ShortsAccessibilityService : AccessibilityService() {

    private enum class Mode { Idle, Watching, Blocked }

    private var mode: Mode = Mode.Idle
    private var activeShortId: String? = null
    private var browserPackage: String? = null

    private var overlayView: FrameLayout? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    /** Saved STREAM_MUSIC volume while muted as a pause fallback; null if not muted. */
    private var mutedVolumeToRestore: Int? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val silenceRetryRunnables = mutableListOf<Runnable>()

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
        cancelSilenceRetries()
        dismissOverlay()
        restoreStreamVolume()
        abandonAudioFocus()
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
        mainHandler.post {
            pauseActiveShortThenShowOverlay()
        }
    }

    /**
     * Full pause cascade under the browser, then overlay.
     * Order matters: center-tap gestures must not hit the overlay.
     */
    private fun pauseActiveShortThenShowOverlay() {
        tryClickPauseControl()
        requestAudioFocusBackup()
        dispatchPauseTapsThenFinish(0) {
            muteStreamAsFallback()
            showOverlay()
            if (overlayView != null) {
                scheduleSilenceRetries()
            }
        }
    }

    private fun tryClickPauseControl(): Boolean {
        val root = rootInActiveWindow ?: return false
        try {
            if (clickByContentDescriptions(root, PAUSE_DESCRIPTIONS)) return true
            if (clickByText(root, PAUSE_TEXTS)) return true
        } finally {
            root.recycle()
        }
        return false
    }

    /** Sequential center taps at several Y positions; always invokes [onDone] once. */
    private fun dispatchPauseTapsThenFinish(index: Int, onDone: () -> Unit) {
        if (index >= PAUSE_TAP_Y_FRACTIONS.size) {
            mainHandler.postDelayed(onDone, PAUSE_SETTLE_MS)
            return
        }

        val fraction = PAUSE_TAP_Y_FRACTIONS[index]
        val dispatched = dispatchTapAtFraction(fraction) {
            dispatchPauseTapsThenFinish(index + 1, onDone)
        }
        if (!dispatched) {
            dispatchPauseTapsThenFinish(index + 1, onDone)
        }
    }

    private fun dispatchTapAtFraction(yFraction: Float, onDone: () -> Unit): Boolean {
        val dm = resources.displayMetrics
        val x = dm.widthPixels / 2f
        val y = dm.heightPixels * yFraction

        val path = Path().apply { moveTo(x, y) }
        val stroke = GestureDescription.StrokeDescription(path, 0, 60)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        return try {
            dispatchGesture(
                gesture,
                object : GestureResultCallback() {
                    override fun onCompleted(gestureDescription: GestureDescription?) {
                        mainHandler.postDelayed(onDone, PAUSE_SETTLE_MS)
                    }

                    override fun onCancelled(gestureDescription: GestureDescription?) {
                        Log.w(TAG, "Pause tap cancelled at y=$yFraction")
                        mainHandler.post(onDone)
                    }
                },
                null,
            )
        } catch (e: Exception) {
            Log.e(TAG, "Pause tap failed at y=$yFraction", e)
            false
        }
    }

    private fun requestAudioFocusBackup() {
        val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Abandon previous request before re-requesting (retries).
                audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
                val attrs = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
                    .build()
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(attrs)
                    .setOnAudioFocusChangeListener { }
                    .build()
                audioFocusRequest = request
                am.requestAudioFocus(request)
            } else {
                @Suppress("DEPRECATION")
                am.requestAudioFocus(
                    null,
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN,
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "Audio focus request failed", e)
        }
    }

    private fun abandonAudioFocus() {
        val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { am.abandonAudioFocusRequest(it) }
            } else {
                @Suppress("DEPRECATION")
                am.abandonAudioFocus(null)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Abandon audio focus failed", e)
        } finally {
            audioFocusRequest = null
        }
    }

    private fun muteStreamAsFallback() {
        val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        try {
            if (mutedVolumeToRestore == null) {
                mutedVolumeToRestore = am.getStreamVolume(AudioManager.STREAM_MUSIC)
            }
            am.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0)
        } catch (e: Exception) {
            Log.w(TAG, "Mute stream failed", e)
        }
    }

    private fun restoreStreamVolume() {
        val saved = mutedVolumeToRestore ?: return
        mutedVolumeToRestore = null
        val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
        try {
            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            am.setStreamVolume(AudioManager.STREAM_MUSIC, saved.coerceIn(0, max), 0)
        } catch (e: Exception) {
            Log.w(TAG, "Restore stream volume failed", e)
        }
    }

    /** Non-touch retries after overlay (gestures would hit the overlay). */
    private fun scheduleSilenceRetries() {
        cancelSilenceRetries()
        for (delayMs in SILENCE_RETRY_DELAYS_MS) {
            val runnable = Runnable {
                if (mode != Mode.Blocked || overlayView == null) return@Runnable
                requestAudioFocusBackup()
                muteStreamAsFallback()
            }
            silenceRetryRunnables.add(runnable)
            mainHandler.postDelayed(runnable, delayMs)
        }
    }

    private fun cancelSilenceRetries() {
        for (runnable in silenceRetryRunnables) {
            mainHandler.removeCallbacks(runnable)
        }
        silenceRetryRunnables.clear()
    }

    private fun showOverlay() {
        if (overlayView != null) return

        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        val view = LayoutInflater.from(this)
            .inflate(R.layout.scroll_block_overlay, null) as FrameLayout

        view.findViewById<Button>(R.id.scroll_block_close_button).setOnClickListener {
            onCloseTabClicked()
        }

        val panel = view.findViewById<LinearLayout>(R.id.scroll_block_panel)
        view.alpha = 0f
        panel.translationY = 28f * resources.displayMetrics.density
        panel.alpha = 0f

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
            animateOverlayIn(view, panel)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show overlay", e)
            cancelSilenceRetries()
            restoreStreamVolume()
            abandonAudioFocus()
            mode = Mode.Idle
            activeShortId = null
            browserPackage = null
        }
    }

    private fun animateOverlayIn(root: View, panel: View) {
        root.animate()
            .alpha(1f)
            .setDuration(OVERLAY_ANIM_MS)
            .setInterpolator(DecelerateInterpolator())
            .start()
        panel.animate()
            .alpha(1f)
            .translationY(0f)
            .setDuration(OVERLAY_ANIM_MS)
            .setInterpolator(DecelerateInterpolator())
            .start()
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
        cancelSilenceRetries()
        dismissOverlay()
        restoreStreamVolume()
        abandonAudioFocus()
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
        private const val PAUSE_SETTLE_MS = 220L
        private const val OVERLAY_ANIM_MS = 220L

        /** Center-X tap Y fractions (player area; avoid right-side action rail). */
        private val PAUSE_TAP_Y_FRACTIONS = floatArrayOf(0.38f, 0.45f, 0.52f)

        /** Post-overlay non-touch silence retries (audio focus + mute). */
        private val SILENCE_RETRY_DELAYS_MS = longArrayOf(400L, 1000L)

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

        private val PAUSE_DESCRIPTIONS = listOf(
            "Pause",
            "Pausa",
            "Pause video",
            "Pause short",
        )

        private val PAUSE_TEXTS = listOf(
            "Pause",
            "Pausa",
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
