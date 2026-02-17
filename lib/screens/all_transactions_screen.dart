import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_balance/config/theme.dart';
import 'package:couple_balance/l10n/app_localizations.dart';

import 'package:couple_balance/models/transaction_model.dart';
import 'package:couple_balance/widgets/dashboard_widgets.dart';
import 'package:couple_balance/screens/transaction_detail_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  final String userUid;
  final String partnerUid;
  final String partnerName;

  const AllTransactionsScreen({
    super.key,
    required this.userUid,
    required this.partnerUid,
    required this.partnerName,
  });

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  late Stream<QuerySnapshot> _transactionStream;

  @override
  void initState() {
    super.initState();
    _initStream();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initStream() {
    // Fetch all transactions involving me
    _transactionStream = FirebaseFirestore.instance
        .collection('transactions')
        .where(
          Filter.or(
            Filter('senderUid', isEqualTo: widget.userUid),
            Filter('receiverUid', isEqualTo: widget.userUid),
          ),
        )
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  String _getGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return AppLocalizations.of(context)!.today;
    } else if (checkDate == yesterday) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      return DateFormat('MMMM d').format(date).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black, // Dark background as per design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.allTransactions,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A2621),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                hintText: l10n.searchTransactionHint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppTheme.emeraldPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _transactionStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Filter valid transactions between me and partner
                var filteredDocs = allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  if (data['isDeleted'] == true || data['isSettled'] == true) {
                    return false;
                  }

                  final sender = data['senderUid'];
                  final receiver = data['receiverUid'];

                  // Must involve partner
                  if (sender != widget.partnerUid &&
                      receiver != widget.partnerUid) {
                    return false;
                  }

                  // Search logic
                  if (_searchQuery.isNotEmpty) {
                    final note = (data['note'] ?? '').toString().toLowerCase();
                    final category = (data['category'] ?? '')
                        .toString()
                        .toLowerCase();
                    if (!note.contains(_searchQuery) &&
                        !category.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noTransactionsFound,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                // Group by date
                Map<String, List<DocumentSnapshot>> grouped = {};
                for (var doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = (data['timestamp'] as Timestamp).toDate();
                  final header = _getGroupHeader(timestamp);
                  if (!grouped.containsKey(header)) {
                    grouped[header] = [];
                  }
                  grouped[header]!.add(doc);
                }

                // Keys are already somewhat sorted because input was sorted,
                // but "TODAY" / "YESTERDAY" logic might mix with "OCTOBER 24".
                // Since original list is desc by time, the iteration order should preserve date desc order.
                // "Today" comes first, then "Yesterday", then older dates.

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final header = grouped.keys.elementAt(index);
                    final docsInGroup = grouped[header]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            header,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        ...docsInGroup.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final tx = TransactionModel.fromMap(data, doc.id);
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailScreen(
                                    transaction: tx,
                                    currentUserId: widget.userUid,
                                  ),
                                ),
                              );
                            },
                            child: SwipeableTransactionTile(
                              transaction: tx,
                              currentUserId: widget.userUid,
                              partnerName: widget.partnerName,
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
