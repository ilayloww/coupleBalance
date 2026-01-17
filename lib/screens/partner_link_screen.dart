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
      final currentUser = Provider.of<AuthService>(
        context,
        listen: false,
      ).currentUser;
      if (currentUser == null) return;

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

      // 2. Update my profile
      // 2. Update my profile
      final batch = FirebaseFirestore.instance.batch();

      final myDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      final partnerDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUid);

      batch.set(myDocRef, {'partnerUid': partnerUid}, SetOptions(merge: true));
      // 3. Update partner's profile to link back immediately (Two-way link)
      batch.set(partnerDocRef, {
        'partnerUid': currentUser.uid,
      }, SetOptions(merge: true));

      await batch.commit();

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
