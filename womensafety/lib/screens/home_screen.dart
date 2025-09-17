// screens/home_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:womensafety/main.dart';
import 'package:womensafety/providers/alert_provider.dart';
import 'package:womensafety/utils/alert_manager.dart';
import 'package:womensafety/utils/location_service.dart';
import 'package:womensafety/widgets/emergency_button.dart';
import 'package:womensafety/widgets/settings_panel.dart';
import 'package:vosk_flutter_2/vosk_flutter_2.dart';
import 'package:permission_handler/permission_handler.dart';
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _vosk;
  String _recognizedText = "Say the KeyWord....Help";
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  String _status = "Waiting for shake...";
final telephony = Telephony.instance;
  // Threshold values
  static const double shakeThreshold = 17.0; // adjust sensitivity
  static const int shakeCooldownMs = 1000; // min time between shakes
  int _lastShakeTime = 0;
String? _userName;
String errorMessage = "";

@pragma('vm:entry-point')
  void onStart(ServiceInstance service) {
  accelerometerEvents.listen((event) {
    double gX = event.x / 9.81;
    double gY = event.y / 9.81;
    double gZ = event.z / 9.81;

    double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    if (gForce   > shakeThreshold / 9.81) { // threshold for shake
      service.invoke("onShakeDetected", {"event": "Shake Detected"});
      // 🚨 trigger your SilentSiren emergency flow here (SMS, email, etc.)
      final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastShakeTime > shakeCooldownMs) {
          _lastShakeTime = now;
          // triggerSMS();
        }
      
    }
  });
}

  @override
  void dispose() {
    ShakeService.stop();
    super.dispose();
  }

   Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName');
    });
  }
  @override
  void initState() {
    _loadUser();
    ShakeService.start();
    ShakeService.events.listen((event) {
      setState(() {
        _status = event;
        // triggerSMS();
      });
    });
    super.initState();
    _vosk = VoskFlutterPlugin.instance();
    initVosk();
     _accelerometerSubscription = accelerometerEvents.listen((event) {
      double gX = event.x / 9.81;
      double gY = event.y / 9.81;
      double gZ = event.z / 9.81;

      // gForce will be > 2.7 when shaken hard
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > shakeThreshold / 9.81) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastShakeTime > shakeCooldownMs) {
          _lastShakeTime = now;
          _onShakeDetected();
        }
      }
    });
    _initializeBackgroundService();
  }

  void _initializeBackgroundService() {
    final service = FlutterBackgroundService();
    
    service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'shake_emergency_channel',
        initialNotificationTitle: 'Shake Detection Service',
        initialNotificationContent: 'Monitoring for emergency shakes',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        
      ),
    );

    service.startService();
  }

void _onShakeDetected()async {
    setState(() {
      // _status = "🚨 Shake detected!";

      print("shake detected");

    });
     try {
            Position position = await LocationService.getCurrentLocation();

            String message =
                "EMERGENCY ALERT!triggered by Motion,\n $_userName is in trouble\n"
                "Time: ${DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now())}\n";
            String locationUrl =
                "https://maps.google.com/?q=${position.latitude},${position.longitude}";
            String fullMessage = "$message\nLocation: $locationUrl";

            // Request SMS permission
            bool hasPermission = await telephony.isSmsCapable ?? false;
            if (!hasPermission) {
              hasPermission = await telephony.requestSmsPermissions ?? false;
            }

            if (hasPermission) {
              try {
                await telephony.sendSms(to: "+919597292187", message: fullMessage);
                print('SMS sent successfully');
               await NotificationService.showNotification(
        title: 'Hello! 👋',
        body: 'This is a local notification from Flutter!',
      );

              } catch (e) {
                print('Error sending SMS: $e');
              }
            } else {
              print("SMS permission denied");
            }
          } catch (e) {
            print('Error getting location: $e');
          }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Shake Detected!")),
    );
  }
 Future<void> initVosk() async {
  try {
    const int sampleRate = 16000;
    
    // Load model
    final enSmallModelPath = await ModelLoader()
        .loadFromAssets('assets/models/vosk-model-small-en-us-0.15.zip');
    final model = await _vosk.createModel(enSmallModelPath);
    // Create recognizer
    final recognizer = await _vosk.createRecognizer(
      model: model,
      sampleRate: sampleRate,
      grammar: ['i need help'], // Added 'help' to grammar
    );

    // Initialize speech service
    final speechService = await _vosk.initSpeechService(recognizer);
    
    // Listen for partial results
    speechService.onPartial().listen((partial) {
      // print('Partial: $partial');
    });
    final List<String> grammar = ['i need help'];
    // Listen for final results
    speechService.onResult().listen((result) async {
  print('Result: $result');
  
  final String text = _extractTextFromResult(result).toLowerCase();

  for (final keyword in grammar) {
    if (text.contains(keyword.toLowerCase())) {
       Position position = await LocationService.getCurrentLocation();

            String message =
                "EMERGENCY ALERT! triggered by voice,\n $_userName is in trouble\n"
                "Time: ${DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.now())}\n";
            String locationUrl =
                "https://maps.google.com/?q=${position.latitude},${position.longitude}";
            String fullMessage = "$message\nLocation: $locationUrl";
     await SmsHelper.sendAlertToContacts(fullMessage);
   await NotificationService.showNotification(
        title: 'Hello! 👋',
        body: 'This is a local notification from Flutter!',
      );
      // _triggerEmergency(keyword);
      break; // stop at first match
    }
  }
});

    // Start listening
    await speechService.start();
    
    print('Vosk initialized successfully');

  } catch (e) {
    print('Error initializing Vosk: $e');
    setState(() => errorMessage = " $e Voice recognition unavailable");
  }
}

// Helper method to extract text from result (adjust based on your result structure)
String _extractTextFromResult(dynamic result) {
  if (result is String) return result;
  if (result is Map<String, dynamic>) {
    return result['text'] ?? '';
  }
  return result.toString();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            NotificationService.showNotification(
        title: 'Hello! 👋',
        body: 'This is a local notification from Flutter!',
      );
          },
          child: Text('SilentSiren')),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SettingsPanel(),
              );
            },
          ),
        ],
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
          _userName != null ? "Welcome, $_userName 👋" : "Welcome!",
          style: const TextStyle(fontSize: 20),
        ),
              
              // StatusIndicator(isActive: alertProvider.isMonitoring),
              Expanded(
                child: Center(
                  child: EmergencyButton(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'In case of emergency:\n- $_recognizedText\n- Shake phone vigorously\n- Press the button\n$errorMessage',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}




class ShakeService {
  static const MethodChannel _channel = MethodChannel('shake_channel');
  static const EventChannel _eventChannel = EventChannel('shake_events');

  static Future<void> start() async {
    await _channel.invokeMethod('startService');
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stopService');
  }

  static Stream<String> get events =>
      _eventChannel.receiveBroadcastStream().map((event) => event.toString());
}
