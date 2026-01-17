import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  String? _message;

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.reloadUser();

      if (!mounted) return;

      if (authService.currentUser?.emailVerified == true) {
        setState(() {
          _message = AppLocalizations.of(context)!.emailVerifiedSuccess;
        });
        // Navigation will be handled by AuthWrapper stream
      } else {
        setState(() {
          _message = AppLocalizations.of(context)!.emailNotVerifiedYet;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendVerificationEmail();
      if (mounted) {
        setState(() {
          _message = AppLocalizations.of(context)!.verificationEmailSent;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e.toString(); // Or localized error
        });
      }
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
    final authService = Provider.of<AuthService>(context);
    final email = authService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.emailVerification),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: Colors.pinkAccent,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.verifyEmailMessage(email),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.checkSpamFolder,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            if (_message != null) ...[
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      _message ==
                          AppLocalizations.of(context)!.emailVerifiedSuccess
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _checkVerification,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context)!.iHaveVerified),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendVerificationEmail,
              child: Text(
                AppLocalizations.of(context)!.resendVerificationEmail,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
