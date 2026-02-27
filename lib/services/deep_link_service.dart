import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Uncommented
import 'package:shared_preferences/shared_preferences.dart'; // Added
import 'auth_service.dart'; // Uncommented
import '../screens/partner_link_screen.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> navigatorKey;
  final SharedPreferences prefs;

  DeepLinkService(this.navigatorKey, this.prefs);

  void init() {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  // State to track if we are currently handling a deep link
  // Used to suppress startup dialogs (like updates)
  bool _isHandlingLink = false;
  bool get isHandlingLink => _isHandlingLink;

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'couplebalance' && uri.host == 'invite') {
      _isHandlingLink = true; // Set flag start
      try {
        final partnerId = uri.queryParameters['partnerId'];
        if (partnerId != null) {
          final context = navigatorKey.currentContext;
          if (context == null) return;

          final authService = Provider.of<AuthService>(context, listen: false);
          if (authService.currentUser != null) {
            // User is logged in, navigate immediately
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) =>
                    PartnerLinkScreen(initialPartnerId: partnerId),
              ),
            );
          } else {
            // User not logged in, save for later
            await prefs.setString('pending_invite_id', partnerId);
            // Show message IF context is valid (might be LoginScreen)
            // Fixed: Capture state, check mounted, use state.context
            final state = navigatorKey.currentState;
            if (state != null && state.mounted) {
              ScaffoldMessenger.of(state.context).showSnackBar(
                const SnackBar(
                  content: Text('Please login to accept the invite.'),
                ),
              );
            }
          }
        }
      } finally {
        // Reset flag after a delay to ensure transition completes
        // or just leave it true? If true, updates are suppressed even if we come back?
        // Let's reset it after a short delay.
        Future.delayed(const Duration(seconds: 5), () {
          _isHandlingLink = false;
        });
      }
    }
  }
}
