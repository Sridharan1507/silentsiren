import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  /// Load contacts from SharedPreferences
  Future<void> _loadContacts() async {
  final prefs = await SharedPreferences.getInstance();
  final String? contactsJson = prefs.getString('contacts');
  
  List<Map<String, String>> loadedContacts = [];
  
  if (contactsJson != null && contactsJson.isNotEmpty) {
    final List<dynamic> decoded = json.decode(contactsJson);
    loadedContacts = decoded.map<Map<String, String>>((e) {
      final map = Map<String, dynamic>.from(e);
      return {
        'name': map['name']?.toString() ?? '',
        'phone': map['phone']?.toString() ?? '',
      };
    }).toList();
  }

  setState(() {
    _contacts = loadedContacts;
  });
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadContacts(); // reload every time the screen becomes visible
}

  /// Save contacts to SharedPreferences
  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('contacts', json.encode(_contacts));
  }

  /// Add a new contact
  void _addContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) return;

    setState(() {
      _contacts.add({'name': name, 'phone': phone});
    });

    _saveContacts();

    _nameController.clear();
    _phoneController.clear();
  }

  /// Delete a contact
  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contacts")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input fields
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // only numbers
                LengthLimitingTextInputFormatter(10), // max 10 chars
              ],
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addContact,
              child: const Text("Add Contact"),
            ),
            const SizedBox(height: 20),

            // Contact list
            Expanded(
              child:
                  _contacts.isEmpty
                      ? const Center(child: Text("No contacts saved"))
                      : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return Card(
                            child: ListTile(
                              title: Text(contact['name'] ?? ''),
                              subtitle: Text(contact['phone'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteContact(index),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
