package com.antigravity.tvcapture.android_tv_cam_control

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder

class TvRemoteBackgroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "tv_remote_bg_channel"
        private const val NOTIF_ID = 1001

        fun start(context: Context) {
            try {
                val intent = Intent(context, TvRemoteBackgroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                android.util.Log.w("TvRemoteBgService", "start error: ${e.message}")
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("TV Remote & Screen Mirror Active")
                .setContentText("Serving on Port 8080 (HTTP) & 9293 (HTTPS)")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("TV Remote & Screen Mirror Active")
                .setContentText("Serving on Port 8080 (HTTP) & 9293 (HTTPS)")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build()
        }
        startForeground(NOTIF_ID, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "TV Remote Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps TV Remote & Screen Mirroring server running in background"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}
