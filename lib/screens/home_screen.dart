import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/theme.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import 'partner_link_screen.dart';
import 'profile_screen.dart';
// import 'partner_profile_screen.dart'; // Unused
// import 'settlement_history_screen.dart'; // Used in Details
import 'settlement_history_screen.dart';
import '../viewmodels/settlement_viewmodel.dart';
import 'partner_list_screen.dart';
import 'transaction_detail_screen.dart';
import 'all_transactions_screen.dart'; // Added
import '../models/user_model.dart';
import '../services/theme_service.dart';
import '../services/update_service.dart';
import '../services/deep_link_service.dart'; // Add this
import '../widgets/pending_settlements_widget.dart';
import '../widgets/dashboard_widgets.dart'; // New Dashboard Widgets

class HomeScreen extends StatefulWidget {
  final int? refreshTrigger;
  const HomeScreen({super.key, this.refreshTrigger});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay to allow DeepLinkService to process any initial link
      // and set 'isHandlingLink' flag before showing update dialog.
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        final deepLinkService = Provider.of<DeepLinkService>(
          context,
          listen: false,
        );
        if (kDebugMode) {
          debugPrint(
            'HomeScreen: isHandlingLink: ${deepLinkService.isHandlingLink}',
          );
        }
        if (!deepLinkService.isHandlingLink) {
          UpdateService().checkForUpdate(context);
        } else {
          if (kDebugMode) {
            debugPrint('HomeScreen: Skipping update check due to deep link.');
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeService>(context); // Listen to Theme changes

    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        if (user == null) {
          return const SizedBox();
        }

        // Use selected partner ID managed by AuthService
        final selectedPartnerId = authService.selectedPartnerId;
        final selectedPartner = authService.partners.firstWhere(
          (p) => p.uid == selectedPartnerId,
          orElse: () => UserModel(uid: '', displayName: '', partnerUids: []),
        );

        if (authService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          extendBody: true, // Allow content to extend behind bottom nav
          // Background color usually handled by theme, but for this specific dashboard look
          // we might want to ensure it's compatible with the dark theme.
          // The screenshot implies a dark background. Our theme is already dark emerald.
          body: SafeArea(
            bottom:
                false, // Don't add bottom safe area padding - let content extend
            child: Column(
              children: [
                // 1. Header
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final userData =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    final displayName =
                        userData?['displayName'] as String? ?? '';
                    final photoUrl = userData?['photoUrl'] as String?;

                    return DashboardHeader(
                      displayName: displayName,
                      photoUrl: photoUrl,
                      onProfileTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      onNotificationTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PartnerListScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),

                // 2. Balance Section
                _DashboardBalanceSection(
                  userUid: user.uid,
                  partnerUid: selectedPartnerId,
                  partnerName: selectedPartner.displayName,
                  refreshTrigger: widget.refreshTrigger,
                ),

                // 3. Pending Settlements (Keep existing logic)
                PendingSettlementsWidget(
                  myUid: user.uid,
                  partnerUid: selectedPartnerId,
                ),

                // 4. Transaction List
                Expanded(
                  child: _DashboardTransactionList(
                    userUid: user.uid,
                    partnerUid: selectedPartnerId,
                    partnerName: selectedPartner.displayName,
                    refreshTrigger: widget.refreshTrigger,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardBalanceSection extends StatefulWidget {
  final String userUid;
  final String? partnerUid;
  final String partnerName;
  final int? refreshTrigger;

  const _DashboardBalanceSection({
    required this.userUid,
    this.partnerUid,
    this.partnerName = "Partner",
    this.refreshTrigger,
  });

  @override
  State<_DashboardBalanceSection> createState() =>
      _DashboardBalanceSectionState();
}

class _DashboardBalanceSectionState extends State<_DashboardBalanceSection> {
  late Stream<QuerySnapshot> _transactionStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(_DashboardBalanceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userUid != widget.userUid ||
        oldWidget.partnerUid != widget.partnerUid ||
        oldWidget.refreshTrigger != widget.refreshTrigger) {
      _initStreams();
    }
  }

  void _initStreams() {
    _transactionStream = FirebaseFirestore.instance
        .collection('transactions')
        .where(
          Filter.or(
            Filter('senderUid', isEqualTo: widget.userUid),
            Filter('receiverUid', isEqualTo: widget.userUid),
          ),
        )
        .snapshots();
  }

  // Logic to show Settle Up Dialog (Reused/Adapted)
  Future<void> _showSettleUpDialog(
    BuildContext context,
    String myUid,
    String partnerUid,
    double amount,
    bool iAmPayer,
  ) async {
    // Determine if we need to explain who pays whom in the dialog
    // amount is absBalance.
    // iAmPayer means I owe.

    final resultCode = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2621), // Dark bg
        title: Text(
          AppLocalizations.of(context)!.settleUpTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          AppLocalizations.of(
            context,
          )!.sendRequestDialogContent(amount.toStringAsFixed(2), "₺"),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ChangeNotifierProvider(
            create: (_) => SettlementViewModel(),
            child: Consumer<SettlementViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return TextButton(
                  onPressed: () async {
                    final result = await viewModel.requestSettlement(
                      senderUid: myUid,
                      receiverUid: partnerUid,
                      amount: amount,
                      currency: '₺',
                    );

                    if (context.mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          Navigator.pop(context, result);
                        }
                      });
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.sendRequest,
                    style: const TextStyle(
                      color: AppTheme.emeraldPrimary,
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

    if (resultCode != null && context.mounted) {
      if (resultCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.requestSentSuccess),
          ),
        );
      } else if (resultCode == 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pendingRequestExists),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.requestSendFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no partner, show link screen link (reuse logic or simplify)
    if (widget.partnerUid == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.noPartnerLinked,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
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

    return StreamBuilder<QuerySnapshot>(
      stream: _transactionStream,
      builder: (context, txSnap) {
        if (!txSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = txSnap.data!.docs;
        double mySpends = 0;
        double partnerSpends = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isSettled'] == true) continue;
          if (data['isDeleted'] == true) continue;

          final sender = data['senderUid'];
          final receiver = data['receiverUid'];
          final amount = (data['amount'] ?? 0).toDouble();

          if (sender == widget.userUid && receiver == widget.partnerUid) {
            mySpends += amount;
          } else if (sender == widget.partnerUid &&
              receiver == widget.userUid) {
            partnerSpends += amount;
          }
        }

        final netBalance = mySpends - partnerSpends;
        // netBalance > 0: I spent more. Partner owes me.
        // netBalance < 0: Partner spent more. I owe partner.

        return DashboardBalanceCard(
          netBalance: netBalance,
          partnerName: widget.partnerName,
          onSettleUp: () {
            if (netBalance.abs() > 0) {
              _showSettleUpDialog(
                context,
                widget.userUid,
                widget.partnerUid!,
                netBalance.abs(),
                netBalance < 0,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Nothing to settle!")),
              );
            }
          },
          onDetails: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettlementHistoryScreen(
                  myUid: widget.userUid,
                  partnerUid: widget.partnerUid!,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DashboardTransactionList extends StatefulWidget {
  final String userUid;
  final String? partnerUid;
  final String partnerName;
  final int? refreshTrigger;

  const _DashboardTransactionList({
    required this.userUid,
    this.partnerUid,
    this.partnerName = "Partner",
    this.refreshTrigger,
  });

  @override
  State<_DashboardTransactionList> createState() =>
      _DashboardTransactionListState();
}

class _DashboardTransactionListState extends State<_DashboardTransactionList> {
  late Stream<QuerySnapshot> _transactionStream;

  @override
  void initState() {
    super.initState();
    _createStream();
  }

  @override
  void didUpdateWidget(_DashboardTransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userUid != widget.userUid ||
        oldWidget.partnerUid != widget.partnerUid ||
        oldWidget.refreshTrigger != widget.refreshTrigger) {
      _createStream();
    }
  }

  void _createStream() {
    // Limit to let's say 30 first to minimize data if only showing 20,
    // but user wanted 'recent transactions limit to 20'.
    // Firestore limit would be better efficiently.
    _transactionStream = FirebaseFirestore.instance
        .collection('transactions')
        .where(
          Filter.or(
            Filter('senderUid', isEqualTo: widget.userUid),
            Filter('receiverUid', isEqualTo: widget.userUid),
          ),
        )
        .orderBy('timestamp', descending: true)
        // .limit(20) // REMOVED: limit(20) here causes issues if the top 20 are settled/deleted.
        // We will limit the display count instead.
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.partnerUid == null) {
      return const SizedBox();
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentTransactions,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllTransactionsScreen(
                        userUid: widget.userUid,
                        partnerUid: widget.partnerUid!,
                        partnerName: widget.partnerName,
                      ),
                    ),
                  );
                },
                child: Text(
                  "See All", // Could move to localizations
                  style: TextStyle(
                    color: AppTheme.emeraldPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
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
              final allDocs = snapshot.data?.docs ?? [];

              // Filter logic
              final docs = allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                if (data['isDeleted'] == true || data['isSettled'] == true) {
                  return false;
                }

                final sender = data['senderUid'];
                final receiver = data['receiverUid'];
                return sender == widget.partnerUid ||
                    receiver == widget.partnerUid;
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.noTransactionsYet,
                    style: const TextStyle(color: Colors.white54),
                  ),
                );
              }

              // Apply limit here
              final displayCount = docs.length > 20 ? 20 : docs.length;

              return ListView.builder(
                padding: const EdgeInsets.only(
                  bottom: 100,
                ), // Space for FAB/BottomBar
                itemCount: displayCount,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final tx = TransactionModel.fromMap(data, docs[index].id);

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
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
