import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:couple_balance/l10n/app_localizations.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirmationController = TextEditingController();
  bool _isLoading = false;
  bool _isDeleteEnabled = false;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  void _onConfirmationChanged(String value) {
    final keyword = AppLocalizations.of(context)!.deleteConfirmationKeyword;
    setState(() {
      _isDeleteEnabled = value.trim() == keyword;
    });
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.accountDeleted)),
        );
        Navigator.of(
          context,
        ).popUntil((route) => route.isFirst); // Back to Auth Wrapper
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Using a specific dark background color to match the screenshot's moody look
    // or fallback to the theme's background.
    // The screenshot has a very dark background, potentially darker than standard theme.
    // But let's stick to theme background for consistency unless it looks bad.
    // However, the screenshot shows a very dark brownish/reddish tint at the top?
    // No, it seems like a solid dark color with maybe some ambient light.
    // Let's use the theme scaffold background.

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Warning Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 48,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                l10n.areYouSure,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                l10n.deleteAccountDescription,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Confirmation Input Label
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    children: [
                      TextSpan(
                        text: l10n.typeDeleteToConfirm.replaceAll(
                          l10n.deleteConfirmationKeyword,
                          '',
                        ),
                      ), // This might be tricky with "type DELETE below" structure.
                      // Let's just use the localized string directly but try to highlight "DELETE" if possible?
                      // For simplicity and robustness with different languages, we'll just display the full string
                      // and highlight the keyword if we can split it, but simple text is safer.
                      // Or better:
                      TextSpan(
                        text: l10n.typeDeleteToConfirm.split(
                          l10n.deleteConfirmationKeyword,
                        )[0],
                      ),
                      TextSpan(
                        text: l10n.deleteConfirmationKeyword,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (l10n.typeDeleteToConfirm.contains(
                            l10n.deleteConfirmationKeyword,
                          ) &&
                          l10n.typeDeleteToConfirm
                                  .split(l10n.deleteConfirmationKeyword)
                                  .length >
                              1)
                        TextSpan(
                          text: l10n.typeDeleteToConfirm.split(
                            l10n.deleteConfirmationKeyword,
                          )[1],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Input Field
              TextField(
                controller: _confirmationController,
                onChanged: _onConfirmationChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: l10n.deleteConfirmationKeyword,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: const Color(
                    0xFF2C1B1B,
                  ), // Dark reddish brown background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.partnerNotifiedInfo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 80,
              ), // Spacer pushes buttons down appropriately
              // Delete Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isDeleteEnabled && !_isLoading
                      ? _deleteAccount
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914), // Netflix Red-ish
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFFE50914,
                    ).withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.3,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.deleteMyAccount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Go Back Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.goBack,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
