// widgets/emergency_button.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:womensafety/main.dart';
import 'package:womensafety/utils/alert_manager.dart';
import 'package:womensafety/utils/location_service.dart';
import 'package:another_telephony/telephony.dart';
import 'package:intl/intl.dart';

class EmergencyButton extends StatefulWidget {
  @override
  _EmergencyButtonState createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton> {
  bool _isPressed = false;
final telephony = Telephony.instance;
String? _userName;
Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName');
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUser();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
              onTap: () async {
          print("on Tap clicked");
          try {
            Position position = await LocationService.getCurrentLocation();

            String message =
                "EMERGENCY ALERT! triggered by Tap,\n $_userName is in trouble\n"
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
               await SmsHelper.sendAlertToContacts(fullMessage);
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
        },
        //       onLongPress: () async {
        //   // Long press also triggers emergency
        //   try {
        //     Position position = await LocationService.getCurrentLocation();
        //     String message =
        //         "EMERGENCY ALERT!\n"
        //         "Time: ${DateTime.now()}\n";
        //     String locationUrl =
        //         "https://maps.google.com/?q=${position.latitude},${position.longitude}";
        //     String fullMessage = "$message\nLocation: $locationUrl";

        //     // Request SMS permission
        //     bool hasPermission = await telephony.isSmsCapable ?? false;
        //     if (!hasPermission) {
        //       hasPermission = await telephony.requestSmsPermissions ?? false;
        //     }

        //     if (hasPermission) {
        //       try {
        //         await telephony.sendSms(to: "+919597292187", message: fullMessage);
        //         print('SMS sent successfully');
        //       } catch (e) {
        //         print('Error sending SMS: $e');
        //       }
        //     } else {
        //       print("SMS permission denied");
        //     }
        //   } catch (e) {
        //     print('Error getting location: $e');
        //   }
        // },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed ? Colors.red[200] : Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(Icons.warning_rounded, size: 60, color: Colors.white),
      ),
    );
  }
}
