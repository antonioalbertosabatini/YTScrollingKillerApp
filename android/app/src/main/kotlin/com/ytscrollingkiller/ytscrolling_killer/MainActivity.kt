package com.ytscrollingkiller.ytscrolling_killer

import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isShortsGuardEnabled())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isShortsGuardEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        if (TextUtils.isEmpty(enabled)) return false

        val expected = "$packageName/${ShortsAccessibilityService::class.java.canonicalName}"
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabled)
        while (splitter.hasNext()) {
            if (splitter.next().equals(expected, ignoreCase = true)) return true
        }
        return false
    }

    companion object {
        private const val CHANNEL =
            "com.ytscrollingkiller.ytscrolling_killer/accessibility"
    }
}
