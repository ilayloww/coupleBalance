import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
          title: const Text(
            'Settlement History',
            style: TextStyle(color: Colors.black),
          ),
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.grey[50],
        body: Consumer<SettlementViewModel>(
          builder: (context, viewModel, child) {
            return StreamBuilder<List<SettlementModel>>(
              stream: viewModel.getSettlementHistory(myUid, partnerUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading history'));
                }

                final settlements = snapshot.data ?? [];

                if (settlements.isEmpty) {
                  return const Center(
                    child: Text(
                      'No past settlements',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
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
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Settled',
                                    style: TextStyle(
                                      color: Colors.green[700],
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
                                      ? Colors.blue[50]
                                      : Colors.pink[50],
                                  child: Icon(
                                    isPayer
                                        ? Icons.arrow_outward
                                        : Icons.arrow_downward,
                                    color: isPayer ? Colors.blue : Colors.pink,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPayer
                                          ? 'You paid Partner'
                                          : 'Partner paid You',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${settlement.transactionIds.length} transactions',
                                      style: TextStyle(
                                        color: Colors.grey[600],
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
