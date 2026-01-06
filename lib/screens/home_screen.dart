import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import 'add_expense_screen.dart';
import 'partner_link_screen.dart';

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
        title: const Text(
          'CoupleBalance',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Settlement in $daysLeft days',
                      style: const TextStyle(color: Colors.white),
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

            return Card(
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
          },
        );
      },
    );
  }
}
