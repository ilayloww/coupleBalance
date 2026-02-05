import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../viewmodels/settlement_viewmodel.dart';
import '../models/settlement_model.dart';
import '../models/transaction_model.dart';
import '../config/theme.dart';

enum SettlementFilter { allTime, thisYear, lastYear }

class SettlementHistoryScreen extends StatefulWidget {
  final String myUid;
  final String partnerUid;

  const SettlementHistoryScreen({
    super.key,
    required this.myUid,
    required this.partnerUid,
  });

  @override
  State<SettlementHistoryScreen> createState() =>
      _SettlementHistoryScreenState();
}

class _SettlementHistoryScreenState extends State<SettlementHistoryScreen> {
  SettlementFilter _selectedFilter = SettlementFilter.allTime;

  List<SettlementModel> _filterSettlements(List<SettlementModel> settlements) {
    if (settlements.isEmpty) return [];

    final now = DateTime.now();
    switch (_selectedFilter) {
      case SettlementFilter.allTime:
        return settlements;
      case SettlementFilter.thisYear:
        return settlements.where((s) => s.timestamp.year == now.year).toList();
      case SettlementFilter.lastYear:
        return settlements
            .where((s) => s.timestamp.year == now.year - 1)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Map filters to localized text
    final Map<SettlementFilter, String> filterLabels = {
      SettlementFilter.allTime: l10n.filterAllTime,
      SettlementFilter.thisYear: l10n.filterThisYear,
      SettlementFilter.lastYear: l10n.filterLastYear,
    };

    return ChangeNotifierProvider(
      create: (_) => SettlementViewModel(),
      child: Scaffold(
        backgroundColor: Colors.black, // Dark background as per screenshot
        appBar: AppBar(
          title: Text(
            l10n.settlementHistory,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: SettlementFilter.values.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        filterLabels[filter]!,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        }
                      },
                      selectedColor: const Color(0xFF00FF80), // Neon Green
                      backgroundColor: const Color(0xFF1F382E), // Dark Green
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      showCheckmark: false,
                      avatar: isSelected
                          ? const Icon(
                              Icons.calendar_today,
                              color: Colors.black,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Header "Past Settlements"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Past Settlements", // Could localize if key exists, else leave as English/Hardcoded based on arb check
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: Consumer<SettlementViewModel>(
                builder: (context, viewModel, child) {
                  return StreamBuilder<List<SettlementModel>>(
                    stream: viewModel.getSettlementHistory(
                      widget.myUid,
                      widget.partnerUid,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            l10n.errorLoadingHistory,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allSettlements = snapshot.data ?? [];
                      final settlements = _filterSettlements(allSettlements);

                      if (settlements.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.noPastSettlements,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: settlements.length,
                        itemBuilder: (context, index) {
                          return ExpandableSettlementCard(
                            settlement: settlements[index],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableSettlementCard extends StatefulWidget {
  final SettlementModel settlement;

  const ExpandableSettlementCard({super.key, required this.settlement});

  @override
  State<ExpandableSettlementCard> createState() =>
      _ExpandableSettlementCardState();
}

class _ExpandableSettlementCardState extends State<ExpandableSettlementCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  List<TransactionModel> _transactions = [];

  IconData _getIcon(TransactionModel tx) {
    if (tx.category != null && tx.category!.isNotEmpty) {
      switch (tx.category!.toLowerCase()) {
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
          break;
      }
    }

    final lowerNote = tx.note.toLowerCase();
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
    return Icons.receipt;
  }

  Future<void> _toggleExpand() async {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
    } else {
      setState(() {
        _isExpanded = true;
      });
      if (_transactions.isEmpty) {
        await _fetchTransactions();
      }
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = Provider.of<SettlementViewModel>(
        context,
        listen: false,
      );
      final txs = await viewModel.fetchTransactions(
        widget.settlement.transactionIds,
      );
      if (mounted) {
        setState(() {
          _transactions = txs;
        });
      }
    } catch (e) {
      debugPrint("Error fetching settlement transactions: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settlement = widget.settlement;

    final startFormat = DateFormat('MMM d').format(settlement.startDate);
    final endFormat = DateFormat('MMM d, yyyy').format(settlement.endDate);
    final dateRange =
        "${startFormat.toUpperCase()} - ${endFormat.toUpperCase()}";
    final count = settlement.transactionIds.length;

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16201D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date Range and (Count + Arrow)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateRange,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "$count ${l10n.items}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom Row: Amount + Status
            Row(
              children: [
                Text(
                  "\$${settlement.totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Matches screenshot 'Big' look
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A2F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.emeraldPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    l10n.settled,
                    style: const TextStyle(
                      color: AppTheme.emeraldPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Expanded List Section
            if (_isExpanded) ...[
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_transactions.isEmpty)
                Center(
                  child: Text(
                    "No details available",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _getIcon(tx),
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.note.isEmpty ? "Transaction" : tx.note,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM d, h:mm a',
                                  ).format(tx.timestamp),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${tx.amount.toStringAsFixed(2)} ${tx.currency}",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
