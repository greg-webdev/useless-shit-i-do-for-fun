package com.antigravity.tvcapture.android_tv_cam_control

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Display
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class TvRemoteAccessibilityService : AccessibilityService() {

    companion object {
        var instance: TvRemoteAccessibilityService? = null
            private set

        val isRunning: Boolean
            get() = instance != null

        fun performHome(): Boolean {
            return instance?.performGlobalAction(GLOBAL_ACTION_HOME) ?: false
        }

        fun performBack(): Boolean {
            return instance?.performGlobalAction(GLOBAL_ACTION_BACK) ?: false
        }

        fun performRecents(): Boolean {
            return instance?.performGlobalAction(GLOBAL_ACTION_RECENTS) ?: false
        }

        fun performNotifications(): Boolean {
            return instance?.performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS) ?: false
        }

        fun performQuickSettings(): Boolean {
            return instance?.performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS) ?: false
        }

        fun performPowerDialog(): Boolean {
            return instance?.performGlobalAction(GLOBAL_ACTION_POWER_DIALOG) ?: false
        }

        fun tapAt(x: Float, y: Float): Boolean {
            val service = instance ?: return false
            service.showCursor(x.toInt(), y.toInt())

            // 1. Click Accessibility Node under (x, y) if one exists (Android TV Leanback cards, buttons)
            val nodeClicked = service.clickNodeAt(x.toInt(), y.toInt())
            if (nodeClicked) {
                return true
            }

            // 2. Only dispatch gesture stroke if no accessibility node handled the click
            val path = Path().apply {
                moveTo(x, y)
                lineTo(x + 1f, y + 1f)
            }
            val stroke = GestureDescription.StrokeDescription(path, 0, 100)
            val gesture = GestureDescription.Builder().addStroke(stroke).build()
            return service.dispatchGesture(gesture, null, null)
        }

        fun moveCursor(x: Float, y: Float) {
            instance?.showCursor(x.toInt(), y.toInt())
        }

        fun swipe(startX: Float, startY: Float, endX: Float, endY: Float, durationMs: Long = 200): Boolean {
            val service = instance ?: return false
            val path = Path().apply {
                moveTo(startX, startY)
                lineTo(endX, endY)
            }
            val stroke = GestureDescription.StrokeDescription(path, 0, durationMs)
            val gesture = GestureDescription.Builder().addStroke(stroke).build()
            return service.dispatchGesture(gesture, null, null)
        }

        private val screenshotExecutor = Executors.newSingleThreadExecutor()
        @Volatile private var lastScreenshotBytes: ByteArray? = null
        @Volatile private var lastScreenshotTime: Long = 0L
        @Volatile private var isCapturing: Boolean = false

        fun captureTvScreen(onComplete: (ByteArray?) -> Unit) {
            val service = instance
            if (service == null) {
                onComplete(lastScreenshotBytes)
                return
            }

            val now = System.currentTimeMillis()
            // Android enforces a rate limit on takeScreenshot (~200-300ms).
            // If called within 250ms or if currently capturing, return cached latest frame immediately
            if (lastScreenshotBytes != null && (now - lastScreenshotTime < 250 || isCapturing)) {
                onComplete(lastScreenshotBytes)
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                isCapturing = true
                try {
                    service.takeScreenshot(Display.DEFAULT_DISPLAY, screenshotExecutor, object : AccessibilityService.TakeScreenshotCallback {
                        override fun onSuccess(result: AccessibilityService.ScreenshotResult) {
                            isCapturing = false
                            try {
                                val bitmap = Bitmap.wrapHardwareBuffer(result.hardwareBuffer, result.colorSpace)
                                val copy = bitmap?.copy(Bitmap.Config.ARGB_8888, false)
                                result.hardwareBuffer.close()
                                if (copy != null) {
                                    val out = ByteArrayOutputStream()
                                    copy.compress(Bitmap.CompressFormat.JPEG, 60, out)
                                    copy.recycle()
                                    val bytes = out.toByteArray()
                                    lastScreenshotBytes = bytes
                                    lastScreenshotTime = System.currentTimeMillis()
                                    onComplete(bytes)
                                    return
                                }
                            } catch (e: Exception) {
                                android.util.Log.e("TvRemoteAccessibility", "Screenshot processing error: ${e.message}")
                            }
                            onComplete(lastScreenshotBytes)
                        }

                        override fun onFailure(errorCode: Int) {
                            isCapturing = false
                            android.util.Log.w("TvRemoteAccessibility", "takeScreenshot onFailure errorCode: $errorCode")
                            onComplete(lastScreenshotBytes)
                        }
                    })
                } catch (e: Exception) {
                    isCapturing = false
                    android.util.Log.e("TvRemoteAccessibility", "takeScreenshot exception: ${e.message}")
                    onComplete(lastScreenshotBytes)
                }
            } else {
                onComplete(lastScreenshotBytes)
            }
        }
    }

    private var cursorView: View? = null
    private var windowManager: WindowManager? = null
    private var cursorParams: WindowManager.LayoutParams? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val hideCursorRunnable = Runnable {
        cursorView?.visibility = View.GONE
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        initOverlayCursor()
        TvRemoteBackgroundService.start(this)
    }

    private fun initOverlayCursor() {
        mainHandler.post {
            try {
                windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val size = 28 // 28px glowing cursor

                val drawable = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.parseColor("#00F2FE"))
                    setStroke(3, Color.WHITE)
                }

                cursorView = View(this).apply {
                    background = drawable
                    elevation = 20f
                    visibility = View.GONE
                }

                cursorParams = WindowManager.LayoutParams(
                    size,
                    size,
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                    x = 960
                    y = 540
                }

                windowManager?.addView(cursorView, cursorParams)
            } catch (e: Exception) {
                android.util.Log.e("TvRemoteAccessibility", "Failed to add overlay cursor: ${e.message}")
            }
        }
    }

    fun showCursor(x: Int, y: Int) {
        mainHandler.post {
            try {
                cursorParams?.let { params ->
                    params.x = x - 14
                    params.y = y - 14
                    cursorView?.let { view ->
                        view.visibility = View.VISIBLE
                        windowManager?.updateViewLayout(view, params)
                    }
                }
                mainHandler.removeCallbacks(hideCursorRunnable)
                mainHandler.postDelayed(hideCursorRunnable, 4000)
            } catch (e: Exception) {}
        }
    }

    fun clickNodeAt(x: Int, y: Int): Boolean {
        val root = rootInActiveWindow ?: return false
        return try {
            val target = findDeepestClickableNode(root, x, y)
            if (target != null) {
                target.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
                val clicked = target.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                android.util.Log.d("TvRemoteAccessibility", "clickNodeAt ($x, $y) on '${target.className}' success: $clicked")
                target.recycle()
                clicked
            } else {
                false
            }
        } catch (e: Exception) {
            android.util.Log.e("TvRemoteAccessibility", "clickNodeAt error: ${e.message}")
            false
        }
    }

    private fun findDeepestClickableNode(node: AccessibilityNodeInfo, x: Int, y: Int): AccessibilityNodeInfo? {
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        if (!bounds.contains(x, y)) {
            return null
        }

        // Search children from top to bottom of z-order (reverse child order)
        for (i in (node.childCount - 1) downTo 0) {
            val child = node.getChild(i) ?: continue
            val found = findDeepestClickableNode(child, x, y)
            if (found != null) {
                return found
            }
            child.recycle()
        }

        if (node.isClickable || node.isCheckable) {
            return AccessibilityNodeInfo.obtain(node)
        }

        return null
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}

    override fun onDestroy() {
        if (instance == this) {
            instance = null
        }
        mainHandler.removeCallbacksAndMessages(null)
        cursorView?.let {
            try { windowManager?.removeView(it) } catch (e: Exception) {}
        }
        super.onDestroy()
    }
}
