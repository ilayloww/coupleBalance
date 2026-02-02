import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:couple_balance/config/theme.dart';
import 'package:couple_balance/models/transaction_model.dart';
import 'package:couple_balance/l10n/app_localizations.dart';

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
                isPositive ? Icons.arrow_outward : Icons.call_received,
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

  const DashboardTransactionTile({
    super.key,
    required this.transaction,
    required this.currentUserId,
    this.partnerName = "Partner",
  });

  IconData _getIconForNote(String note) {
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
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
              _getIconForNote(transaction.note),
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
