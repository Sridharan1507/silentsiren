// widgets/settings_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:womensafety/providers/alert_provider.dart';
import 'package:womensafety/screens/contacts_screen.dart';

class SettingsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
        
          Divider(),
          ListTile(
            title: Text('Emergency Contacts'),
            subtitle: Text('Manage who receives alerts'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              // Navigate to contacts screen
              Navigator.push(context, MaterialPageRoute(builder: (context) => ContactScreen()));
            },
          ),
         
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}