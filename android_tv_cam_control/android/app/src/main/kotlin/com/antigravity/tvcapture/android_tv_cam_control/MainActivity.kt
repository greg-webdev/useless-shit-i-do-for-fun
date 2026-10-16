package com.antigravity.tvcapture.android_tv_cam_control

import android.content.Context
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.media.AudioManager
import android.os.Bundle
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.net.Socket
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val VIDEO_CHANNEL = "com.antigravity.tvcapture/video_stream"
    private val SYSTEM_CHANNEL = "com.antigravity.tvcapture/system_control"
    private val executor = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        TvRemoteBackgroundService.start(this)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onBackPressed() {
        moveTaskToBack(true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Hardware Video Stream Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VIDEO_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "convertYuvToJpeg") {
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0
                val quality = call.argument<Int>("quality") ?: 65
                val yBytes = call.argument<ByteArray>("y")
                val uBytes = call.argument<ByteArray>("u")
                val vBytes = call.argument<ByteArray>("v")
                val yRowStride = call.argument<Int>("yRowStride") ?: width
                val uvRowStride = call.argument<Int>("uvRowStride") ?: width
                val uvPixelStride = call.argument<Int>("uvPixelStride") ?: 1

                if (yBytes == null || uBytes == null || vBytes == null || width <= 0 || height <= 0) {
                    result.error("INVALID_ARGS", "Missing plane data or invalid dimensions", null)
                    return@setMethodCallHandler
                }

                executor.execute {
                    try {
                        val nv21 = yuv420ToNv21(width, height, yBytes, uBytes, vBytes, yRowStride, uvRowStride, uvPixelStride)
                        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
                        val out = ByteArrayOutputStream()
                        yuvImage.compressToJpeg(Rect(0, 0, width, height), quality, out)
                        val jpeg = out.toByteArray()
                        runOnUiThread {
                            result.success(jpeg)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("CONVERSION_ERROR", e.message, null)
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }

        // 2. System-Wide TV Control Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityActive" -> {
                    result.success(TvRemoteAccessibilityService.isRunning)
                }
                "globalAction" -> {
                    val action = call.argument<String>("action") ?: ""
                    val success = when (action) {
                        "HOME" -> {
                            val done = TvRemoteAccessibilityService.performHome()
                            if (!done) sendAdbShellCmd("input keyevent 3")
                            true
                        }
                        "BACK" -> {
                            val done = TvRemoteAccessibilityService.performBack()
                            if (!done) sendAdbShellCmd("input keyevent 4")
                            true
                        }
                        "RECENTS" -> {
                            val done = TvRemoteAccessibilityService.performRecents()
                            if (!done) sendAdbShellCmd("input keyevent 187")
                            true
                        }
                        "NOTIFICATIONS" -> TvRemoteAccessibilityService.performNotifications()
                        "QUICK_SETTINGS" -> TvRemoteAccessibilityService.performQuickSettings()
                        "POWER" -> {
                            val done = TvRemoteAccessibilityService.performPowerDialog()
                            if (!done) sendAdbShellCmd("input keyevent 26")
                            true
                        }
                        else -> false
                    }
                    result.success(success)
                }
                "keyevent" -> {
                    val keyCode = call.argument<Int>("keyCode") ?: 0
                    executor.execute {
                        // Handle volume keys directly via AudioManager for zero latency
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                        when (keyCode) {
                            KeyEvent.KEYCODE_VOLUME_UP -> {
                                audioManager?.adjustSuggestedStreamVolume(
                                    AudioManager.ADJUST_RAISE,
                                    AudioManager.USE_DEFAULT_STREAM_TYPE,
                                    AudioManager.FLAG_SHOW_UI
                                )
                            }
                            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                                audioManager?.adjustSuggestedStreamVolume(
                                    AudioManager.ADJUST_LOWER,
                                    AudioManager.USE_DEFAULT_STREAM_TYPE,
                                    AudioManager.FLAG_SHOW_UI
                                )
                            }
                            KeyEvent.KEYCODE_VOLUME_MUTE -> {
                                audioManager?.adjustSuggestedStreamVolume(
                                    AudioManager.ADJUST_TOGGLE_MUTE,
                                    AudioManager.USE_DEFAULT_STREAM_TYPE,
                                    AudioManager.FLAG_SHOW_UI
                                )
                            }
                            else -> {
                                // Send keyevent system-wide via ADB shell
                                sendAdbShellCmd("input keyevent $keyCode")
                            }
                        }
                    }
                    result.success(true)
                }
                "tap" -> {
                    val x = (call.argument<Double>("x") ?: 0.0).toFloat()
                    val y = (call.argument<Double>("y") ?: 0.0).toFloat()
                    val handled = TvRemoteAccessibilityService.tapAt(x, y)
                    if (!handled) {
                        executor.execute {
                            sendAdbShellCmd("input tap ${x.toInt()} ${y.toInt()}")
                        }
                    }
                    result.success(true)
                }
                "moveCursor" -> {
                    val x = (call.argument<Double>("x") ?: 0.0).toFloat()
                    val y = (call.argument<Double>("y") ?: 0.0).toFloat()
                    TvRemoteAccessibilityService.moveCursor(x, y)
                    result.success(true)
                }
                "swipe" -> {
                    val startX = (call.argument<Double>("startX") ?: 0.0).toFloat()
                    val startY = (call.argument<Double>("startY") ?: 0.0).toFloat()
                    val endX = (call.argument<Double>("endX") ?: 0.0).toFloat()
                    val endY = (call.argument<Double>("endY") ?: 0.0).toFloat()
                    val duration = (call.argument<Int>("duration") ?: 200).toLong()
                    val handled = TvRemoteAccessibilityService.swipe(startX, startY, endX, endY, duration)
                    if (!handled) {
                        executor.execute {
                            sendAdbShellCmd("input swipe ${startX.toInt()} ${startY.toInt()} ${endX.toInt()} ${endY.toInt()} $duration")
                        }
                    }
                    result.success(true)
                }
                "captureTvScreen" -> {
                    TvRemoteAccessibilityService.captureTvScreen { bytes ->
                        runOnUiThread {
                            result.success(bytes)
                        }
                    }
                }
                "inputText" -> {
                    val text = call.argument<String>("text") ?: ""
                    executor.execute {
                        // Escape spaces and special chars for input text
                        val escaped = text.replace(" ", "%s").replace("'", "\\'")
                        sendAdbShellCmd("input text '$escaped'")
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun captureScreenViaExec(): ByteArray? {
        return try {
            val proc = Runtime.getRuntime().exec("screencap -p")
            val bytes = proc.inputStream.readBytes()
            proc.waitFor()
            if (bytes.isNotEmpty()) bytes else null
        } catch (e: Exception) {
            null
        }
    }

    private fun sendAdbShellCmd(cmd: String) {
        try {
            // First try ProcessBuilder (fastest if shell permission exists)
            val proc = Runtime.getRuntime().exec(arrayOf("sh", "-c", cmd))
            proc.waitFor()
            if (proc.exitValue() == 0) return
        } catch (e: Exception) {}

        // Fallback: Connect to local ADB daemon on port 5555
        try {
            Socket("127.0.0.1", 5555).use { socket ->
                socket.soTimeout = 1000
                val out = socket.getOutputStream()
                val inp = socket.getInputStream()

                // ADB CNXN packet
                sendAdbPacket(out, 0x4e584e43, 0x01000000, 4096, "host::\u0000".toByteArray())
                readAdbPacket(inp)

                // ADB OPEN packet for shell
                val payload = "shell:$cmd\u0000".toByteArray()
                sendAdbPacket(out, 0x4e45504f, 1, 0, payload)
            }
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Local ADB execution error: ${e.message}")
        }
    }

    private fun sendAdbPacket(out: OutputStream, command: Int, arg0: Int, arg1: Int, data: ByteArray) {
        val header = ByteBuffer.allocate(24).order(ByteOrder.LITTLE_ENDIAN)
        header.putInt(command)
        header.putInt(arg0)
        header.putInt(arg1)
        header.putInt(data.size)
        var checksum = 0
        for (b in data) checksum += (b.toInt() and 0xFF)
        header.putInt(checksum)
        header.putInt(command xor -0x1)
        out.write(header.array())
        if (data.isNotEmpty()) out.write(data)
        out.flush()
    }

    private fun readAdbPacket(inp: InputStream) {
        val header = ByteArray(24)
        var read = 0
        while (read < 24) {
            val r = inp.read(header, read, 24 - read)
            if (r == -1) break
            read += r
        }
        if (read == 24) {
            val buf = ByteBuffer.wrap(header).order(ByteOrder.LITTLE_ENDIAN)
            buf.getInt() // cmd
            buf.getInt() // arg0
            buf.getInt() // arg1
            val dataLen = buf.getInt()
            if (dataLen > 0) {
                val data = ByteArray(dataLen)
                var dRead = 0
                while (dRead < dataLen) {
                    val r = inp.read(data, dRead, dataLen - dRead)
                    if (r == -1) break
                    dRead += r
                }
            }
        }
    }

    private fun yuv420ToNv21(
        width: Int,
        height: Int,
        yPlane: ByteArray,
        uPlane: ByteArray,
        vPlane: ByteArray,
        yRowStride: Int,
        uvRowStride: Int,
        uvPixelStride: Int
    ): ByteArray {
        val nv21 = ByteArray(width * height * 3 / 2)
        var pos = 0

        for (row in 0 until height) {
            val yOffset = row * yRowStride
            val length = Math.min(width, yPlane.size - yOffset)
            if (length > 0) {
                System.arraycopy(yPlane, yOffset, nv21, pos, length)
            }
            pos += width
        }

        val uvHeight = height / 2
        val uvWidth = width / 2
        for (row in 0 until uvHeight) {
            val uRowOffset = row * uvRowStride
            val vRowOffset = row * uvRowStride
            for (col in 0 until uvWidth) {
                val colOffset = col * uvPixelStride
                val vIdx = vRowOffset + colOffset
                val uIdx = uRowOffset + colOffset
                if (vIdx < vPlane.size && uIdx < uPlane.size && pos + 1 < nv21.size) {
                    nv21[pos++] = vPlane[vIdx]
                    nv21[pos++] = uPlane[uIdx]
                }
            }
        }

        return nv21
    }
}
