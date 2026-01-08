import 'package:flutter/material.dart';
import 'package:couple_balance/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/add_expense_viewmodel.dart';

class AddExpenseScreen extends StatelessWidget {
  final String partnerUid; // Passed from parent or context

  const AddExpenseScreen({super.key, required this.partnerUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddExpenseViewModel()..init(partnerUid),
      child: _AddExpenseContent(partnerUid: partnerUid),
    );
  }
}

class _AddExpenseContent extends StatefulWidget {
  final String partnerUid;
  const _AddExpenseContent({required this.partnerUid});

  @override
  State<_AddExpenseContent> createState() => _AddExpenseContentState();
}

class _AddExpenseContentState extends State<_AddExpenseContent> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AddExpenseViewModel>(context);
    final state = viewModel.state;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.addExpense)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount Input
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.amount('₺'),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      // fillColor handled by Theme
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Split Options
                  Column(
                    children: [
                      _SplitOptionCard(
                        title: AppLocalizations.of(context)!.youPaidSplit,
                        isSelected:
                            viewModel.selectedOption ==
                            SplitOption.youPaidSplit,
                        onTap: () =>
                            viewModel.setSplitOption(SplitOption.youPaidSplit),
                        icon: Icons.call_split,
                      ),
                      const SizedBox(height: 8),
                      _SplitOptionCard(
                        title: AppLocalizations.of(context)!.youPaidFull,
                        isSelected:
                            viewModel.selectedOption == SplitOption.youPaidFull,
                        onTap: () =>
                            viewModel.setSplitOption(SplitOption.youPaidFull),
                        icon: Icons.arrow_downward,
                      ),
                      const SizedBox(height: 8),
                      _SplitOptionCard(
                        title: AppLocalizations.of(
                          context,
                        )!.partnerPaidSplit(viewModel.partnerName),
                        isSelected:
                            viewModel.selectedOption ==
                            SplitOption.partnerPaidSplit,
                        onTap: () => viewModel.setSplitOption(
                          SplitOption.partnerPaidSplit,
                        ),
                        icon: Icons.call_split,
                        isPartner: true,
                      ),
                      const SizedBox(height: 8),
                      _SplitOptionCard(
                        title: AppLocalizations.of(
                          context,
                        )!.partnerPaidFull(viewModel.partnerName),
                        isSelected:
                            viewModel.selectedOption ==
                            SplitOption.partnerPaidFull,
                        onTap: () => viewModel.setSplitOption(
                          SplitOption.partnerPaidFull,
                        ),
                        icon: Icons.arrow_upward,
                        isPartner: true,
                      ),
                    ],
                  ),

                  // Dynamic Explanation
                  if (_amountController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4),
                      child: Text(
                        viewModel.getDescriptionText(
                          double.tryParse(_amountController.text) ?? 0,
                        ),
                        style: TextStyle(
                          color: Colors.pinkAccent[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Note Input
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.whatIsItFor,
                      hintText: AppLocalizations.of(context)!.expenseHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Options
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                                AppLocalizations.of(context)!.tagFood,
                                AppLocalizations.of(context)!.tagCoffee,
                                AppLocalizations.of(context)!.tagGroceries,
                                AppLocalizations.of(context)!.tagRent,
                                AppLocalizations.of(context)!.tagTransport,
                                AppLocalizations.of(context)!.tagDate,
                                AppLocalizations.of(context)!.tagBills,
                                AppLocalizations.of(context)!.tagShopping,
                              ]
                              .map(
                                (option) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ActionChip(
                                    label: Text(option),
                                    backgroundColor: Theme.of(
                                      context,
                                    ).cardColor,
                                    side: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    onPressed: () {
                                      _noteController.text = option;
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image Action
                  ListTile(
                    leading: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(AppLocalizations.of(context)!.addReceiptPhoto),
                    subtitle: state.selectedImage != null
                        ? Text(AppLocalizations.of(context)!.imageSelected)
                        : null,
                    tileColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () => _showImagePickerModal(context, viewModel),
                  ),
                  if (state.selectedImage != null) ...[
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            state.selectedImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => viewModel.removeImage(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () async {
                          final amount = double.tryParse(
                            _amountController.text,
                          );
                          if (amount == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.validAmountError,
                                ),
                              ),
                            );
                            return;
                          }

                          final success = await viewModel.saveExpense(
                            amount: amount,
                            note: _noteController.text,
                            receiverUid: widget.partnerUid,
                          );

                          if (!context.mounted) return;
                          if (success) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: viewModel.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppLocalizations.of(context)!.addExpense,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  void _showImagePickerModal(
    BuildContext context,
    AddExpenseViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.gallery),
              onTap: () {
                viewModel.pickImage(ImageSource.gallery);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.camera),
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
}

class _SplitOptionCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final bool isPartner;

  const _SplitOptionCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    this.isPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).hintColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.pinkAccent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
