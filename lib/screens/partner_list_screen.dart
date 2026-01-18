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

  Future<void> _respondToRequest(
    String requestId,
    String fromUid,
    bool accept,
  ) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final requestRef = FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId);

      if (accept) {
        // 1. Link Users (Two-way)
        final myRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid);
        final partnerRef = FirebaseFirestore.instance
            .collection('users')
            .doc(fromUid);

        batch.set(myRef, {
          'partnerUids': FieldValue.arrayUnion([fromUid]),
          'partnerUid': fromUid, // Legacy support
        }, SetOptions(merge: true));

        batch.set(partnerRef, {
          'partnerUids': FieldValue.arrayUnion([currentUser.uid]),
          // We don't force 'partnerUid' on them, they can select manually
        }, SetOptions(merge: true));

        // 2. Update Request Status
        batch.update(requestRef, {'status': 'accepted'});
      } else {
        // Reject
        batch.update(requestRef, {'status': 'rejected'});
      }

      await batch.commit();

      if (accept && mounted) {
        authService.selectPartner(fromUid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner Request Accepted!')),
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

  Future<void> _cancelRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request cancelled')));
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
          final currentUser = authService.currentUser;
          if (currentUser == null) return const SizedBox();

          return Column(
            children: [
              // 1. Pending Requests Section
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('friend_requests')
                    .where('toUid', isEqualTo: currentUser.uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox();
                  }

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final cardColor = isDark
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.orange.shade50;
                  final titleColor = isDark
                      ? Colors.orangeAccent
                      : Colors.orange.shade900;

                  return Card(
                    margin: const EdgeInsets.all(16),
                    color: cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Pending Requests',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ),
                        ...snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final fromEmail = data['fromEmail'] ?? 'Unknown';
                          final fromName = data['fromName'] ?? '';

                          return ListTile(
                            title: Text(
                              fromName.isNotEmpty ? fromName : fromEmail,
                              style: TextStyle(
                                // Ensure text is visible on the background
                                color: isDark
                                    ? Colors.orange.shade100
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Invites you to link',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _respondToRequest(
                                    doc.id,
                                    data['fromUid'],
                                    true,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _respondToRequest(
                                    doc.id,
                                    data['fromUid'],
                                    false,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

              // 2. Sent Requests Section (Sent)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('friend_requests')
                    .where('fromUid', isEqualTo: currentUser.uid)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox();
                  }

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final cardColor = isDark
                      ? Colors.grey.withValues(alpha: 0.1)
                      : Colors.grey.shade100;
                  final titleColor = isDark
                      ? Colors.grey.shade300
                      : Colors.grey.shade800;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Sent Requests',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ),
                        ...snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final toEmail = data['toEmail'] ?? 'Unknown';
                          final toName = data['toName'] as String?;

                          // Use name if available, fallback to email
                          final displayName =
                              (toName != null && toName.isNotEmpty)
                              ? toName
                              : toEmail;

                          // If we show name in title, show email in subtitle
                          final displaySubtitle =
                              (toName != null && toName.isNotEmpty)
                              ? '$toEmail\nWaiting for approval...'
                              : 'Waiting for approval...';

                          return ListTile(
                            leading: Icon(Icons.outbound, color: titleColor),
                            title: Text(
                              displayName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              displaySubtitle,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            isThreeLine: (toName != null && toName.isNotEmpty),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () => _cancelRequest(doc.id),
                              tooltip: 'Cancel Request',
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

              // 2. Existing Partners List
              Expanded(child: _buildPartnersList(context, authService)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPartnersList(BuildContext context, AuthService authService) {
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
                  MaterialPageRoute(builder: (_) => const PartnerLinkScreen()),
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
  }
}
