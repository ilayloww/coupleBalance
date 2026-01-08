import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/transaction_model.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;
  final String currentUserId;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = transaction.senderUid == currentUserId;
    final formattedDate = DateFormat(
      'EEEE, MMMM d, yyyy • h:mm a',
    ).format(transaction.timestamp);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.details,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt Photo Section
            if (transaction.photoUrl != null &&
                transaction.photoUrl!.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      barrierColor: Colors.black,
                      pageBuilder: (BuildContext context, _, _) {
                        return _FullScreenImageView(
                          photoUrl: transaction.photoUrl!,
                          heroTag: 'tx_photo_${transaction.id}',
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
                  tag: 'tx_photo_${transaction.id}',
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    width: double.infinity,
                    child: Builder(
                      builder: (context) {
                        return CachedNetworkImage(
                          imageUrl: transaction.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[100],
                            child: const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 150,
                color: Colors.grey[50],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.noReceiptPhoto,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount and Title
                  Center(
                    child: Column(
                      children: [
                        Text(
                          transaction.note,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${isMe ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isMe ? Colors.pink : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.pink[50] : Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isMe
                                ? AppLocalizations.of(context)!.youPaid
                                : AppLocalizations.of(context)!.partnerPaid,
                            style: TextStyle(
                              color: isMe ? Colors.pink : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Metadata
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: AppLocalizations.of(context)!.date,
                    value: formattedDate,
                  ),
                  const SizedBox(height: 16),

                  if (transaction.isSettled)
                    _DetailRow(
                      icon: Icons.check_circle,
                      label: AppLocalizations.of(context)!.status,
                      value: AppLocalizations.of(context)!.settled,
                      valueColor: Colors.green,
                    )
                  else
                    _DetailRow(
                      icon: Icons.pending,
                      label: AppLocalizations.of(context)!.status,
                      value: AppLocalizations.of(context)!.unsettled,
                      valueColor: Colors.orange,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: valueColor ?? Colors.black87,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
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
