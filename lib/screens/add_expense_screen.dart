import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:couple_balance/config/theme.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../viewmodels/add_expense_viewmodel.dart';

class AddExpenseScreen extends StatelessWidget {
  final String partnerUid;

  const AddExpenseScreen({super.key, required this.partnerUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddExpenseViewModel()..init(partnerUid),
      child: const _AddExpenseContent(),
    );
  }
}

class _AddExpenseContent extends StatelessWidget {
  const _AddExpenseContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AddExpenseViewModel>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF05100A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          l10n.addExpense,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: viewModel.clearAmount,
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              color: AppTheme.emeraldPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Amount Display
                  Text(
                    "AMOUNT",
                    style: TextStyle(
                      color: AppTheme.emeraldPrimary.withValues(alpha: 0.7),
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "\u20BA${viewModel.amountStr}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 48,
                        margin: const EdgeInsets.only(bottom: 8, left: 2),
                        color: AppTheme.emeraldPrimary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Split Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _SplitToggleItem(
                            label: "50/50",
                            isSelected:
                                viewModel.selectedOption ==
                                    SplitOption.youPaidSplit ||
                                viewModel.selectedOption ==
                                    SplitOption.partnerPaidSplit,
                            onTap: () => viewModel.setSplitOption(
                              SplitOption.youPaidSplit,
                            ),
                          ),
                          _SplitToggleItem(
                            label: "Full",
                            isSelected:
                                viewModel.selectedOption ==
                                    SplitOption.youPaidFull ||
                                viewModel.selectedOption ==
                                    SplitOption.partnerPaidFull,
                            onTap: () => viewModel.setSplitOption(
                              SplitOption.youPaidFull,
                            ),
                          ),
                          _SplitToggleItem(
                            label: "Custom",
                            isSelected:
                                viewModel.selectedOption == SplitOption.custom,
                            onTap: () {
                              viewModel.setSplitOption(SplitOption.custom);
                              _showCustomSplitSheet(context, viewModel);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Category Label
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "CATEGORY",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category List
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: viewModel.categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cat = viewModel.categories[index];
                        final isSelected =
                            viewModel.selectedCategory == cat['id'];
                        return _CategoryChip(
                          label: _getCategoryLabel(context, cat['id']),
                          icon: cat['icon'],
                          isSelected: isSelected,
                          onTap: () => viewModel.setCategory(cat['id']),
                        );
                      },
                    ),
                  ),

                  // Custom Category Input
                  if (viewModel.selectedCategory == 'custom')
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                      ),
                      child: TextField(
                        onChanged: viewModel.setCustomCategoryText,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: l10n.customCategoryHint,
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Attach Receipt
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: InkWell(
                      onTap: () => _showImagePickerModal(context, viewModel),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: viewModel.state.selectedImage != null
                                    ? AppTheme.emeraldPrimary
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: viewModel.state.selectedImage != null
                                    ? Colors.black
                                    : AppTheme.emeraldPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  viewModel.state.selectedImage != null
                                      ? l10n.imageSelected
                                      : l10n.addReceiptPhoto,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (viewModel.state.selectedImage == null)
                                  Text(
                                    "Optional",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Number Pad
                  _NumberPad(viewModel: viewModel),

                  const SizedBox(height: 20),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                                final amount =
                                    double.tryParse(viewModel.amountStr) ?? 0;
                                if (amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.validAmountError),
                                    ),
                                  );
                                  return;
                                }

                                if (viewModel.selectedCategory == 'custom' &&
                                    viewModel.customCategoryText
                                        .trim()
                                        .isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.enterCategoryError),
                                    ),
                                  );
                                  return;
                                }

                                // Pass the localized category name as the note
                                final note = _getCategoryLabel(
                                  context,
                                  viewModel.selectedCategory,
                                );

                                // If Custom is selected, the slider has already set
                                // _customOwedAmount, so we don't need to override it here.

                                final success = await viewModel.saveExpense(
                                  amount: amount,
                                  note: note,
                                  receiverUid:
                                      Provider.of<AuthService>(
                                        context,
                                        listen: false,
                                      ).selectedPartnerId ??
                                      '',
                                );
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldPrimary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: viewModel.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.black,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.saveExpense,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(BuildContext context, String id) {
    // Map ids to l10n
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

  void _showImagePickerModal(
    BuildContext context,
    AddExpenseViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1E14),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text(
                AppLocalizations.of(context)!.gallery,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                viewModel.pickImage(ImageSource.gallery);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: Text(
                AppLocalizations.of(context)!.camera,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                viewModel.pickImage(ImageSource.camera);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomSplitSheet(
    BuildContext context,
    AddExpenseViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF05100A), // Dark background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ChangeNotifierProvider.value(
              value: viewModel,
              child: const _CustomSplitSheetContent(),
            );
          },
        );
      },
    );
  }
}

class _SplitToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SplitToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.emeraldPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0B3B24)
              : Colors.transparent, // Darker Green BG for selected
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppTheme.emeraldPrimary
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppTheme.emeraldPrimary
                  : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.emeraldPrimary
                    : Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 14,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 24),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 24),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 24),
          _buildRow(['.', '0', 'BACK']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        if (key == 'BACK') {
          return _buildKey(
            child: const Icon(
              Icons.backspace_outlined,
              color: Colors.white,
              size: 24,
            ),
            onTap: viewModel.backspace,
          );
        } else if (key == '.') {
          return _buildKey(
            child: const Text(
              '.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: viewModel.addDecimal,
          );
        } else {
          return _buildKey(
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => viewModel.addDigit(int.parse(key)),
          );
        }
      }).toList(),
    );
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return SizedBox(
      width: 60,
      height: 60,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Center(child: child),
      ),
    );
  }
}

/// Enum to track which input is currently active for custom numpad
enum _ActiveInput { myPercent, myAmount, partnerPercent, partnerAmount }

class _CustomSplitSheetContent extends StatefulWidget {
  const _CustomSplitSheetContent();

  @override
  State<_CustomSplitSheetContent> createState() =>
      _CustomSplitSheetContentState();
}

class _CustomSplitSheetContentState extends State<_CustomSplitSheetContent> {
  late TextEditingController _myPercentCtrl;
  late TextEditingController _myAmountCtrl;
  late TextEditingController _partnerPercentCtrl;
  late TextEditingController _partnerAmountCtrl;

  final FocusNode _myPercentFocus = FocusNode();
  final FocusNode _myAmountFocus = FocusNode();
  final FocusNode _partnerPercentFocus = FocusNode();
  final FocusNode _partnerAmountFocus = FocusNode();

  // Local slider value for smooth dragging
  double? _localSliderValue;
  bool _isDragging = false;

  // Active input tracking for custom numpad
  _ActiveInput? _activeInput;

  // Scroll controller for auto-scrolling to numpad
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _myPercentCtrl = TextEditingController();
    _myAmountCtrl = TextEditingController();
    _partnerPercentCtrl = TextEditingController();
    _partnerAmountCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _myPercentCtrl.dispose();
    _myAmountCtrl.dispose();
    _partnerPercentCtrl.dispose();
    _partnerAmountCtrl.dispose();
    _myPercentFocus.dispose();
    _myAmountFocus.dispose();
    _partnerPercentFocus.dispose();
    _partnerAmountFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncControllers(AddExpenseViewModel model) {
    double total = double.tryParse(model.amountStr) ?? 0;
    double myPct = model.customPercentage;
    double myAmt = (total * myPct) / 100;
    double partnerPct = 100 - myPct;
    double partnerAmt = total - myAmt;

    void sync(
      TextEditingController ctrl,
      FocusNode focus,
      double val,
      int decimals,
    ) {
      if (!focus.hasFocus) {
        String newVal = val.toStringAsFixed(decimals);
        if (ctrl.text != newVal) {
          ctrl.text = newVal;
        }
      }
    }

    sync(_myPercentCtrl, _myPercentFocus, myPct, 0);
    sync(_myAmountCtrl, _myAmountFocus, myAmt, 2);
    sync(_partnerPercentCtrl, _partnerPercentFocus, partnerPct, 0);
    sync(_partnerAmountCtrl, _partnerAmountFocus, partnerAmt, 2);
  }

  TextEditingController? get _activeController {
    switch (_activeInput) {
      case _ActiveInput.myPercent:
        return _myPercentCtrl;
      case _ActiveInput.myAmount:
        return _myAmountCtrl;
      case _ActiveInput.partnerPercent:
        return _partnerPercentCtrl;
      case _ActiveInput.partnerAmount:
        return _partnerAmountCtrl;
      case null:
        return null;
    }
  }

  void _onNumpadDigit(int digit) {
    final ctrl = _activeController;
    if (ctrl == null) return;

    String current = ctrl.text;
    if (current == '0' && digit != 0) {
      current = digit.toString();
    } else if (current == '0' && digit == 0) {
      return; // Don't add leading zeros
    } else {
      // Prevent too many decimal places
      if (current.contains('.')) {
        final parts = current.split('.');
        if (parts.length > 1 && parts[1].length >= 2) return;
      }
      if (current.length >= 7) return; // Max length
      current += digit.toString();
    }
    ctrl.text = current;
    ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: ctrl.text.length),
    );
    _triggerOnChanged(ctrl.text);
  }

  void _onNumpadDecimal() {
    final ctrl = _activeController;
    if (ctrl == null) return;

    // Block decimals for percentage inputs
    if (_activeInput == _ActiveInput.myPercent ||
        _activeInput == _ActiveInput.partnerPercent) {
      return;
    }

    if (!ctrl.text.contains('.')) {
      ctrl.text = '${ctrl.text}.';
      ctrl.selection = TextSelection.fromPosition(
        TextPosition(offset: ctrl.text.length),
      );
    }
  }

  void _onNumpadBackspace() {
    final ctrl = _activeController;
    if (ctrl == null) return;

    String current = ctrl.text;
    if (current.length > 1) {
      current = current.substring(0, current.length - 1);
    } else {
      current = '0';
    }
    ctrl.text = current;
    ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: ctrl.text.length),
    );
    _triggerOnChanged(ctrl.text);
  }

  void _triggerOnChanged(String value) {
    // This will be called when numpad changes a value
    // The actual update to model happens through the build method's onChanged callbacks
    setState(() {}); // Trigger rebuild to sync values
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddExpenseViewModel>(
      builder: (context, model, child) {
        _syncControllers(model);
        final double totalAmount = double.tryParse(model.amountStr) ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        "Custom Split",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),

                // Total Amount
                Text(
                  "Total Amount",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "\u20BA${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),

                // Rows
                _buildEditableRow(
                  context,
                  "You",
                  "Payer",
                  Provider.of<AuthService>(
                        context,
                      ).currentUserModel?.photoUrl ??
                      model.userPhotoUrl,
                  Icons.person,
                  _myPercentCtrl,
                  _myPercentFocus,
                  _myAmountCtrl,
                  _myAmountFocus,
                  (val) => model.setCustomPercentage(
                    double.tryParse(val) ?? 0,
                    totalAmount,
                  ),
                  (val) => model.setCustomAmount(
                    double.tryParse(val) ?? 0,
                    totalAmount,
                  ),
                  _ActiveInput.myPercent,
                  _ActiveInput.myAmount,
                ),
                const SizedBox(height: 16),
                _buildEditableRow(
                  context,
                  model.partnerName,
                  "",
                  model.partnerPhotoUrl,
                  Icons.people,
                  _partnerPercentCtrl,
                  _partnerPercentFocus,
                  _partnerAmountCtrl,
                  _partnerAmountFocus,
                  (val) {
                    double pPct = double.tryParse(val) ?? 0;
                    model.setCustomPercentage(100 - pPct, totalAmount);
                  },
                  (val) {
                    double pAmt = double.tryParse(val) ?? 0;
                    model.setCustomAmount(totalAmount - pAmt, totalAmount);
                  },
                  _ActiveInput.partnerPercent,
                  _ActiveInput.partnerAmount,
                ),

                const SizedBox(height: 32),

                // Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "YOUR SHARE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "PARTNER'S SHARE",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.emeraldPrimary,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: AppTheme.emeraldPrimary,
                    overlayColor: AppTheme.emeraldPrimary.withValues(
                      alpha: 0.2,
                    ),
                    trackHeight: 6,
                    thumbShape: const _DottedSliderThumbShape(thumbRadius: 14),
                  ),
                  child: Slider(
                    value:
                        (_isDragging
                                ? _localSliderValue
                                : model.customPercentage)
                            ?.clamp(0.0, 100.0) ??
                        50.0,
                    min: 0,
                    max: 100,
                    allowedInteraction: SliderInteraction.tapAndSlide,
                    onChangeStart: (val) {
                      setState(() {
                        _isDragging = true;
                        _localSliderValue = val;
                      });
                    },
                    onChanged: (val) {
                      setState(() {
                        _localSliderValue = val;
                      });
                      // Update model for live text field updates
                      model.setCustomPercentage(val, totalAmount);
                    },
                    onChangeEnd: (val) {
                      setState(() {
                        _isDragging = false;
                        _localSliderValue = null;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  "Adjusting one value automatically updates the others.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 24),

                // Custom Numpad (only show when an input is active)
                if (_activeInput != null) ...[
                  _buildMiniNumpad(model, totalAmount),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // Set the split option to custom before closing
                      model.setSplitOption(SplitOption.custom);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldPrimary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Confirm Split",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditableRow(
    BuildContext context,
    String name,
    String role,
    String? photoUrl,
    IconData fallbackIcon,
    TextEditingController pctCtrl,
    FocusNode pctFocus,
    TextEditingController amtCtrl,
    FocusNode amtFocus,
    ValueChanged<String> onPctChanged,
    ValueChanged<String> onAmtChanged,
    _ActiveInput pctInputType,
    _ActiveInput amtInputType,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            alignment: Alignment.center,
            child: ClipOval(
              child: SizedBox(
                width: 48,
                height: 48,
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.emeraldPrimary,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: Icon(
                            fallbackIcon,
                            color: AppTheme.emeraldPrimary,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: Icon(
                          fallbackIcon,
                          color: AppTheme.emeraldPrimary,
                          size: 24,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (role.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Inputs Side-by-Side
          Row(
            children: [
              _buildBoxedInput(
                pctCtrl,
                pctFocus,
                onPctChanged,
                "%",
                80,
                pctInputType,
              ),
              const SizedBox(width: 12),
              _buildBoxedInput(
                amtCtrl,
                amtFocus,
                onAmtChanged,
                "\u20BA",
                100,
                amtInputType,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoxedInput(
    TextEditingController ctrl,
    FocusNode focus,
    ValueChanged<String> onChanged,
    String suffix,
    double width,
    _ActiveInput inputType,
  ) {
    final isActive = _activeInput == inputType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeInput = inputType;
        });
        focus.requestFocus();
        // Auto-scroll to show the numpad
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      },
      child: Container(
        width: width,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1E14), // Darker green/black
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? AppTheme.emeraldPrimary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                right: 14,
              ), // Shift text left from symbol
              child: TextField(
                controller: ctrl,
                focusNode: focus,
                readOnly: true, // Prevent system keyboard
                showCursor: true,
                onTap: () {
                  setState(() {
                    _activeInput = inputType;
                  });
                  // Auto-scroll to show the numpad
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  });
                },
                onChanged: onChanged,
                textAlign: TextAlign.center,
                cursorColor: AppTheme.emeraldPrimary,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            Positioned(
              right: 12,
              child: IgnorePointer(
                child: Text(
                  suffix,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniNumpad(AddExpenseViewModel model, double totalAmount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNumpadRow(['1', '2', '3'], model, totalAmount),
        const SizedBox(height: 12),
        _buildNumpadRow(['4', '5', '6'], model, totalAmount),
        const SizedBox(height: 12),
        _buildNumpadRow(['7', '8', '9'], model, totalAmount),
        const SizedBox(height: 12),
        _buildNumpadRow(['.', '0', 'BACK'], model, totalAmount),
        const SizedBox(height: 16),
        // Done button to dismiss numpad
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () {
              setState(() {
                _activeInput = null;
              });
              // Unfocus all inputs
              FocusScope.of(context).unfocus();
            },
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.emeraldPrimary.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Done",
              style: TextStyle(
                color: AppTheme.emeraldPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumpadRow(
    List<String> keys,
    AddExpenseViewModel model,
    double totalAmount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key == 'BACK') {
          return _buildNumpadKey(
            child: Icon(
              Icons.backspace_outlined,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            onTap: () {
              _onNumpadBackspace();
              _commitValueToModel(model, totalAmount);
            },
          );
        } else if (key == '.') {
          return _buildNumpadKey(
            child: Text(
              '.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _onNumpadDecimal(),
          );
        } else {
          return _buildNumpadKey(
            child: Text(
              key,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              _onNumpadDigit(int.parse(key));
              _commitValueToModel(model, totalAmount);
            },
          );
        }
      }).toList(),
    );
  }

  Widget _buildNumpadKey({required Widget child, required VoidCallback onTap}) {
    return SizedBox(
      width: 56,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(child: child),
        ),
      ),
    );
  }

  void _commitValueToModel(AddExpenseViewModel model, double totalAmount) {
    final ctrl = _activeController;
    if (ctrl == null) return;

    final value = double.tryParse(ctrl.text) ?? 0;

    switch (_activeInput) {
      case _ActiveInput.myPercent:
        model.setCustomPercentage(value, totalAmount);
        break;
      case _ActiveInput.myAmount:
        model.setCustomAmount(value, totalAmount);
        break;
      case _ActiveInput.partnerPercent:
        model.setCustomPercentage(100 - value, totalAmount);
        break;
      case _ActiveInput.partnerAmount:
        model.setCustomAmount(totalAmount - value, totalAmount);
        break;
      case null:
        break;
    }
  }
}

/// Custom slider thumb with 6 dots inside a green circle
class _DottedSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const _DottedSliderThumbShape({this.thumbRadius = 14});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw the green circle
    final circlePaint = Paint()
      ..color = AppTheme.emeraldPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, circlePaint);

    // Draw 6 dark dots (2 columns x 3 rows)
    final dotPaint = Paint()
      ..color = const Color(0xFF05100A)
      ..style = PaintingStyle.fill;

    const double dotRadius = 2.5;
    const double horizontalSpacing = 6.0;
    const double verticalSpacing = 5.0;

    // Column positions (centered around the thumb center)
    final double col1 = center.dx - horizontalSpacing / 2;
    final double col2 = center.dx + horizontalSpacing / 2;

    // Row positions (centered around the thumb center)
    final double row1 = center.dy - verticalSpacing;
    final double row2 = center.dy;
    final double row3 = center.dy + verticalSpacing;

    // Draw dots
    canvas.drawCircle(Offset(col1, row1), dotRadius, dotPaint);
    canvas.drawCircle(Offset(col2, row1), dotRadius, dotPaint);
    canvas.drawCircle(Offset(col1, row2), dotRadius, dotPaint);
    canvas.drawCircle(Offset(col2, row2), dotRadius, dotPaint);
    canvas.drawCircle(Offset(col1, row3), dotRadius, dotPaint);
    canvas.drawCircle(Offset(col2, row3), dotRadius, dotPaint);
  }
}
