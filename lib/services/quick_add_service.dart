import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

class QuickAddService {
  final GlobalKey<NavigatorState> navigatorKey;
  bool _initialized = false;

  QuickAddService(this.navigatorKey);

  void init() {
    if (_initialized) return;
    _initialized = true;

    _setupAppShortcuts();
  }

  void _setupAppShortcuts() {
    const QuickActions quickActions = QuickActions();

    // Set shortcuts on home screen
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_quick_add',
        localizedTitle: 'Quick Add',
        icon:
            'ic_launcher', // Make sure this matches an icon in android/app/src/main/res/drawable
      ),
    ]);

    // Listen for shortcut taps
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_quick_add') {
        _navigateToQuickAdd();
      }
    });
  }

  void _navigateToQuickAdd() {
    // Check if we are already on the quick-add screen
    bool isCurrentQuickAdd = false;
    navigatorKey.currentState?.popUntil((route) {
      if (route.settings.name == '/quick-add') {
        isCurrentQuickAdd = true;
      }
      return true;
    });

    if (!isCurrentQuickAdd) {
      navigatorKey.currentState?.pushNamed('/quick-add');
    }
  }
}
