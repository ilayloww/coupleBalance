import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';

class PartnerProfileScreen extends StatefulWidget {
  final String partnerUid;

  const PartnerProfileScreen({super.key, required this.partnerUid});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  bool _isLoading = false;

  Future<void> _confirmUnlink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Partner?'),
        content: const Text(
          'Are you sure you want to unlink? You will no longer see shared expenses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final myUid = Provider.of<AuthService>(
          context,
          listen: false,
        ).currentUser!.uid;

        final batch = FirebaseFirestore.instance.batch();
        final myRef = FirebaseFirestore.instance.collection('users').doc(myUid);
        final partnerRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.partnerUid);

        // Remove field using FieldValue.delete()
        batch.update(myRef, {'partnerUid': FieldValue.delete()});
        batch.update(partnerRef, {'partnerUid': FieldValue.delete()});

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unlinked successfully')),
          );
          Navigator.pop(context); // Go back to Home
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error unlinking: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Profile'),
        // backgroundColor: handled by Theme
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.partnerUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Center(child: Text('Partner data not found'));
          }

          final displayName = data['displayName'] as String? ?? 'Partner';
          final email = data['email'] as String? ?? 'No Email';
          final photoUrl = data['photoUrl'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blueAccent.shade100,
                    backgroundImage: photoUrl != null
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _confirmUnlink(),
                      icon: const Icon(Icons.link_off, color: Colors.red),
                      label: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Unlink Partner',
                              style: TextStyle(color: Colors.red),
                            ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
