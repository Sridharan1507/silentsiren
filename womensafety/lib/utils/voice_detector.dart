// utils/voice_detector.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';

class VoiceDetector {
  static const String _emergencyKeyword = "help me";
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isListening = false;
  Function(String) onEmergencyDetected;

  VoiceDetector({required this.onEmergencyDetected});

  Future<void> init() async {
    await _recorder.openRecorder();
    // Load Vosk model would be implemented here
  }

  Future<void> startListening() async {
    if (_isListening) return;
    
    _isListening = true;
    await _recorder.startRecorder(toFile: 'temp_audio');
    
    // This is a simplified implementation
    // In a real app, you would process audio chunks with Vosk
    _recorder.onProgress?.listen((event) {
      // Process audio here
    });
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _recorder.stopRecorder();
    _isListening = false;
  }

  // This would be replaced with actual Vosk integration
  bool _processAudio(String text) {
    return text.toLowerCase().contains(_emergencyKeyword);
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}