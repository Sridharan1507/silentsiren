import 'dart:convert';
import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SmsHelper {
  static final Telephony telephony = Telephony.instance;

  static Future<List<Map<String, String>>> _getSavedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      final List<dynamic> decoded = json.decode(contactsJson);
      return decoded.map((e) {
        return {
          'name': e['name']?.toString() ?? '',
          'phone': e['phone']?.toString() ?? '',
        };
      }).toList();
    }
    return [];
  }

  static Future<void> sendAlertToContacts(String fullMessage) async {
    bool hasPermission = await telephony.isSmsCapable ?? false;
    if (!hasPermission) {
      hasPermission = await telephony.requestSmsPermissions ?? false;
    }

    if (hasPermission) {
      final contacts = await _getSavedContacts();

      if (contacts.isEmpty) {
        print("No contacts saved");
        return;
      }

      for (final contact in contacts) {
        final phone = contact['phone'];
        print("+91$phone");
        if (phone != null && phone.isNotEmpty) {
          try {
            await telephony.sendSms(
              to: "+91$phone",
              message: fullMessage,
            );
            print("SMS sent to $phone");
          } catch (e) {
            print("Error sending SMS to $phone: $e");
          }
        }
      }
    } else {
      print("SMS permission denied");
    }
  }
}
