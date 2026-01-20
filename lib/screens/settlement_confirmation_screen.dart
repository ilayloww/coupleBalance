import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../models/settlement_request_model.dart';
import '../viewmodels/settlement_viewmodel.dart';

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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequest();
  }

  Future<void> _fetchRequest() async {
    // We use the viewmodel to fetch data.
    // Ideally we should use a provider if available, or just create a local instance/listen to one.
    // For simplicity, we can fetch it once.
    try {
      final viewModel = Provider.of<SettlementViewModel>(
        context,
        listen: false,
      );

      debugPrint("Fetching request with ID: ${widget.requestId}");

      final request = await viewModel
          .fetchSettlementRequest(widget.requestId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint("Fetch request timed out.");
              return null;
            },
          );

      debugPrint("Fetch result: ${request?.toString() ?? 'NULL'}");

      if (mounted) {
        if (request == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = AppLocalizations.of(context)!.requestNotFound;
          });
        } else {
          setState(() {
            _request = request;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error in _fetchRequest: $e");
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
          backgroundColor: confirm ? Colors.green : Colors.red,
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
    // If we're loading or failed
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    // Check status
    if (_request!.status != SettlementRequest.statusPending) {
      return Scaffold(
        appBar: AppBar(title: const Text("Settlement")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(
                  context,
                )!.requestAlreadyStatus(_request!.status),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: Text(AppLocalizations.of(context)!.goHome),
              ),
            ],
          ),
        ),
      );
    }

    final amount = _request?.amount.toStringAsFixed(2) ?? "0.00";
    final currency = _request?.currency ?? "₺";

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settlementRequestTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            const Icon(
              Icons.monetization_on_outlined,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.partnerWantsToSettleUp,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              "$amount $currency",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.settlementConfirmationDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.reject,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.confirm,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
