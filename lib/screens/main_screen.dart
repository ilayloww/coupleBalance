import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import '../services/auth_service.dart';

import 'home_screen.dart';
import 'calendar_screen.dart';
import 'add_expense_screen.dart';
import 'partner_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final selectedPartnerId = authService.selectedPartnerId;

        final pages = [
          const HomeScreen(),
          CalendarScreen(
            userUid: user.uid,
            partnerUid: selectedPartnerId ?? '',
          ),
        ];

        return Scaffold(
          extendBody: true, // Required for transparent notch
          // IndexedStack preserves state of pages (scrolling, input, etc.)
          // IndexedStack preserves state of pages (scrolling, input, etc.)
          body: IndexedStack(index: _currentIndex, children: pages),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (selectedPartnerId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.pleaseLinkPartnerFirst,
                    ),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context)!.linkPartner,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PartnerListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddExpenseScreen(partnerUid: selectedPartnerId),
                ),
              );
            },
            shape: const CircleBorder(), // Force circular shape
            // The FAB color is handled by the Theme (floatingActionButtonTheme)
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45, // Increased strength
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BottomAppBar(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors
                            .white // White bar with shadow for floating look
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: const CenteredCircularNotchedRectangle(),
                  notchMargin: 8.0,
                  height: 50,
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(
                              0,
                              6,
                            ), // Visual centering adjustment
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _currentIndex == 0
                                    ? Icons.home
                                    : Icons.home_outlined,
                              ),
                              iconSize: 32,
                              color: _currentIndex == 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              tooltip: 'Home',
                              onPressed: () {
                                if (_currentIndex != 0) {
                                  setState(() {
                                    _currentIndex = 0;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      // The exact center gap for the FAB
                      const SizedBox(width: 60),
                      Expanded(
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(
                              0,
                              6,
                            ), // Visual centering adjustment
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _currentIndex == 1
                                    ? Icons.calendar_month
                                    : Icons.calendar_month_outlined,
                              ),
                              iconSize: 32,
                              color: _currentIndex == 1
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              tooltip: 'Calendar',
                              onPressed: () {
                                if (_currentIndex != 1) {
                                  setState(() {
                                    _currentIndex = 1;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CenteredCircularNotchedRectangle extends CircularNotchedRectangle {
  const CenteredCircularNotchedRectangle();

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) {
      return super.getOuterPath(host, guest);
    }

    // Force the guest rect to be centered horizontally with the host
    final double dx = host.center.dx - guest.center.dx;
    final Rect adjustedGuest = guest.shift(Offset(dx, 0));

    return super.getOuterPath(host, adjustedGuest);
  }
}
