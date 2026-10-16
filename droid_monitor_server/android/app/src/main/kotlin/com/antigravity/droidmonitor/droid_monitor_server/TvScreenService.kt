package com.antigravity.droidmonitor.droid_monitor_server

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.os.Build
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class TvScreenService : AccessibilityService() {

    companion object {
        var instance: TvScreenService? = null
            private set

        val isRunning: Boolean
            get() = instance != null

        private val executor = Executors.newSingleThreadExecutor()

        fun captureScreen(callback: (ByteArray?) -> Unit): Boolean {
            val service = instance ?: return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    service.takeScreenshot(Display.DEFAULT_DISPLAY, executor, object : TakeScreenshotCallback {
                        override fun onSuccess(result: ScreenshotResult) {
                            try {
                                val bitmap = Bitmap.wrapHardwareBuffer(result.hardwareBuffer, result.colorSpace)
                                val copy = bitmap?.copy(Bitmap.Config.ARGB_8888, false)
                                result.hardwareBuffer.close()
                                if (copy != null) {
                                    val out = ByteArrayOutputStream()
                                    copy.compress(Bitmap.CompressFormat.JPEG, 75, out)
                                    copy.recycle()
                                    callback(out.toByteArray())
                                    return
                                }
                            } catch (_: Exception) {}
                            callback(null)
                        }

                        override fun onFailure(errorCode: Int) {
                            callback(null)
                        }
                    })
                    return true
                } catch (_: Exception) {
                    return false
                }
            }
            return false
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) instance = null
    }
}
