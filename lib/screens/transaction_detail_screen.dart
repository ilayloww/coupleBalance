import 'package:flutter/material.dart';
import 'package:couple_balance/utils/date_time_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodels/settlement_viewmodel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  final String currentUserId;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.currentUserId,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _noteController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.transaction.note);
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_noteController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      return;
    }

    final newAmount = double.tryParse(_amountController.text.trim());
    if (newAmount == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transaction.id)
          .update({'note': _noteController.text.trim(), 'amount': newAmount});

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating: $e')));
      }
    }
  }

  Future<void> _onSettleUp() async {
    final partnerUid = widget.transaction.senderUid == widget.currentUserId
        ? widget.transaction.receiverUid
        : widget.transaction.senderUid;

    final viewModel = context.read<SettlementViewModel>();
    final result = await viewModel.requestSingleTransactionSettlement(
      myUid: widget.currentUserId,
      partnerUid: partnerUid,
      transactionId: widget.transaction.id,
      amount: widget.transaction.amount,
      iAmPayer: widget.transaction.senderUid != widget.currentUserId,
    );

    if (!mounted) return;

    if (result == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.requestSentSuccess),
        ),
      );
    } else if (result == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pendingRequestExists),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send request')));
    }
  }

  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTransactionTitle),
        content: Text(AppLocalizations.of(context)!.deleteTransactionContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(widget.transaction.id)
            .delete();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        }
      }
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
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
        return Icons.receipt;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  String _getCategoryLabel(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'food':
        return l10n.tagFood;
      case 'coffee':
        return l10n.tagCoffee;
      case 'rent':
        return l10n.tagRent;
      case 'groceries':
        return l10n.tagGroceries;
      case 'transport':
        return l10n.tagTransport;
      case 'date':
        return l10n.tagDate;
      case 'bills':
        return l10n.tagBills;
      case 'shopping':
        return l10n.tagShopping;
      case 'custom':
        return l10n.tagCustom;
      default:
        return id; // Or map custom category names if stored differently
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.transaction.senderUid == widget.currentUserId;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // determine partner
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUserModel;
    final partnerId = isMe
        ? widget.transaction.receiverUid
        : widget.transaction.senderUid;
    // Try to find partner in loaded partners
    final partnerUser = authService.partners.firstWhere(
      (p) => p.uid == partnerId,
      orElse: () => UserModel(uid: partnerId, displayName: 'Partner'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.details), // "Transaction Details"
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: Text(
              _isEditing
                  ? 'Save'
                  : l10n.editProfile, // Using editProfile as it maps to "Edit"
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Top Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ), // Green tint
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getCategoryIcon(widget.transaction.category ?? 'others'),
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount and Title
            Center(
              child: Column(
                children: [
                  if (_isEditing)
                    TextFormField(
                      controller: _noteController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Enter note',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    Text(
                      widget.transaction.note,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMe ? '+' : '-',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isMe
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextFormField(
                            controller: _amountController,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isMe
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              border: const UnderlineInputBorder(),
                              suffixText: widget.transaction.currency,
                              suffixStyle: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: isMe
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${isMe ? '+' : '-'}${widget.transaction.amount.toStringAsFixed(2)} ${widget.transaction.currency}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isMe
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Paid By Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMe
                        ? l10n.paidByYou
                        : l10n.paidByPartner(partnerUser.displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    Icons.calendar_today,
                    l10n.date,
                    DateFormat(
                      'MMM d, yyyy',
                    ).format(widget.transaction.timestamp),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    context,
                    Icons.access_time,
                    l10n.time,
                    DateTimeUtils.formatTime(
                      context,
                      widget.transaction.timestamp,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    context,
                    Icons.category,
                    l10n.category,
                    _getCategoryLabel(
                      context,
                      widget.transaction.category ?? 'others',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    context,
                    widget.transaction.isSettled
                        ? Icons.check_circle_outline
                        : Icons.pending_outlined,
                    l10n.status,
                    widget.transaction.isSettled
                        ? l10n.settled
                        : l10n.unsettled,
                    valueColor: widget.transaction.isSettled
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Split Details Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.splitDetails,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Split Details Cards
            // Split Details Cards
            // Calculate respective shares
            // If totalAmount is available, PayerShare = Total - Debt. DebtorShare = Debt.
            // Fallback (Legacy): Assume Amount is 50% split -> PayerShare = Amount, DebtorShare = Amount.
            // Logic:
            // Payer Amount to show = (transaction.totalAmount != null)
            //    ? (transaction.totalAmount! - transaction.amount)
            //    : transaction.amount;
            // Debtor Amount to show = transaction.amount;
            _buildSplitCard(
              context,
              user: isMe ? currentUser : partnerUser,
              description: isMe
                  ? l10n.paidByYou
                  : l10n.paidByPartner(
                      partnerUser.displayName,
                    ), // Corrected description logic
              amount: widget.transaction.totalAmount != null
                  ? (widget.transaction.totalAmount! - // Show 'My Share' (Cost)
                        widget.transaction.amount) // Debt
                  : widget.transaction.amount, // Fallback
              currency: widget.transaction.currency,
              isPayer: true,
            ),
            const SizedBox(height: 12),
            _buildSplitCard(
              context,
              user: isMe ? partnerUser : currentUser!,
              description: isMe
                  ? l10n.owesYou
                  : l10n.owePartner(
                      partnerUser.displayName,
                    ), // Corrected description logic
              amount: widget.transaction.amount, // Debt is always Debt
              currency: widget.transaction.currency,
              isPayer: false,
            ),

            const SizedBox(height: 24),

            // Receipt Header
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.receipt,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Receipt Image
            if (widget.transaction.photoUrl != null &&
                widget.transaction.photoUrl!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      barrierColor: Colors.black,
                      pageBuilder: (BuildContext context, _, _) {
                        return _FullScreenImageView(
                          photoUrl: widget.transaction.photoUrl!,
                          heroTag: 'tx_photo_${widget.transaction.id}',
                        );
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const curve = Curves.easeOutCubic;
                            final tween = Tween(
                              begin: 0.0,
                              end: 1.0,
                            ).chain(CurveTween(curve: curve));
                            return ScaleTransition(
                              scale: animation.drive(tween),
                              child: child,
                            );
                          },
                    ),
                  );
                },
                child: Hero(
                  tag: 'tx_photo_${widget.transaction.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.transaction.photoUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noReceiptPhoto,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Action Buttons
            if (!widget.transaction.isSettled) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSettleUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.settleUp,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.deleteTransactionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitCard(
    BuildContext context, {
    required UserModel? user,
    required String description,
    required double amount,
    required String currency,
    required bool isPayer,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCurrentUser = user?.uid == widget.currentUserId;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(user.photoUrl!)
                : null,
            child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                ? Text(
                    user?.displayName.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCurrentUser ? l10n.you : (user?.displayName ?? l10n.partner),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount.toStringAsFixed(2)} $currency',
                style: TextStyle(
                  color: isPayer ? theme.colorScheme.primary : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ], // Closing children of Column
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageView extends StatelessWidget {
  final String photoUrl;
  final String heroTag;

  const _FullScreenImageView({required this.photoUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
