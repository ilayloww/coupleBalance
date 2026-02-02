import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:couple_balance/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:couple_balance/config/theme.dart'; // Ensure AppTheme is available

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      setState(() {}); // Rebuild to update strength meter
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Basic strength check: 1 point for > 0 chars, +1 for >= 6, +1 for >= 8, +1 for complexity (optional, sticking to 8 chars per screenshot hint)
  // Screenshot says "Must contain at least 8 characters."
  // Let's make bars fill up as we approach 8.
  // 4 bars total.
  // 1-2 chars -> 1 bar
  // 3-5 chars -> 2 bars
  // 6-7 chars -> 3 bars
  // 8+ chars -> 4 bars (Green)
  int _calculateStrength(String password) {
    if (password.isEmpty) return 0;
    if (password.length >= 8) return 4;
    if (password.length >= 6) return 3;
    if (password.length >= 3) return 2;
    return 1;
  }

  Color _getStrengthColor(int strength, int index) {
    // If strength is high enough to light up this bar
    if (strength > index) {
      if (strength == 4) return AppTheme.emeraldPrimary; // Full strength
      return AppTheme.emeraldPrimary.withValues(
        alpha: 0.5 + (index * 0.1),
      ); // Gradientish or just solid
    }
    return Colors.white.withValues(alpha: 0.1); // Inactive
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.passwordUpdated),
            backgroundColor: AppTheme.emeraldPrimary,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'invalid-credential':
          case 'wrong-password':
            errorMessage = AppLocalizations.of(context)!.incorrectPassword;
            break;
          case 'weak-password':
            errorMessage = AppLocalizations.of(context)!.weakPassword;
            break;
          case 'requires-recent-login':
            errorMessage = AppLocalizations.of(context)!.reauthRequired;
            break;
          case 'same-password':
            errorMessage = AppLocalizations.of(context)!.passwordCannotBeSame;
            break;
          default:
            errorMessage = e.message ?? AppLocalizations.of(context)!.error;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strength = _calculateStrength(_newPasswordController.text);

    return Scaffold(
      backgroundColor: const Color(0xFF05100A), // Deep dark green/black
      appBar: AppBar(
        title: Text(
          l10n.changePassword,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.passwordDifferentNote,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Current Password
              _PasswordInput(
                controller: _currentPasswordController,
                label: l10n.currentPassword,
                hint: l10n.enterCurrentPassword,
                icon: Icons.lock_outline,
                obscureText: _obscureCurrent,
                onToggleVisibility: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (value) => value == null || value.isEmpty
                    ? l10n.currentPassword
                    : null,
              ),

              const SizedBox(height: 24),

              // New Password
              _PasswordInput(
                controller: _newPasswordController,
                label: l10n.newPassword,
                hint: l10n.enterNewPassword,
                icon: Icons.vpn_key_outlined,
                obscureText: _obscureNew,
                onToggleVisibility: () =>
                    setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return l10n.passwordMinLength8;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Strength Bars
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _getStrengthColor(strength, index),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.passwordMinLength8,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 24),

              // Confirm New Password
              _PasswordInput(
                controller: _confirmPasswordController,
                label: l10n.confirmNewPassword,
                hint: l10n.reenterNewPassword,
                icon: Icons.check_circle_outline,
                obscureText: _obscureConfirm,
                onToggleVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 60),

              // Button
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.emeraldPrimary,
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldPrimary,
                      foregroundColor: Colors
                          .black, // Dark text on green button for contrast
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppTheme.emeraldPrimary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    child: Text(
                      l10n.updatePassword,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? Function(String?) validator;

  const _PasswordInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                onPressed: onToggleVisibility,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
