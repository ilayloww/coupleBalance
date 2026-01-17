import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'partner_link_screen.dart';
import 'package:couple_balance/l10n/app_localizations.dart';

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  Future<void> _unlinkPartner(String partnerUid, String partnerName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.unlinkPartnerTitle),
        content: Text(
          AppLocalizations.of(context)!.unlinkPartnerContent(partnerName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.unlink),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Remove partner from my list
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        {
          'partnerUids': FieldValue.arrayRemove([partnerUid]),
          // Clear legacy field only if it matches
          if (authService.currentUserModel?.partnerUid == partnerUid)
            'partnerUid': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );

      // Remove me from partner's list (Two-way unlink)
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(partnerUid),
        {
          'partnerUids': FieldValue.arrayRemove([currentUser.uid]),
          'partnerUid': FieldValue.delete(), // Legacy cleanup
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.unlinkedSuccess),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.partnersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartnerLinkScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final partners = authService.partners.reversed.toList();
          final selectedId = authService.selectedPartnerId;

          if (partners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.noPartnersLinkedYet),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PartnerLinkScreen(),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.linkPartner),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index];
              final isSelected = partner.uid == selectedId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: partner.photoUrl != null
                      ? NetworkImage(partner.photoUrl!)
                      : null,
                  child: partner.photoUrl == null
                      ? Text(
                          partner.displayName.isNotEmpty
                              ? partner.displayName[0].toUpperCase()
                              : '?',
                        )
                      : null,
                ),
                title: Text(
                  partner.displayName.isNotEmpty
                      ? partner.displayName
                      : 'Unknown Partner',
                ),
                subtitle: Text(partner.email ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.green),
                    IconButton(
                      icon: const Icon(Icons.broken_image, color: Colors.red),
                      onPressed: () =>
                          _unlinkPartner(partner.uid, partner.displayName),
                      tooltip: 'Unlink',
                    ),
                  ],
                ),
                onTap: () {
                  authService.selectPartner(partner.uid);
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
