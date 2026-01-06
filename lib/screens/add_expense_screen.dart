import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/add_expense_viewmodel.dart';

class AddExpenseScreen extends StatelessWidget {
  final String partnerUid; // Passed from parent or context

  const AddExpenseScreen({super.key, required this.partnerUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddExpenseViewModel(),
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
      appBar: AppBar(
        title: const Text('Add Expense', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₺)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Note Input
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'What is it for?',
                  hintText: 'e.g. Dinner, Rent',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),

              // Image Action
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Colors.purpleAccent,
                ),
                title: const Text('Add Receipt / Photo'),
                subtitle: state.selectedImage != null
                    ? const Text('Image selected')
                    : null,
                tileColor: Colors.purple[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => _showImagePickerModal(context, viewModel),
              ),
              if (state.selectedImage != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    state.selectedImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        final amount = double.tryParse(_amountController.text);
                        if (amount == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
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
                    : const Text(
                        'Add Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
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
              title: const Text('Gallery'),
              onTap: () {
                viewModel.pickImage(ImageSource.gallery);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
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
