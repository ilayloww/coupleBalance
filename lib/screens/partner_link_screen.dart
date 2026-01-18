import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../services/auth_service.dart';

class PartnerLinkScreen extends StatefulWidget {
  const PartnerLinkScreen({super.key});

  @override
  State<PartnerLinkScreen> createState() => _PartnerLinkScreenState();
}

class _PartnerLinkScreenState extends State<PartnerLinkScreen> {
  final _partnerEmailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _linkPartner() async {
    final email = _partnerEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final currentUserModel = authService.currentUserModel;

      if (currentUser == null || currentUserModel == null) return;

      // 1. Verify partner exists by Email
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.partnerNotFound),
          ),
        );
        return;
      }

      final partnerDoc = querySnapshot.docs.first;
      final partnerUid = partnerDoc.id;

      if (partnerUid == currentUser.uid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cannotLinkSelf)),
        );
        return;
      }

      // 2. Check if already linked
      if (currentUserModel.partnerUids.contains(partnerUid)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Partner already linked (${partnerDoc['displayName'] ?? email})',
            ),
          ),
        );
        return;
      }

      // 3. Check for existing pending request (to avoid spam)
      final existingRequests = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('fromUid', isEqualTo: currentUser.uid)
          .where('toUid', isEqualTo: partnerUid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequests.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request already sent! Wait for approval.'),
          ),
        );
        return;
      }

      // 4. Create Friend Request
      await FirebaseFirestore.instance.collection('friend_requests').add({
        'fromUid': currentUser.uid,
        'fromEmail': currentUser.email,
        'fromName': currentUser.displayName ?? currentUser.email,
        'toUid': partnerUid,
        'toEmail': partnerDoc['email'], // Saved for "Sent Requests" list
        'toName': partnerDoc['displayName'] ?? '', // Saved for display
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));

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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.linkPartnerTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.linkPartnerInstruction,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _partnerEmailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.partnerEmail,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
                      : Text(
                          AppLocalizations.of(context)!.linkPartnerTitle,
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
