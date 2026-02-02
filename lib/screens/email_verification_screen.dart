import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../config/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

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
        // Success logic here
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

  Future<void> _openEmailApp() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      const intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.APP_EMAIL',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      try {
        await intent.launch();
      } catch (e) {
        if (mounted) {
          // Fallback to mailto if intent fails
          final Uri mailtoUri = Uri(scheme: 'mailto');
          try {
            await launchUrl(mailtoUri);
          } catch (e2) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open email app: $e')),
              );
            }
          }
        }
      }
      return;
    }

    // iOS and others
    final Uri emailLaunchUri = Uri(
      scheme: 'message', // Try message:// first for iOS mail app
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // Fallback to mailto
        final Uri mailtoUri = Uri(scheme: 'mailto');
        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open default email app.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening email app: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final email = authService.currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: const Color(0xFF05100A), // Deep Dark Green/Black
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.emailVerification,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            authService.signOut();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Placeholder (simulating the 3D envelope lock)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.mark_email_read,
                  size: 80,
                  color: AppTheme.emeraldPrimary,
                ),
              ),
              const SizedBox(height: 40),

              // Title
              Text(
                "Check your inbox",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "We've sent a magic link to \n"),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(
                      text:
                          ".\nClick the link in your email to sign in automatically.",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Feedback Message Area
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.emeraldPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.emeraldPrimary),
                  ),
                ),

              const SizedBox(height: 32),

              // Open Email App Button
              CustomButton(text: "Open Email App", onPressed: _openEmailApp),

              const Spacer(),

              // Resend Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the link? ",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _resendVerificationEmail,
                    child: Text(
                      AppLocalizations.of(context)!.resendVerificationEmail,
                      style: const TextStyle(
                        color: AppTheme.emeraldPrimary, // Green text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Verify Check (Manual)
              TextButton(
                onPressed: _isLoading ? null : _checkVerification,
                child: Text(
                  "I have verified",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
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
