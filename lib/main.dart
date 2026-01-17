import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/localization_service.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';

// UNCOMMENT the following line after running `flutterfire configure`
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Try to initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    runApp(MyApp(prefs: prefs));
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    // Run an error app if Firebase fails, so the user sees something other than a black screen
    runApp(InitializationErrorApp(error: e.toString()));
  }
}

class InitializationErrorApp extends StatelessWidget {
  final String error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 24),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please make sure you have configured Firebase for this project.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Run command:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: const Text('flutterfire configure'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Error Details:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService(prefs)),
        ChangeNotifierProvider(create: (_) => LocalizationService(prefs)),
      ],
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, themeService, localizationService, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'CoupleBalance',
            themeAnimationDuration: Duration
                .zero, // Disable animation to prevent color interpolation issues
            theme: AppTheme.lightTheme(themeService.selectedColor),
            darkTheme: AppTheme.darkTheme(themeService.selectedColor),
            themeMode: themeService.themeMode,
            locale: localizationService.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('tr'), // Turkish
            ],
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);

    // Listen to the stream manually to handle transitions
    authService.userChanges.listen((User? user) async {
      if (!mounted) return;

      // If this is the FIRST load, don't delay.
      // If transitioning from NULL (logged out) to USER (logged in), delay for animation.
      if (!_isInit && _user == null && user != null) {
        // Login Success! Wait for animation to play.
        await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted) {
        setState(() {
          _user = user;
          _isInit = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If identifying initial state (and user is unknown), show loader or fallback
    if (_isInit && _user == null) {
      // We can temporarily check the current sync value if possible,
      // or just show a loader until the stream emits first event.
      // However, Stream.listen usually emits quickly.
      // Let's rely on the stream callback.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const LoginScreen();
    }

    // Check verification status
    if (!_user!.emailVerified) {
      return const EmailVerificationScreen();
    }

    return const HomeScreen();
  }
}
