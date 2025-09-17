// providers/alert_provider.dart
import 'package:flutter/foundation.dart';
import 'package:womensafety/utils/voice_detector.dart';
import 'package:womensafety/utils/location_service.dart';
import 'package:geolocator/geolocator.dart';

class AlertProvider with ChangeNotifier {
  bool _isMonitoring = false;
  VoiceDetector? _voiceDetector;
  // MotionDetector? _motionDetector;


  bool get isMonitoring => _isMonitoring;

  AlertProvider() {
    _initialize();
  }

  void _initialize() async {
    // Initialize components
  
    
    _voiceDetector = VoiceDetector(onEmergencyDetected: _handleEmergency);
    await _voiceDetector?.init();
    
    // _motionDetector = MotionDetector(onEmergencyDetected: _handleEmergency);
    // _motionDetector?.startDetection();
  }

  void toggleMonitoring() {
    _isMonitoring = !_isMonitoring;
    
    if (_isMonitoring) {
      _voiceDetector?.startListening();
    } else {
      _voiceDetector?.stopListening();
    }
    
    notifyListeners();
  }

  void _handleEmergency([String? details]) async {
    print("message $details");
    // if (!_isMonitoring) return;
    
    // Get current location
    try {
      Position position = await LocationService.getCurrentLocation();
      
      // Format emergency message
      String message = "EMERGENCY ALERT!\n"
          "Location: https://maps.google.com/?q=${position.latitude},${position.longitude}\n"
          "Time: ${DateTime.now()}\n"
          "Details: ${details ?? 'Unknown emergency detected'}";
      
      // Send alert
      // _alertManager?.sendEmergencyAlert(message, position);
      
      // Show confirmation to user (discreetly)
      // In a real app, this would be a subtle notification
    } catch (e) {
      print("Error handling emergency: $e");
    }
  }

  void triggerEmergency() {
    _handleEmergency("Manual trigger by user");
  }

  @override
  void dispose() {
    _voiceDetector?.dispose();
    super.dispose();
  }
}