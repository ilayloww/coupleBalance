import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../viewmodels/settlement_viewmodel.dart';
import '../models/settlement_model.dart';

class SettlementHistoryScreen extends StatelessWidget {
  final String myUid;
  final String partnerUid;

  const SettlementHistoryScreen({
    super.key,
    required this.myUid,
    required this.partnerUid,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettlementViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settlementHistory),
          elevation: 0,
        ),
        body: Consumer<SettlementViewModel>(
          builder: (context, viewModel, child) {
            return StreamBuilder<List<SettlementModel>>(
              stream: viewModel.getSettlementHistory(myUid, partnerUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('SettlementHistory Error: ${snapshot.error}');
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.errorLoadingHistory,
                    ),
                  );
                }

                final settlements = snapshot.data ?? [];

                if (settlements.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noPastSettlements,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: settlements.length,
                  itemBuilder: (context, index) {
                    final settlement = settlements[index];
                    final isPayer = settlement.payerUid == myUid;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(settlement.timestamp),
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.settled,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isPayer
                                      ? Theme.of(context).colorScheme.secondary
                                            .withValues(alpha: 0.1)
                                      : Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.1),
                                  child: Icon(
                                    isPayer
                                        ? Icons.arrow_outward
                                        : Icons.arrow_downward,
                                    color: isPayer
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPayer
                                          ? AppLocalizations.of(
                                              context,
                                            )!.youPaidPartner
                                          : AppLocalizations.of(
                                              context,
                                            )!.partnerPaidYou,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.transactionCount(
                                        settlement.transactionIds.length,
                                      ),
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  '${settlement.totalAmount.toStringAsFixed(2)} ₺',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
