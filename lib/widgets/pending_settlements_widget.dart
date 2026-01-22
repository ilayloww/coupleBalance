import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settlement_request_model.dart';
import '../services/settlement_service.dart';
import '../screens/settlement_confirmation_screen.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../viewmodels/settlement_viewmodel.dart';
import '../models/transaction_model.dart';

class PendingSettlementsWidget extends StatefulWidget {
  final String myUid;
  final String? partnerUid;

  const PendingSettlementsWidget({
    super.key,
    required this.myUid,
    this.partnerUid,
  });

  @override
  State<PendingSettlementsWidget> createState() =>
      _PendingSettlementsWidgetState();
}

class _PendingSettlementsWidgetState extends State<PendingSettlementsWidget> {
  late Stream<List<SettlementRequest>> _requestsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(PendingSettlementsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.myUid != widget.myUid) {
      _initStream();
    }
  }

  void _initStream() {
    _requestsStream = SettlementService().getIncomingRequests(widget.myUid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SettlementRequest>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final requests = snapshot.data!.where((req) {
          // Hide Completed/Rejected requests if any slip through, usually service handles this
          if (req.status != SettlementRequest.statusPending) return false;

          if (widget.partnerUid == null) return true;
          return req.senderUid == widget.partnerUid;
        }).toList();

        if (requests.isEmpty) return const SizedBox.shrink();

        return Column(
          children: requests.map((request) {
            return _PendingRequestItem(request: request);
          }).toList(),
        );
      },
    );
  }
}

class _PendingRequestItem extends StatelessWidget {
  final SettlementRequest request;
  const _PendingRequestItem({required this.request});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SettlementViewModel>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.notifications_active, color: Colors.white),
        ),
        title: Text(
          AppLocalizations.of(context)!.settlementRequestTitle,
          style: TextStyle(
            color: Colors.orange.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: request.transactionId == null
            ? Text(
                "${AppLocalizations.of(context)!.partnerWantsToSettleUp}: ${request.amount.toStringAsFixed(2)} ${request.currency}",
                style: TextStyle(color: Colors.orange.shade800),
              )
            : FutureBuilder<TransactionModel?>(
                future: viewModel.fetchTransaction(request.transactionId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      "${AppLocalizations.of(context)!.waitingFor}...",
                      style: TextStyle(color: Colors.orange.shade800),
                    );
                  }
                  final txName = snapshot.data?.note ?? "Transaction";
                  return Text(
                    "${AppLocalizations.of(context)!.partnerWantsToSettleUp}: $txName (${request.amount.toStringAsFixed(2)} ${request.currency})",
                    style: TextStyle(color: Colors.orange.shade800),
                  );
                },
              ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SettlementConfirmationScreen(requestId: request.id),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: Text(AppLocalizations.of(context)!.details),
        ),
      ),
    );
  }
}
