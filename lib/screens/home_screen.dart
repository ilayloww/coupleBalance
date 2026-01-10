import 'package:flutter/material.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import 'add_expense_screen.dart';
import 'partner_link_screen.dart';
import 'profile_screen.dart';
import 'partner_profile_screen.dart';
import 'settlement_history_screen.dart';
import '../viewmodels/settlement_viewmodel.dart';
import 'transaction_detail_screen.dart';

import '../services/notification_service.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeService>(context); // Listen to Theme changes
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) {
      return const SizedBox(); // Should not happen due to AuthWrapper
    }

    return Scaffold(
      // backgroundColor: handled by Theme
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
        title: const Text('CoupleBalance'),
        centerTitle: true,
        // backgroundColor: handled by Theme
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
              final photoUrl = userData?['photoUrl'] as String?;

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
                    backgroundImage: photoUrl != null
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl == null
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
              children: [
                Text(
                  AppLocalizations.of(context)!.recentTransactions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.pleaseLinkPartnerFirst,
                    ),
                  ),
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.noPartnerLinked,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                  child: Text(AppLocalizations.of(context)!.linkPartner),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .where(
                Filter.or(
                  Filter('senderUid', isEqualTo: userUid),
                  Filter('receiverUid', isEqualTo: userUid),
                ),
              )
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, txSnap) {
            if (txSnap.hasError) {
              debugPrint('BalanceCard Error: ${txSnap.error}');
              return const Center(child: Text('Error loading data'));
            }
            if (!txSnap.hasData) return const CircularProgressIndicator();
            final docs = txSnap.data!.docs;
            double mySpends = 0;
            double partnerSpends = 0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['isSettled'] == true) continue; // Skip settled

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
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final settlementDay = userData?['settlementDay'] ?? 10;

            var targetDate = DateTime(today.year, today.month, settlementDay);
            if (today.day > settlementDay) {
              targetDate = DateTime(today.year, today.month + 1, settlementDay);
            }
            final daysLeft = targetDate.difference(today).inDays;

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.pink.shade900.withValues(alpha: 0.8),
                          Colors.pink.shade600.withValues(alpha: 0.9),
                        ]
                      : [Colors.pinkAccent.shade100, Colors.pinkAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.pinkAccent : Colors.pinkAccent)
                        .withValues(alpha: isDark ? 0.15 : 0.3),
                    blurRadius: isDark ? 20 : 10,
                    offset: isDark ? const Offset(0, 0) : const Offset(0, 5),
                    spreadRadius: isDark ? 2 : 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isPositive
                        ? AppLocalizations.of(context)!.partnerOwesYou
                        : AppLocalizations.of(context)!.youOwePartner,
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
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.1 : 0.2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: isDark
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 0.5,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.settlementInDays(daysLeft),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (absBalance > 0)
                        ElevatedButton.icon(
                          onPressed: () => _showSettleUpDialog(
                            context,
                            userUid,
                            partnerUid,
                            absBalance,
                            !isPositive, // I am payer if balance is negative (partner owes me is positive) -> Wait.
                            // isPositive = (mySpends - partnerSpends) >= 0.
                            // If positive: partner owes me. I am receiver. IAmPayer = false.
                            // If negative: I owe partner. I am payer. IAmPayer = true.
                            // Logic: isPositive means Partner Owes Me.
                            // So if isPositive is true, iAmPayer is false.
                            // If isPositive is false, iAmPayer is true.
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(AppLocalizations.of(context)!.settleUp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.white,
                            foregroundColor: isDark
                                ? Colors.pink.shade700
                                : Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      if (absBalance > 0) const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettlementHistoryScreen(
                                myUid: userUid,
                                partnerUid: partnerUid,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, color: Colors.white),
                        tooltip: AppLocalizations.of(context)!.history,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(
                            alpha: isDark ? 0.1 : 0.15,
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSettleUpDialog(
    BuildContext context,
    String myUid,
    String partnerUid,
    double amount,
    bool iAmPayer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.settleUpTitle),
        content: Text(
          AppLocalizations.of(context)!.settleUpContent(
            amount.toStringAsFixed(2),
            '₺',
            iAmPayer
                ? AppLocalizations.of(context)!.youArePaying
                : AppLocalizations.of(context)!.partnerIsPaying,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ChangeNotifierProvider(
            create: (_) => SettlementViewModel(),
            child: Consumer<SettlementViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const CircularProgressIndicator();
                }
                return TextButton(
                  onPressed: () async {
                    final success = await viewModel.settleUp(
                      myUid: myUid,
                      partnerUid: partnerUid,
                      totalAmount: amount,
                      iAmPayer: iAmPayer,
                    );
                    if (context.mounted) {
                      Navigator.pop(context, success);
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.confirm,
                    style: TextStyle(
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settlementComplete),
        ),
      );
    }
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
          title: Text(AppLocalizations.of(context)!.selectSettlementDay),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;
                return ListTile(
                  title: Text(AppLocalizations.of(context)!.day(day)),
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
          .where(
            Filter.or(
              Filter('senderUid', isEqualTo: userUid),
              Filter('receiverUid', isEqualTo: userUid),
            ),
          )
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('TransactionList Error: ${snapshot.error}');
          return const Center(child: Text('Error loading data'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        // Filter out deleted and settled transactions
        final docs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['isDeleted'] != true && data['isSettled'] != true;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noTransactionsYet),
          );
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
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(
                        transaction: tx,
                        currentUserId: userUid,
                      ),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: isMe
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.1),
                  child: Icon(
                    isMe ? Icons.arrow_outward : Icons.arrow_downward,
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: Text(
                  tx.note,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat.MMMd().add_jm().format(tx.timestamp),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                trailing: Text(
                  '${isMe ? '+' : '-'}${tx.amount % 1 == 0 ? tx.amount.toInt().toString() : tx.amount.toString()} ${tx.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            );

            final canDelete = tx.addedByUid != null
                ? tx.addedByUid == userUid
                : tx.senderUid == userUid;

            if (!canDelete) return cardWidget;

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
                    title: Text(
                      AppLocalizations.of(context)!.deleteTransactionTitle,
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.deleteTransactionContent,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          AppLocalizations.of(context)!.delete,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                final myUid = Provider.of<AuthService>(
                  context,
                  listen: false,
                ).currentUser?.uid;
                if (myUid != null) {
                  FirebaseFirestore.instance
                      .collection('transactions')
                      .doc(docId)
                      .update({'isDeleted': true, 'deletedBy': myUid});
                }
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
