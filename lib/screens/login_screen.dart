import 'package:flutter/material.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../config/theme.dart';
import '../utils/input_sanitizer.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await authService.signInWithEmailAndPassword(email, password);
      } else {
        try {
          await authService.registerWithEmailAndPassword(
            email,
            password,
            InputSanitizer.sanitizeAndTruncate(
              _displayNameController.text,
              100,
            ),
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Try to log in with these credentials transparency
            try {
              await authService.signInWithEmailAndPassword(email, password);
              // If successful, the auth state stream will update and redirect
              return;
            } catch (_) {
              // If login fails (wrong password), throw original error
              rethrow;
            }
          }
          rethrow;
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.unexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not using standard dark theme, ensure we force dark background here
    // But since we updated AppTheme.darkTheme, it should be fine.

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient/Image Placeholder
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 0.8,
                  colors: [
                    Color(0xFF0F3D24), // Dark Green Glow
                    Color(0xFF05100A), // Deep Black
                  ],
                ),
              ),
            ),
          ),

          // Abstract Wave at Top (Placeholder for standard CustomPainter)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: CustomPaint(painter: WavePainter()),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.emeraldPrimary.withValues(
                                alpha: 0.5,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emeraldPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.wallet,
                            color: AppTheme.emeraldPrimary,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'COUPLE BALANCE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Welcome Text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey<bool>(_isLogin),
                          children: [
                            Text(
                              _isLogin
                                  ? AppLocalizations.of(context)!.welcomeBack
                                  : 'Join Us',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.trackExpensesTogether,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Display Name Field (Sign Up Only)
                      if (!_isLogin) ...[
                        CustomTextField(
                          label: AppLocalizations.of(context)!.displayName,
                          controller: _displayNameController,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.white54,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(
                                context,
                              )!.enterDisplayName;
                            }
                            if (value.length > 100) {
                              return 'Display name is too long (max 100 characters).';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Email Field
                      CustomTextField(
                        label: AppLocalizations.of(context)!.email,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.white54,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.enterEmail;
                          }
                          if (!value.contains('@')) {
                            return AppLocalizations.of(context)!.validEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Password Field
                      CustomTextField(
                        label: AppLocalizations.of(context)!.password,
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white54,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.enterPassword;
                          }
                          if (!_isLogin) {
                            final error = Validators.validatePassword(value);
                            switch (error) {
                              case PasswordValidationError.tooShort:
                                return AppLocalizations.of(
                                  context,
                                )!.passwordMinLength8;
                              case PasswordValidationError.missingUppercase:
                                return AppLocalizations.of(
                                  context,
                                )!.passwordMustContainUppercase;
                              case PasswordValidationError.missingNumber:
                                return AppLocalizations.of(
                                  context,
                                )!.passwordMustContainNumber;
                              case PasswordValidationError.none:
                                return null;
                            }
                          }
                          return null;
                        },
                      ),

                      // Forgot Password (Login Only)
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showForgotPasswordDialog(context),
                            child: Text(
                              AppLocalizations.of(context)!.forgotPassword,
                              style: const TextStyle(
                                color: AppTheme.emeraldPrimary,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 24),

                      const SizedBox(height: 32),

                      // Submit Button
                      CustomButton(
                        text: _isLogin
                            ? AppLocalizations.of(context)!.login
                            : AppLocalizations.of(context)!.signUp,
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),

                      const SizedBox(height: 24),

                      // Toggle Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: const TextStyle(color: Colors.white60),
                          ),
                          GestureDetector(
                            onTap: _toggleAuthMode,
                            child: Text(
                              _isLogin
                                  ? AppLocalizations.of(context)!.signUp
                                  : AppLocalizations.of(context)!.login,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          AppLocalizations.of(context)!.resetPassword,
          style: const TextStyle(color: Colors.white),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.enterEmailToReset,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Email",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return AppLocalizations.of(context)!.invalidEmail;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  await authService.sendPasswordResetEmail(
                    emailController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.resetEmailSent,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}")),
                    );
                  }
                }
              }
            },
            child: Text(
              AppLocalizations.of(context)!.sendResetLink,
              style: const TextStyle(color: AppTheme.emeraldPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AppLocalizations.of(context)!.userNotFound;
      case 'wrong-password':
        return AppLocalizations.of(context)!.incorrectPassword;
      case 'weak-password':
        return AppLocalizations.of(context)!.weakPassword;
      case 'email-already-in-use':
        return AppLocalizations.of(context)!.emailAlreadyInUse;
      case 'invalid-email':
        return AppLocalizations.of(context)!.invalidEmail;
      case 'invalid-credential':
        return AppLocalizations.of(context)!.invalidCredential;
      case 'too-many-requests':
        return AppLocalizations.of(context)!.tooManyRequests;
      case 'network-request-failed':
        return AppLocalizations.of(context)!.networkRequestFailed;
      default:
        return AppLocalizations.of(context)!.authFailed;
    }
  }
}

// Simple Wave Painter for aesthetic
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = AppTheme.emeraldPrimary.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    var path = Path();

    // Draw multiple sine waves
    for (int i = 0; i < 3; i++) {
      path.reset();
      path.moveTo(0, size.height * 0.5 + (i * 10));
      var y = 0.0;
      for (double x = 0; x <= size.width; x++) {
        y =
            size.height * 0.5 +
            (i * 10) +
            20 *
                (0.5 *
                    (x / size.width) *
                    (x / size.width) // Amplitude modulation
                    *
                    (
                        // Sine function
                        (1 * (x / size.width * 6.28 + (i))) -
                            (0.5 * (x / size.width * 12.56)))
                        .abs()); // Simple visual wave
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    // Top glow
    var gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.emeraldPrimary.withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
