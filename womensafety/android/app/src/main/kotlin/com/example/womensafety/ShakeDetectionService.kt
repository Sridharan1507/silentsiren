package com.example.womensafety

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.telephony.SmsManager
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import kotlin.math.sqrt

class ShakeDetectionService : Service() {

    private lateinit var sensorManager: android.hardware.SensorManager
    private var accelCurrent = 0f
    private var accelLast = 0f
    private var shake = 0f

    private lateinit var fusedLocationClient: FusedLocationProviderClient

    // Flutter communication
    private lateinit var flutterEngine: FlutterEngine
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private val SHAKE_THRESHOLD = 22f

    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()

        val notification: Notification = NotificationCompat.Builder(this, "emergency_channel")
            .setContentTitle("Shake Detection Active")
            .setContentText("Monitoring for emergency shakes")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()

        startForeground(1, notification)

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        // Initialize Flutter engine for EventChannel
        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "shake_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Register accelerometer listener
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as android.hardware.SensorManager
        sensorManager.registerListener(
            sensorListener,
            sensorManager.getDefaultSensor(android.hardware.Sensor.TYPE_ACCELEROMETER),
            android.hardware.SensorManager.SENSOR_DELAY_NORMAL
        )
    }

    private val sensorListener = object : android.hardware.SensorEventListener {
        override fun onSensorChanged(event: android.hardware.SensorEvent) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]

            accelLast = accelCurrent
            accelCurrent = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
            val delta = accelCurrent - accelLast
            shake = shake * 0.9f + delta

            if (shake > SHAKE_THRESHOLD) {
                onShakeDetected()
            }
        }

        override fun onAccuracyChanged(sensor: android.hardware.Sensor?, accuracy: Int) {}
    }

    private fun onShakeDetected() {
        // Fetch location
        fusedLocationClient.lastLocation.addOnSuccessListener { location ->
            val lat = location?.latitude
            val lng = location?.longitude
            val locationUrl = if (lat != null && lng != null)
                "https://maps.google.com/?q=$lat,$lng" else "Location unavailable"

            val message = "EMERGENCY ALERT! Shake detected!\nTime: ${System.currentTimeMillis()}\nLocation: $locationUrl"

            // Send SMS to a predefined number
            try {
                val smsManager = SmsManager.getDefault()
                // Replace with your contacts or loop through multiple
                smsManager.sendTextMessage("+919597292187", null, message, null, null)
            } catch (e: Exception) {
                e.printStackTrace()
            }

            // Trigger Flutter event if app is alive
            eventSink?.success("SHAKE_DETECTED")

            // Show local notification
            showNotification("Emergency Alert", "Shake detected! SMS sent.")
        }.addOnFailureListener {
            // Even if location fails, send SMS with unknown location
            val message = "EMERGENCY ALERT! Shake detected!\nTime: ${System.currentTimeMillis()}\nLocation: unavailable"
            try {
                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage("+919597292187", null, message, null, null)
            } catch (e: Exception) { e.printStackTrace() }

            eventSink?.success("SHAKE_DETECTED")
            showNotification("Emergency Alert", "Shake detected! SMS sent.")
        }
    }

    private fun showNotification(title: String, content: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(this, "emergency_channel")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)

        manager.notify(System.currentTimeMillis().toInt(), builder.build())
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        sensorManager.unregisterListener(sensorListener)
        flutterEngine.destroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "emergency_channel",
                "Emergency Alerts",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.enableVibration(true)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
