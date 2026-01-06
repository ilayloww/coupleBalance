import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/auth_service.dart';

class PartnerLinkScreen extends StatefulWidget {
  const PartnerLinkScreen({super.key});

  @override
  State<PartnerLinkScreen> createState() => _PartnerLinkScreenState();
}

class _PartnerLinkScreenState extends State<PartnerLinkScreen> {
  final _partnerUidController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickContact() async {
    // Request permission
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        // In a real app, you would normalize the phone number and query Firestore
        // to find the user with that phone number.
        // For this POC, we will mock this by pretending the phone number IS the UID,
        // or just show a dialog to enter UID manually which is more reliable for dev.
        if (contact.phones.isNotEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected ${contact.displayName}: ${contact.phones.first.number}. In real app, we would resolve this to UID.',
              ),
            ),
          );
          // For now, we prefer manual UID entry for specific testing unless user exists
        }
      }
    }
  }

  Future<void> _linkPartner() async {
    final uid = _partnerUidController.text.trim();
    if (uid.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final currentUser = Provider.of<AuthService>(
        context,
        listen: false,
      ).currentUser;
      if (currentUser == null) return;

      // 1. Verify partner exists
      final partnerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!partnerDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Partner UID not found')));
        return;
      }

      // 2. Update my profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({'partnerUid': uid}, SetOptions(merge: true));

      // 3. (Optional) Update partner's profile to link back?
      // Usually better to have request/accept flow, but direct link for POC.

      if (!mounted) return;
      Navigator.pop(context); // Go back to Home
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Partner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Enter your partner\'s User ID to link accounts. You can find this in their specific profile or debug logs for now.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _partnerUidController,
              decoration: const InputDecoration(
                labelText: 'Partner UID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickContact,
              icon: const Icon(Icons.contacts),
              label: const Text('Pick from Contacts (Simulation)'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _linkPartner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Link Partner',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
