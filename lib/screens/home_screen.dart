import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import 'add_expense_screen.dart';
import 'partner_link_screen.dart';
import 'profile_screen.dart';
import 'partner_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) {
      return const SizedBox(); // Should not happen due to AuthWrapper
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      appBar: AppBar(
        leading: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final partnerUid = userData?['partnerUid'];

            if (partnerUid == null) return const SizedBox();

            return _AnimatedHeartButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PartnerProfileScreen(partnerUid: partnerUid),
                  ),
                );
              },
            );
          },
        ),
        title: const Text(
          'CoupleBalance',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final userData = snapshot.data?.data() as Map<String, dynamic>?;
              final displayName = userData?['displayName'] as String? ?? '';
              final email = userData?['email'] as String? ?? '';
              final photoBase64 = userData?['photoBase64'] as String?;

              String initials = 'U';
              if (displayName.isNotEmpty) {
                initials = displayName[0].toUpperCase();
              } else if (email.isNotEmpty) {
                initials = email[0].toUpperCase();
              }

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.pinkAccent,
                    backgroundImage: photoBase64 != null
                        ? MemoryImage(base64Decode(photoBase64))
                        : null,
                    child: photoBase64 == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance Card
          _BalanceCard(userUid: user.uid),

          // Transaction Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.history, color: Colors.grey),
              ],
            ),
          ),

          // Transaction List
          Expanded(child: _TransactionList(userUid: user.uid)),
        ],
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final partnerUid = userData?['partnerUid'];

          return FloatingActionButton(
            onPressed: () {
              if (partnerUid == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please link a partner first')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(partnerUid: partnerUid),
                ),
              );
            },
            backgroundColor: Colors.pinkAccent,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String userUid;
  const _BalanceCard({required this.userUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox();

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        final partnerUid = userData?['partnerUid'] as String?;

        if (partnerUid == null) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'No Partner Linked',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnerLinkScreen(),
                      ),
                    );
                  },
                  child: const Text('Link Partner'),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          // Fetch all transactions involving me OR partner is hard with one query unless we have a 'chatId' or similar.
          // For POC, we fetch 'transactions' collection generally and filter client side?
          // OR better: 'transactions' where users array-contains 'me'.
          // Let's assume we filter client-side for now or use Composite Query.
          // Simplest for POC: fetch all transactions where 'senderUid' is Me or 'receiverUid' is Me.
          // Firestore doesn't support logical OR directly in one field easily without multiple queries.
          // So we will do TWO streams and Merge, or just fetch all 'transactions' (if small scale)
          // Let's use two streams approach via 'rxdart' usually, but here just StreamBuilder nesting or simple approach.

          // Optimization: Let's assume we just query 'transactions' orders by timestamp.
          // We will filter in the builder logic for simplicity in this proto.
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, txSnap) {
            if (!txSnap.hasData) return const CircularProgressIndicator();

            final docs = txSnap.data!.docs;
            double mySpends = 0;
            double partnerSpends = 0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final sender = data['senderUid'];
              final receiver = data['receiverUid'];
              final amount = (data['amount'] ?? 0).toDouble();

              if (sender == userUid && receiver == partnerUid) {
                mySpends += amount;
              } else if (sender == partnerUid && receiver == userUid) {
                partnerSpends += amount;
              }
            }

            final netBalance = mySpends - partnerSpends;
            final isPositive = netBalance >= 0;
            final absBalance = netBalance.abs();

            // Settlement Day Logic
            final today = DateTime.now();
            final settlementDay = userData?['settlementDay'] ?? 10;
            var targetDate = DateTime(today.year, today.month, settlementDay);
            if (today.day > settlementDay) {
              targetDate = DateTime(today.year, today.month + 1, settlementDay);
            }
            final daysLeft = targetDate.difference(today).inDays;

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent.shade100, Colors.pinkAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isPositive ? 'Partner owes you' : 'You owe Partner',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${absBalance.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectSettlementDay(
                      context,
                      userUid,
                      partnerUid,
                      settlementDay,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Settlement in $daysLeft days',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectSettlementDay(
    BuildContext context,
    String myUid,
    String? partnerUid,
    int currentDay,
  ) async {
    final pickedDay = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Settlement Day'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;
                return ListTile(
                  title: Text('Day $day'),
                  selected: day == currentDay,
                  onTap: () => Navigator.pop(ctx, day),
                );
              },
            ),
          ),
        );
      },
    );

    if (pickedDay != null && pickedDay != currentDay) {
      final batch = FirebaseFirestore.instance.batch();
      final myRef = FirebaseFirestore.instance.collection('users').doc(myUid);

      batch.set(myRef, {'settlementDay': pickedDay}, SetOptions(merge: true));

      if (partnerUid != null) {
        final partnerRef = FirebaseFirestore.instance
            .collection('users')
            .doc(partnerUid);
        batch.set(partnerRef, {
          'settlementDay': pickedDay,
        }, SetOptions(merge: true));
      }

      await batch.commit();
    }
  }
}

class _TransactionList extends StatelessWidget {
  final String userUid;
  const _TransactionList({required this.userUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No transactions yet.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final tx = TransactionModel.fromMap(data, docs[index].id);
            final isMe = tx.senderUid == userUid;

            final docId = docs[index].id;

            final cardWidget = Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: isMe ? Colors.pink[50] : Colors.blue[50],
                  child: Icon(
                    isMe ? Icons.arrow_outward : Icons.arrow_downward,
                    color: isMe ? Colors.pink : Colors.blue,
                  ),
                ),
                title: Text(
                  tx.note,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat.MMMd().add_jm().format(tx.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: Text(
                  '${isMe ? '+' : '-'}${tx.amount.toStringAsFixed(0)} ${tx.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isMe ? Colors.pink : Colors.blue,
                  ),
                ),
              ),
            );

            if (!isMe) return cardWidget;

            return Dismissible(
              key: Key(docId),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Transaction?'),
                    content: const Text(
                      'Are you sure you want to delete this item?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                FirebaseFirestore.instance
                    .collection('transactions')
                    .doc(docId)
                    .delete();
              },
              child: cardWidget,
            );
          },
        );
      },
    );
  }
}

class _AnimatedHeartButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedHeartButton({required this.onPressed});

  @override
  State<_AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<_AnimatedHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await HapticFeedback.mediumImpact();
    await _controller.forward();
    await _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.favorite, color: Colors.redAccent, size: 28),
        ),
      ),
    );
  }
}
