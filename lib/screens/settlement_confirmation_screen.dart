import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../models/settlement_request_model.dart';
import '../models/transaction_model.dart';
import '../viewmodels/settlement_viewmodel.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementConfirmationScreen extends StatefulWidget {
  final String requestId;

  const SettlementConfirmationScreen({super.key, required this.requestId});

  @override
  State<SettlementConfirmationScreen> createState() =>
      _SettlementConfirmationScreenState();
}

class _SettlementConfirmationScreenState
    extends State<SettlementConfirmationScreen> {
  SettlementRequest? _request;
  TransactionModel? _transaction;
  bool _isLoading = true;
  String? _errorMessage;

  // Summary Data
  int _itemCount = 0;
  DateTime? _minDate;
  DateTime? _maxDate;
  String _directionText = "";

  @override
  void initState() {
    super.initState();
    _fetchRequest();
  }

  Future<void> _fetchRequest() async {
    try {
      final viewModel = Provider.of<SettlementViewModel>(
        context,
        listen: false,
      );
      final authService = Provider.of<AuthService>(context, listen: false);
      final myUid = authService.currentUser!.uid;

      // Get partner name safely
      String partnerName = "Partner";
      if (authService.currentUserModel != null &&
          authService.currentUserModel!.partnerUids.isNotEmpty) {
        // Ideally AuthService has a way to get partner display name easily
        // For now, we iterate partners list if available
        final pId = authService.selectedPartnerId;
        if (pId != null) {
          final p = authService.partners.firstWhere(
            (element) => element.uid == pId,
            orElse: () => authService.partners.isNotEmpty
                ? authService.partners.first
                : authService.currentUserModel!,
          );
          // Fix logic: currentUserModel is not Partner.
          // Just fallback to "Partner" if not found
          if (p.uid != authService.currentUserModel!.uid) {
            partnerName = p.displayName;
          }
        }
      }

      if (kDebugMode) {
        debugPrint('Fetching request with ID: ${widget.requestId}');
      }

      final request = await viewModel
          .fetchSettlementRequest(widget.requestId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              return null;
            },
          );

      if (request == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = AppLocalizations.of(context)!.requestNotFound;
          });
        }
        return;
      }

      // If single transaction
      TransactionModel? transaction;
      if (request.transactionId != null) {
        transaction = await viewModel.fetchTransaction(request.transactionId!);
      }

      // Determine Direction
      // Logic: If request.senderUid is Payer, and I am Payer -> I Pay.
      // But we need to know who is the actual PAYER of the debt.
      // SettlementRequest doesn't explicitly say "senderIsPayer".
      // However, usually "Settle Up" is initiated by the one who Owes?
      // Or simply: Calculate net balance of pending transactions to be sure.

      // Fetch unsettled transactions to calculate stats
      final partnerUid = request.senderUid == myUid
          ? request.receiverUid
          : request.senderUid;

      final unsettledDocs = await viewModel.getUnsettledTransactions(
        myUid,
        partnerUid,
      );

      // Calculate stats
      int count = unsettledDocs.length;
      DateTime? minDate;
      DateTime? maxDate;
      double netBalance = 0; // + means I am Owed, - means I Owe

      for (var doc in unsettledDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['timestamp'] as Timestamp).toDate();
        final amount = (data['amount'] ?? 0).toDouble();
        final sender = data['senderUid'];

        if (minDate == null || date.isBefore(minDate)) minDate = date;
        if (maxDate == null || date.isAfter(maxDate)) maxDate = date;

        if (sender == myUid) {
          netBalance += amount;
        } else {
          netBalance -= amount;
        }
      }

      // If single transaction, override stats
      if (transaction != null) {
        count = 1;
        minDate = transaction.timestamp;
        maxDate = transaction.timestamp;
        // Direction for single tx:
        // If sender is Me -> Partner owes Me.
        // If sender is Partner -> I owe Partner.
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String direction = "";
        if (transaction != null) {
          if (transaction.senderUid == myUid) {
            direction = "$partnerName ${l10n.paysYou}";
          } else {
            direction = "${l10n.youPay} $partnerName";
          }
        } else {
          // Bulk settlement
          // If netBalance > 0, Partner owes Me -> Partner Pays.
          // If netBalance < 0, I owe Partner -> I Pay.
          // We use a small epsilon for float comparison safety
          if (netBalance > 0.01) {
            direction = "$partnerName ${l10n.paysYou}";
          } else {
            direction = "${l10n.youPay} $partnerName";
          }
        }

        setState(() {
          _request = request;
          _transaction = transaction;
          _itemCount = count;
          _minDate = minDate;
          _maxDate = maxDate;
          _directionText = direction;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in _fetchRequest: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error: $e";
        });
      }
    }
  }

  Future<void> _respond(bool confirm) async {
    final viewModel = Provider.of<SettlementViewModel>(context, listen: false);
    final success = await viewModel.respondToSettlementRequest(
      requestId: widget.requestId,
      response: confirm,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirm
                ? AppLocalizations.of(context)!.settlementConfirmed
                : AppLocalizations.of(context)!.settlementRejected,
          ),
          backgroundColor: confirm ? AppTheme.emeraldPrimary : Colors.red,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.genericError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    // Check status
    if (_request!.status != SettlementRequest.statusPending) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settlementRequestTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _request!.status == SettlementRequest.statusAccepted
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 64,
                color: _request!.status == SettlementRequest.statusAccepted
                    ? AppTheme.emeraldPrimary
                    : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.requestAlreadyStatus(_request!.status),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: Text(l10n.goHome),
              ),
            ],
          ),
        ),
      );
    }

    final amountStr = _request?.amount.toStringAsFixed(2) ?? "0.00";
    final currency = _request?.currency ?? "₺";

    // Date Range String
    String dateRange = "";
    if (_minDate != null && _maxDate != null) {
      final f = DateFormat('MMM d');
      if (_minDate!.year == _maxDate!.year &&
          _minDate!.month == _maxDate!.month &&
          _minDate!.day == _maxDate!.day) {
        dateRange = f.format(_minDate!);
      } else {
        dateRange = "${f.format(_minDate!)} - ${f.format(_maxDate!)}";
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.confirmSettlement,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                color: AppTheme.emeraldPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emeraldPrimary.withValues(alpha: 0.05),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sync,
                  color: AppTheme.emeraldPrimary,
                  size: 40,
                ),
              ),

              const SizedBox(height: 32),

              // Direction Title
              Text(
                _directionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Amount
              Text(
                "$currency$amountStr",
                style: const TextStyle(
                  color: AppTheme.emeraldPrimary,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                _transaction != null
                    ? l10n.settleSingleTransactionContent(
                        _transaction?.note ?? 'Transaction',
                      )
                    : l10n.settlementConfirmationDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // Expenses Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.expensesSummary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$dateRange • $_itemCount ${l10n.items}",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldPrimary.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.pending,
                                  style: const TextStyle(
                                    color: AppTheme.emeraldPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.dueToday,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Mini Graph Placeholder
                    Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            AppTheme.emeraldPrimary.withValues(alpha: 0.8),
                            AppTheme.emeraldPrimary.withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bar_chart,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _respond(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldPrimary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.confirmSettlement,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reject Button
              TextButton(
                onPressed: () => _respond(false),
                child: Text(
                  l10n.reject,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
