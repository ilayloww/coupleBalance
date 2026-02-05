import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:couple_balance/config/theme.dart';
import 'package:couple_balance/models/transaction_model.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:couple_balance/services/settlement_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Dashboard Header ---
class DashboardHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;

  const DashboardHeader({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.onProfileTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine greeting
    final hour = DateTime.now().hour;
    String greeting = "";
    if (hour >= 5 && hour < 12) {
      greeting = AppLocalizations.of(context)!.goodMorning;
    } else if (hour >= 12 && hour < 17) {
      greeting = AppLocalizations.of(context)!.goodAfternoon;
    } else if (hour >= 17 && hour < 21) {
      greeting = AppLocalizations.of(context)!.goodEvening;
    } else {
      greeting = AppLocalizations.of(context)!.goodNight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.emeraldPrimary,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      backgroundImage: photoUrl != null
                          ? CachedNetworkImageProvider(photoUrl!)
                          : null,
                      child: photoUrl == null
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dashboard",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "$greeting, ${displayName.split(' ').first}",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onNotificationTap,
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Dashboard Balance Card ---
class DashboardBalanceCard extends StatelessWidget {
  final double netBalance; // + means partner owes me, - means I owe partner
  final VoidCallback onSettleUp;
  final VoidCallback onDetails;
  final String partnerName;

  const DashboardBalanceCard({
    super.key,
    required this.netBalance,
    required this.onSettleUp,
    required this.onDetails,
    this.partnerName = "Partner",
  });

  @override
  Widget build(BuildContext context) {
    final absBalance = netBalance.abs();
    final isPositive =
        netBalance >=
        0; // true if partner owes me (Green), false if I owe (Warning/Red?)

    // Logic from previous code:
    // isPositive = (mySpends - partnerSpends) >= 0;
    // If > 0: Partner owes ME.
    // If < 0: I owe Partner.

    // Let's use '₺' for consistency with previous files.

    final formattedBalance = "${absBalance.toStringAsFixed(2)} ₺";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C3E50), // Dark Blue-Grey
            const Color(0xFF000000).withValues(alpha: 0.8), // Blackish
            // Trying to mimic the screenshot's dark abstract vibe with maybe a hint of color
            // Screenshot has some yellow/blue blobs.
            // Let's stick to a clean Dark Card for now, maybe with a subtle image if possible.
            // Or use a rich dark gradient.
          ],
        ),
        image: DecorationImage(
          image: const NetworkImage(
            "https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=2670&auto=format&fit=crop",
          ),
          fit: BoxFit.cover,
          opacity: 0.6,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.4),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TOTAL BALANCE",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.call_received : Icons.arrow_outward,
                color: AppTheme.emeraldPrimary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isPositive
                    ? "You are owed $formattedBalance"
                    : "You owe $partnerName $formattedBalance",
                style: const TextStyle(
                  color: AppTheme.emeraldPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onSettleUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldPrimary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.settleUp,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.details,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Transaction Tile ---
class DashboardTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String currentUserId;
  final String partnerName;
  final EdgeInsetsGeometry? margin;

  const DashboardTransactionTile({
    super.key,
    required this.transaction,
    required this.currentUserId,
    this.partnerName = "Partner",
    this.margin,
  });

  IconData _getIconForNote(String note, String? category) {
    // 1. Try Category First
    if (category != null && category.isNotEmpty) {
      switch (category) {
        case 'food':
          return Icons.restaurant;
        case 'coffee':
          return Icons.coffee;
        case 'rent':
          return Icons.home;
        case 'groceries':
          return Icons.shopping_cart;
        case 'transport':
          return Icons.directions_car;
        case 'date':
          return Icons.favorite;
        case 'bills':
          return Icons.receipt_long;
        case 'shopping':
          return Icons.shopping_bag;
        case 'custom':
          return Icons.edit;
        default:
          // Fallback to text matching if unknown category ID
          break;
      }
    }

    // 2. Fallback to Note Matching (Old Logic)
    final lowerNote = note.toLowerCase();
    if (lowerNote.contains("grocery") ||
        lowerNote.contains("market") ||
        lowerNote.contains("food")) {
      return Icons.shopping_cart;
    } else if (lowerNote.contains("gas") || lowerNote.contains("fuel")) {
      return Icons.local_gas_station;
    } else if (lowerNote.contains("dinner") ||
        lowerNote.contains("lunch") ||
        lowerNote.contains("restaurant")) {
      return Icons.restaurant;
    } else if (lowerNote.contains("movie") || lowerNote.contains("cinema")) {
      return Icons.movie;
    } else if (lowerNote.contains("rent") || lowerNote.contains("home")) {
      return Icons.home;
    } else if (lowerNote.contains("bill") ||
        lowerNote.contains("wifi") ||
        lowerNote.contains("electric")) {
      return Icons.receipt_long;
    }
    return Icons.receipt; // Default
  }

  Color _getIconColor(String note) {
    // Return a color based on category/icon potentially?
    // For now, let's keep it consistent 'Emerald' or varied.
    // Screenshot shows green icons.
    return AppTheme.emeraldPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final isMe = transaction.senderUid == currentUserId;
    final amount = transaction.amount;
    final currency = transaction.currency;
    final date = DateFormat('MMM d').format(transaction.timestamp);

    // If I paid, subtitle: "You paid $amount"
    // If partner paid, subtitle: "Partner paid $amount"

    final subtitle = isMe
        ? "You paid ${amount.toStringAsFixed(2)} $currency"
        : "$partnerName paid ${amount.toStringAsFixed(2)} $currency";

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2621), // Dark Green/Grey card bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForNote(transaction.note, transaction.category),
              color: _getIconColor(transaction.note),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note.isNotEmpty
                      ? transaction.note
                      : "Transaction",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${amount.toStringAsFixed(2)} $currency",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Swipeable Transaction Tile ---
class SwipeableTransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String currentUserId;
  final String partnerName;

  const SwipeableTransactionTile({
    super.key,
    required this.transaction,
    required this.currentUserId,
    this.partnerName = "Partner",
  });

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2621),
        title: Text(
          AppLocalizations.of(context)!.deleteTransactionTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteTransactionContent,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(transaction.id)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Transaction deleted")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Delete Error: $e")));
        }
      }
    }
  }

  Future<void> _handleSettleUp(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final amount = transaction.amount;
    final currency = transaction.currency;

    final shouldSettle = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2621),
        title: Text(l10n.settleUp, style: const TextStyle(color: Colors.white)),
        content: Text(
          "Do you want to settle this transaction of ${amount.toStringAsFixed(2)} $currency?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emeraldPrimary,
            ),
            child: Text(l10n.sendRequest),
          ),
        ],
      ),
    );

    if (shouldSettle == true) {
      try {
        final settlementService = SettlementService();
        String partnerUid = "";
        if (transaction.senderUid == currentUserId) {
          partnerUid = transaction.receiverUid;
        } else {
          partnerUid = transaction.senderUid;
        }

        if (partnerUid.isEmpty || partnerUid == currentUserId) {
          partnerUid = transaction.senderUid == currentUserId
              ? transaction.receiverUid
              : transaction.senderUid;
        }

        await settlementService.requestSettlement(
          senderUid: currentUserId,
          receiverUid: partnerUid,
          amount: amount,
          currency: currency,
          transactionId: transaction.id,
        );

        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(l10n.requestSentSuccess),
              backgroundColor: AppTheme.emeraldPrimary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                "Error: ${e.toString().replaceAll('Exception:', '')}",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Slidable(
        key: Key(transaction.id),
        // Left swipe reveals Settle Up button
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.28,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomSlidableAction(
                  onPressed: (ctx) => _handleSettleUp(context),
                  backgroundColor: AppTheme.emeraldPrimary,
                  foregroundColor: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  padding: EdgeInsets.zero,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 24),
                      SizedBox(height: 4),
                      Text(
                        "Settle",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Right swipe reveals Delete button
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.28,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CustomSlidableAction(
                  onPressed: (ctx) => _handleDelete(context),
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  padding: EdgeInsets.zero,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete, size: 24),
                      SizedBox(height: 4),
                      Text(
                        "Delete",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        child: DashboardTransactionTile(
          transaction: transaction,
          currentUserId: currentUserId,
          partnerName: partnerName,
          margin: EdgeInsets.zero,
        ),
      ),
    );
  }
}
