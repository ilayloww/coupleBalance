import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:couple_balance/config/theme.dart';
import 'package:couple_balance/services/auth_service.dart';
import 'package:couple_balance/viewmodels/add_expense_viewmodel.dart';
import 'package:flutter/services.dart';

class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0: Amount, 1: Category, 2: Split Type
  late AddExpenseViewModel _viewModel;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _viewModel = AddExpenseViewModel();

    // Play haptic feedback when opening
    HapticFeedback.mediumImpact();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final partnerId = authService.selectedPartnerId;
      if (partnerId != null) {
        _viewModel.init(partnerId);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _saveExpense();
    }
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      _close();
    }
  }

  void _close() {
    _animationController.reverse().then((_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        SystemNavigator.pop();
      }
    });
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_viewModel.amountStr) ?? 0;
    final l10n = AppLocalizations.of(context)!;

    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validAmountError)));
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final receiverUid = authService.selectedPartnerId;

    if (receiverUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No partner selected. Cannot add expense.'),
        ),
      );
      return;
    }

    // Set custom note based on category name
    String note = _getCategoryLabel(context, _viewModel.selectedCategory);
    if (_viewModel.selectedCategory == 'custom') {
      note = _viewModel.customCategoryText.trim().isEmpty
          ? l10n.tagCustom
          : _viewModel.customCategoryText.trim();
    }

    final error = await _viewModel.saveExpense(
      amount: amount,
      note: note,
      receiverUid: receiverUid,
    );

    if (mounted) {
      if (error == null) {
        HapticFeedback.heavyImpact();
        _close();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  String _getCategoryLabel(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'food':
        return l10n.tagFood;
      case 'coffee':
        return l10n.tagCoffee;
      case 'rent':
        return l10n.tagRent;
      case 'groceries':
        return l10n.tagGroceries;
      case 'transport':
        return l10n.tagTransport;
      case 'date':
        return l10n.tagDate;
      case 'bills':
        return l10n.tagBills;
      case 'shopping':
        return l10n.tagShopping;
      case 'custom':
        return l10n.tagCustom;
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fully transparent
      body: Stack(
        children: [
          // Blurred backdrop
          GestureDetector(
            onTap: _close,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),

          // Main content modal
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.9,
                  end: 1.0,
                ).animate(_fadeAnimation),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1A13),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.emeraldPrimary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ChangeNotifierProvider.value(
                      value: _viewModel,
                      child: Consumer<AddExpenseViewModel>(
                        builder: (context, viewModel, child) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress Indicator
                              Row(
                                children: List.generate(3, (index) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: index <= _currentStep
                                            ? AppTheme.emeraldPrimary
                                            : Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 24),

                              // View based on step
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _buildStepContent(viewModel),
                              ),

                              const SizedBox(height: 24),

                              // Next / Save Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : (_currentStep == 0 &&
                                                (double.tryParse(
                                                          viewModel.amountStr,
                                                        ) ??
                                                        0) <=
                                                    0
                                            ? null
                                            : _nextStep),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.emeraldPrimary,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: viewModel.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _currentStep == 2
                                              ? AppLocalizations.of(
                                                  context,
                                                )!.saveExpense
                                              : "Next",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              if (_currentStep > 0) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : _prevStep,
                                  child: const Text(
                                    "Back",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(AddExpenseViewModel viewModel) {
    switch (_currentStep) {
      case 0:
        return _buildAmountStep(viewModel);
      case 1:
        return _buildCategoryStep(viewModel);
      case 2:
        return _buildSplitStep(viewModel);
      default:
        return const SizedBox();
    }
  }

  Widget _buildAmountStep(AddExpenseViewModel viewModel) {
    return Column(
      key: const ValueKey(0),
      children: [
        Text(
          "Quick Add Amount",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\u20BA${viewModel.amountStr}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _NumberPad(viewModel: viewModel),
      ],
    );
  }

  Widget _buildCategoryStep(AddExpenseViewModel viewModel) {
    return Column(
      key: const ValueKey(1),
      children: [
        Text(
          "Select Category",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: viewModel.categories.map((cat) {
            final isSelected = viewModel.selectedCategory == cat['id'];
            return GestureDetector(
              onTap: () {
                viewModel.setCategory(cat['id']);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0B3B24)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.emeraldPrimary
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      cat['icon'],
                      size: 20,
                      color: isSelected
                          ? AppTheme.emeraldPrimary
                          : Colors.white70,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryLabel(context, cat['id']),
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.emeraldPrimary
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSplitStep(AddExpenseViewModel viewModel) {
    return Column(
      key: const ValueKey(2),
      children: [
        Text(
          "Select Split Type",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _SplitOptionTile(
          title: "50/50 (You paid)",
          isSelected: viewModel.selectedOption == SplitOption.youPaidSplit,
          onTap: () {
            viewModel.setSplitOption(SplitOption.youPaidSplit);
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 8),
        _SplitOptionTile(
          title: "Full (You paid everything)",
          isSelected: viewModel.selectedOption == SplitOption.youPaidFull,
          onTap: () {
            viewModel.setSplitOption(SplitOption.youPaidFull);
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 8),
        _SplitOptionTile(
          title: "50/50 (Partner paid)",
          isSelected: viewModel.selectedOption == SplitOption.partnerPaidSplit,
          onTap: () {
            viewModel.setSplitOption(SplitOption.partnerPaidSplit);
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 8),
        _SplitOptionTile(
          title: "Full (Partner paid everything)",
          isSelected: viewModel.selectedOption == SplitOption.partnerPaidFull,
          onTap: () {
            viewModel.setSplitOption(SplitOption.partnerPaidFull);
            HapticFeedback.selectionClick();
          },
        ),
      ],
    );
  }
}

class _SplitOptionTile extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SplitOptionTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0B3B24)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.emeraldPrimary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.emeraldPrimary : Colors.white54,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  final AddExpenseViewModel viewModel;

  const _NumberPad({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildRow(['.', '0', 'BACK']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == 'BACK') {
          return _buildKey(
            child: const Icon(Icons.backspace_outlined, color: Colors.white),
            onTap: () {
              HapticFeedback.lightImpact();
              viewModel.backspace();
            },
          );
        } else if (key == '.') {
          return _buildKey(
            child: const Text(
              '.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              viewModel.addDecimal();
            },
          );
        } else {
          return _buildKey(
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              viewModel.addDigit(int.parse(key));
            },
          );
        }
      }).toList(),
    );
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );
  }
}
