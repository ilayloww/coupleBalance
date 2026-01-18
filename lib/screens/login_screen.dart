import 'package:flutter/material.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rive/rive.dart';
import '../widgets/login_animation.dart';
import '../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum ValidationStatus { none, success, fail }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  ValidationStatus _validationStatus = ValidationStatus.none;
  String? _errorMessage;

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Rive inputs
  SMIBool? _isFocus;
  SMIBool? _isPrivateField;
  SMIBool? _isPrivateFieldShow; // For peeking
  SMITrigger? _successTrigger;
  SMITrigger? _failTrigger;
  SMINumber? _numLook;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_emailFocusChanged);
    _passwordFocusNode.addListener(_passwordFocusChanged);
  }

  void _emailFocusChanged() {
    _isFocus?.change(_emailFocusNode.hasFocus);
  }

  void _passwordFocusChanged() {
    // When password has focus, raise hands (isPrivateField)
    _isPrivateField?.change(_passwordFocusNode.hasFocus);

    // Also sync the "peek" state (isPrivateFieldShow) immediately if we gain focus
    if (_passwordFocusNode.hasFocus) {
      _isPrivateFieldShow?.change(_isPasswordVisible);
    }
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_emailFocusChanged);
    _passwordFocusNode.removeListener(_passwordFocusChanged);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Unfocus keyboard immediately to let hands start dropping naturally
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _validationStatus = ValidationStatus.none;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await authService.signInWithEmailAndPassword(email, password);
      } else {
        await authService.registerWithEmailAndPassword(email, password);
      }

      // Reset internal hands state so Success animation can play
      _isPrivateField?.change(false);
      _isPrivateFieldShow?.change(false);
      _isFocus?.change(false); // Also stop looking

      // Trigger success animation
      _successTrigger?.fire();

      if (mounted) {
        setState(() {
          _validationStatus = ValidationStatus.success;
        });
      }
    } on FirebaseAuthException catch (e) {
      // Reset internal hands state so Fail animation can play
      // Reset internal hands state so Fail animation can play
      _isPrivateField?.change(false);
      _isPrivateFieldShow?.change(false);
      _isFocus?.change(false);

      // Wait for "Hands Down" animation to complete
      if (mounted) await Future.delayed(const Duration(milliseconds: 1000));

      _failTrigger?.fire();
      setState(() {
        _validationStatus = ValidationStatus.fail;
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      // Reset internal hands state so Fail animation can play
      // Reset internal hands state so Fail animation can play
      _isPrivateField?.change(false);
      _isPrivateFieldShow?.change(false);
      _isFocus?.change(false);

      // Wait for "Hands Down" animation to complete
      if (mounted) await Future.delayed(const Duration(milliseconds: 1000));

      _failTrigger?.fire();
      setState(() {
        _validationStatus = ValidationStatus.fail;
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
      // Reset animation states
      _isFocus?.change(false);
      _isPrivateField?.change(false);
      _isPrivateFieldShow?.change(false);
    });
  }

  void _onRiveInit(
    SMIBool? isFocus,
    SMIBool? isPrivateField,
    SMIBool? isPrivateFieldShow,
    SMITrigger? successTrigger,
    SMITrigger? failTrigger,
    SMINumber? numLook,
  ) {
    _isFocus = isFocus;
    _isPrivateField = isPrivateField;
    _isPrivateFieldShow = isPrivateFieldShow;
    _successTrigger = successTrigger;
    _failTrigger = failTrigger;
    _numLook = numLook;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white, // Removed to use theme background
      body: Theme(
        data: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkTheme(Colors.pinkAccent)
            : AppTheme.lightTheme(Colors.pinkAccent),
        child: Builder(
          builder: (context) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 50), // Move teddy down a bit
                      // Login Animation
                      Center(child: LoginAnimation(onInit: _onRiveInit)),
                      // const Icon(Icons.favorite, size: 80, color: Colors.pinkAccent), // Replaced by animation
                      const SizedBox(
                        height: 5,
                      ), // Reduce space below teddy since it is bigger now
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Text(
                          key: ValueKey<bool>(_isLogin),
                          _isLogin
                              ? AppLocalizations.of(context)!.welcomeBack
                              : AppLocalizations.of(context)!.createAccount,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.trackExpensesTogether,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 48),

                      // Error Message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: Colors.pinkAccent, // Explicit pink cursor
                        onChanged: (value) {
                          _numLook?.change(value.length.toDouble());
                          if (_validationStatus != ValidationStatus.none) {
                            setState(() {
                              _validationStatus = ValidationStatus.none;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _validationStatus == ValidationStatus.success
                                  ? Colors.green
                                  : _validationStatus == ValidationStatus.fail
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _validationStatus == ValidationStatus.success
                                  ? Colors.green
                                  : _validationStatus == ValidationStatus.fail
                                  ? Colors.red
                                  : Colors.pinkAccent,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_isPasswordVisible,
                        cursorColor: Colors.pinkAccent, // Explicit pink cursor
                        onChanged: (value) {
                          if (_validationStatus != ValidationStatus.none) {
                            setState(() {
                              _validationStatus = ValidationStatus.none;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                              // If password field has focus, toggle the peek state (isPrivateFieldShow)
                              if (_passwordFocusNode.hasFocus) {
                                _isPrivateFieldShow?.change(_isPasswordVisible);
                              }
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _validationStatus == ValidationStatus.success
                                  ? Colors.green
                                  : _validationStatus == ValidationStatus.fail
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  _validationStatus == ValidationStatus.success
                                  ? Colors.green
                                  : _validationStatus == ValidationStatus.fail
                                  ? Colors.red
                                  : Colors.pinkAccent,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!_isLogin && value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(context),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.pinkAccent, // Explicit pink text
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.forgotPassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.pinkAccent, // Explicit pink background
                          foregroundColor: Colors.white, // Explicit white text
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                child: Text(
                                  key: ValueKey<bool>(_isLogin),
                                  _isLogin
                                      ? AppLocalizations.of(context)!.login
                                      : AppLocalizations.of(context)!.signUp,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle Button
                      TextButton(
                        onPressed: _isLoading ? null : _toggleAuthMode,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Text(
                            key: ValueKey<bool>(_isLogin),
                            _isLogin
                                ? AppLocalizations.of(context)!.dontHaveAccount
                                : AppLocalizations.of(
                                    context,
                                  )!.alreadyHaveAccount,
                            style: const TextStyle(color: Colors.pinkAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
        title: Text(AppLocalizations.of(context)!.resetPassword),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.enterEmailToReset),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: const OutlineInputBorder(),
                ),
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
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.sendResetLink),
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
