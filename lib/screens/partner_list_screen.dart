import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import 'partner_link_screen.dart';
import 'package:couple_balance/l10n/app_localizations.dart';

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ... [Keep _unlinkPartner, _respondToRequest, _cancelRequest methods unchanged] ...

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

      // --- 1. Delete Transactions ---
      final txQuery1 = await FirebaseFirestore.instance
          .collection('transactions')
          .where('senderUid', isEqualTo: currentUser.uid)
          .where('receiverUid', isEqualTo: partnerUid)
          .get();

      final txQuery2 = await FirebaseFirestore.instance
          .collection('transactions')
          .where('senderUid', isEqualTo: partnerUid)
          .where('receiverUid', isEqualTo: currentUser.uid)
          .get();

      for (var doc in txQuery1.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in txQuery2.docs) {
        batch.delete(doc.reference);
      }

      // --- 2. Delete Settlements ---
      final settlementQuery1 = await FirebaseFirestore.instance
          .collection('settlements')
          .where('payerUid', isEqualTo: currentUser.uid)
          .where('receiverUid', isEqualTo: partnerUid)
          .get();

      final settlementQuery2 = await FirebaseFirestore.instance
          .collection('settlements')
          .where('payerUid', isEqualTo: partnerUid)
          .where('receiverUid', isEqualTo: currentUser.uid)
          .get();

      for (var doc in settlementQuery1.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in settlementQuery2.docs) {
        batch.delete(doc.reference);
      }

      // --- 3. Unlink Users ---
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
        {
          'partnerUids': FieldValue.arrayRemove([partnerUid]),
          if (authService.currentUserModel?.partnerUid == partnerUid)
            'partnerUid': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        FirebaseFirestore.instance.collection('users').doc(partnerUid),
        {
          'partnerUids': FieldValue.arrayRemove([currentUser.uid]),
          'partnerUid': FieldValue.delete(),
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
        final myRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid);
        final partnerRef = FirebaseFirestore.instance
            .collection('users')
            .doc(fromUid);

        batch.set(myRef, {
          'partnerUids': FieldValue.arrayUnion([fromUid]),
          'partnerUid': fromUid,
        }, SetOptions(merge: true));

        batch.set(partnerRef, {
          'partnerUids': FieldValue.arrayUnion([currentUser.uid]),
        }, SetOptions(merge: true));

        batch.update(requestRef, {'status': 'accepted'});
      } else {
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

  @override
  Widget build(BuildContext context) {
    // Determine colors based on brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF05100A) // AppTheme.darkBackground
        : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final searchBarColor = isDark ? const Color(0xFF1A2E25) : Colors.grey[200];
    final searchIconColor = isDark ? Colors.grey : Colors.grey[600];
    final greenAccent = const Color(0xFF00E676);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connections',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final currentUser = authService.currentUser;
          if (currentUser == null) return const SizedBox();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: searchBarColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search by User',
                      hintStyle: TextStyle(color: searchIconColor),
                      prefixIcon: Icon(Icons.search, color: searchIconColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pending Requests Section
                _buildSectionTitle('Pending Requests', textColor),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('friend_requests')
                      .where('toUid', isEqualTo: currentUser.uid)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        // Center vertically:
                        // Top space: 12 (title padding) + 28 = 40
                        // Bottom space: 16 (this padding) + 24 (next section margin) = 40
                        padding: const EdgeInsets.only(top: 28.0, bottom: 16.0),
                        child: Center(
                          child: Text(
                            'No pending requests',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      );
                    }

                    final requests = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['fromName'] ?? '')
                          .toString()
                          .toLowerCase();
                      final email = (data['fromEmail'] ?? '')
                          .toString()
                          .toLowerCase();
                      return _searchText.isEmpty ||
                          name.contains(_searchText) ||
                          email.contains(_searchText);
                    }).toList();

                    if (requests.isEmpty && _searchText.isNotEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: requests.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildPendingRequestItem(
                          context,
                          doc.id,
                          data,
                          textColor,
                          greenAccent,
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Active Connections Section
                _buildSectionTitle('Active Connections', textColor),
                _buildPartnersList(
                  context,
                  authService,
                  textColor,
                  greenAccent,
                ),
                const SizedBox(height: 32),

                // Invite via Link (Mockup)
                _buildInviteCard(context, greenAccent),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPendingRequestItem(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data,
    Color textColor,
    Color accentColor,
  ) {
    final fromName = data['fromName'] as String?;
    final fromEmail = data['fromEmail'] as String? ?? '';

    final displayName = (fromName != null && fromName.isNotEmpty)
        ? fromName
        : fromEmail;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: null, // Placeholder or fetch image if available
            backgroundColor: Colors.grey.shade800,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (fromEmail.isNotEmpty && fromEmail != displayName)
                  Text(
                    fromEmail,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                Text(
                  'Wants to track expenses',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          // Reject Button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: () =>
                  _respondToRequest(requestId, data['fromUid'], false),
            ),
          ),
          const SizedBox(width: 8),
          // Accept Button
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () =>
                  _respondToRequest(requestId, data['fromUid'], true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Accept',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersList(
    BuildContext context,
    AuthService authService,
    Color textColor,
    Color accentColor,
  ) {
    final partners = authService.partners.reversed.where((p) {
      final name = p.displayName.toLowerCase();
      return _searchText.isEmpty || name.contains(_searchText);
    }).toList();

    if (partners.isEmpty) {
      if (_searchText.isNotEmpty) {
        return Text(
          'No connections found matching "$_searchText"',
          style: TextStyle(color: Colors.grey.shade500),
        );
      }
      // Empty state with Link Partner button
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              'No active connections yet.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PartnerLinkScreen()),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Link a Partner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedPartnerId = authService.selectedPartnerId;

    return Column(
      children: partners.map((partner) {
        final isSelected = partner.uid == selectedPartnerId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isSelected) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${partner.displayName} is already active.',
                      ),
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                }
                return;
              }

              authService.selectPartner(partner.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched to ${partner.displayName}'),
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: accentColor.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  // Avatar with Green Border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: partner.photoUrl != null
                          ? CachedNetworkImageProvider(partner.photoUrl!)
                          : null,
                      backgroundColor: Colors.grey.shade800,
                      child: partner.photoUrl == null
                          ? Text(
                              partner.displayName.isNotEmpty
                                  ? partner.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner.displayName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // "Shared Wallet" text removed
                        Text(
                          partner.email ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current selection indicator or Menu
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.check_circle,
                        color: accentColor,
                        size: 24,
                      ),
                    ),

                  // Menu / Unlink
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
                    color: Colors.grey.shade900,
                    onSelected: (value) {
                      if (value == 'unlink') {
                        _unlinkPartner(partner.uid, partner.displayName);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'unlink',
                        child: Row(
                          children: const [
                            Icon(
                              Icons.broken_image,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Unlink',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInviteCard(BuildContext context, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2618), // Slightly lighter dark green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B3E2B)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF153322),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_add_alt_1, color: accentColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            'Invite via Link',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a magic link to connect instantly without searching.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PartnerLinkScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF153322),
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Share Invite Link',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
