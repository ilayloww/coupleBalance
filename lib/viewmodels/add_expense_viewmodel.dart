import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/transaction_model.dart';

enum CustomSplitType { amount, percentage }

enum SplitOption {
  youPaidSplit,
  youPaidFull,
  partnerPaidSplit,
  partnerPaidFull,
  custom,
}

class AddExpenseViewModel extends ChangeNotifier {
  final AddExpenseScreenState _state = AddExpenseScreenState();
  AddExpenseScreenState get state => _state;

  SplitOption _selectedOption = SplitOption.youPaidSplit;
  SplitOption get selectedOption => _selectedOption;

  // Custom Split State
  String? _customPayerUid; // Null means "Me" (current user)
  String? get customPayerUid => _customPayerUid;

  // Who owes whom how much?
  // We will store "how much the OTHER person owes".
  double _customOwedAmount = 0;
  double get customOwedAmount => _customOwedAmount;

  // New: Split Type & Percentage
  CustomSplitType _customSplitType = CustomSplitType.amount;
  CustomSplitType get customSplitType => _customSplitType;

  double _customPercentage = 50; // default 50%
  double get customPercentage => _customPercentage;

  String _partnerName = 'Partner';
  String get partnerName => _partnerName;

  String? _partnerUid;
  String? get partnerUid => _partnerUid;

  String? _partnerPhotoUrl;
  String? get partnerPhotoUrl => _partnerPhotoUrl;

  String? get userPhotoUrl => _auth.currentUser?.photoURL;

  // Keypad State
  String _amountStr = '0';
  String get amountStr => _amountStr;

  void addDigit(int digit) {
    if (_amountStr == '0') {
      _amountStr = digit.toString();
    } else {
      // Prevent too many decimal places if needed, or max length
      if (_amountStr.contains('.')) {
        final parts = _amountStr.split('.');
        if (parts.length > 1 && parts[1].length >= 2) return; // Max 2 decimals
      }
      if (_amountStr.length >= 9) return; // Max length
      _amountStr += digit.toString();
    }
    notifyListeners();
  }

  void addDecimal() {
    if (!_amountStr.contains('.')) {
      _amountStr += '.';
      notifyListeners();
    }
  }

  void backspace() {
    if (_amountStr.length > 1) {
      _amountStr = _amountStr.substring(0, _amountStr.length - 1);
    } else {
      _amountStr = '0';
    }
    notifyListeners();
  }

  void clearAmount() {
    _amountStr = '0';
    notifyListeners();
  }

  // Categories
  final List<Map<String, dynamic>> categories = [
    {'id': 'food', 'icon': Icons.restaurant},
    {'id': 'coffee', 'icon': Icons.coffee},
    {'id': 'rent', 'icon': Icons.home},
    {'id': 'groceries', 'icon': Icons.shopping_cart},
    {'id': 'transport', 'icon': Icons.directions_car},
    {'id': 'date', 'icon': Icons.favorite},
    {'id': 'bills', 'icon': Icons.receipt_long},
    {'id': 'shopping', 'icon': Icons.shopping_bag},
    {'id': 'custom', 'icon': Icons.edit},
  ];

  String _selectedCategory = 'food';
  String get selectedCategory => _selectedCategory;

  String _customCategoryText = '';
  String get customCategoryText => _customCategoryText;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setCustomCategoryText(String text) {
    _customCategoryText = text;
    // Don't notify listeners here to avoid rebuilding on every keystroke if not needed,
    // or notify if validation state depends on it. Ideally use a Controller in UI,
    // but if we want to validate in VM:
    // notifyListeners();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> init(String partnerUid) async {
    _partnerUid = partnerUid;
    try {
      final doc = await _firestore.collection('users').doc(partnerUid).get();
      if (doc.exists) {
        final data = doc.data();
        _partnerName = data?['displayName'] ?? 'Partner';
        _partnerPhotoUrl = data?['photoUrl'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching partner name: $e");
    }
  }

  void setSplitOption(SplitOption option) {
    _selectedOption = option;
    notifyListeners();
  }

  // Custom Split Setters
  void setCustomPayer(String? uid) {
    _customPayerUid = uid;
    notifyListeners();
  }

  void setCustomOwedAmount(double amount, {double? totalAmount}) {
    _customOwedAmount = amount;
    // If totalAmount is provided, reverse calc percentage
    if (totalAmount != null && totalAmount > 0) {
      _customPercentage = (amount / totalAmount) * 100;
    }
    notifyListeners();
  }

  void setCustomSplitType(CustomSplitType type) {
    _customSplitType = type;
    notifyListeners();
  }

  void setCustomAmount(double myAmount, double totalAmount) {
    if (totalAmount <= 0) return;
    double percentage = ((myAmount / totalAmount) * 100).roundToDouble();
    // Clamp to 0-100
    if (percentage < 0) percentage = 0;
    if (percentage > 100) percentage = 100;

    _customPercentage = percentage;
    // Update owed amount (Partner's share)
    double partnerSharePercent = 100 - _customPercentage;
    _customOwedAmount = (totalAmount * partnerSharePercent) / 100;

    notifyListeners();
  }

  void setCustomPercentage(double myPercentage, double totalAmount) {
    _customPercentage = myPercentage
        .roundToDouble(); // 0 to 100 representing MY share

    // We update _customOwedAmount (what partner owes if I paid).
    // If I am the payer:
    double partnerSharePercent = 100 - _customPercentage;
    _customOwedAmount = (totalAmount * partnerSharePercent) / 100;

    notifyListeners();
  }

  void recalculateCustomSplit(double totalAmount) {
    if (_customSplitType == CustomSplitType.percentage) {
      _customOwedAmount = (totalAmount * _customPercentage) / 100;
      notifyListeners();
    }
  }

  String getDescriptionText(double amount) {
    if (amount <= 0) return '';

    switch (_selectedOption) {
      case SplitOption.youPaidSplit:
        return '$_partnerName owes you ${(amount / 2).toStringAsFixed(2)} ₺';
      case SplitOption.youPaidFull:
        return '$_partnerName owes you ${amount.toStringAsFixed(2)} ₺';
      case SplitOption.partnerPaidSplit:
        return 'You owe $_partnerName ${(amount / 2).toStringAsFixed(2)} ₺';
      case SplitOption.partnerPaidFull:
        return 'You owe $_partnerName ${amount.toStringAsFixed(2)} ₺';
      case SplitOption.custom:
        final isMePayer =
            _customPayerUid == null ||
            _customPayerUid == _auth.currentUser?.uid;
        if (isMePayer) {
          return '$_partnerName owes you ${_customOwedAmount.toStringAsFixed(2)} ₺';
        } else {
          return 'You owe $_partnerName ${_customOwedAmount.toStringAsFixed(2)} ₺';
        }
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      // Higher quality for storage upload
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 90,
      );
      if (image != null) {
        _state.selectedImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void removeImage() {
    _state.selectedImage = null;
    notifyListeners();
  }

  Future<bool> saveExpense({
    required double amount,
    required String note,
    required String receiverUid, // Partner's UID
  }) async {
    if (_auth.currentUser == null) return false;

    // Validate Custom Category
    if (_selectedCategory == 'custom' && _customCategoryText.trim().isEmpty) {
      // Validation failed - we'll handle UI feedback in the screen
      return false;
    }

    setLoading(true);
    try {
      // 1. Upload Image to Storage if exists
      String? photoUrl;
      if (_state.selectedImage != null) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('transaction_images')
              .child(_auth.currentUser!.uid)
              .child('$timestamp.jpg');

          await storageRef.putFile(_state.selectedImage!);
          photoUrl = await storageRef.getDownloadURL();
        } catch (e) {
          debugPrint("Image upload failed: $e");
          // Fail gracefully for now, but log the specific error
        }
      }

      // 2. Create Transaction Object
      double finalAmount = amount;
      String finalSender = _auth.currentUser!.uid;
      String finalReceiver = receiverUid;

      // Logic adjustments based on selection
      switch (_selectedOption) {
        case SplitOption.youPaidSplit:
          finalAmount = amount / 2;
          finalSender = _auth.currentUser!.uid;
          finalReceiver = receiverUid;
          break;
        case SplitOption.youPaidFull:
          finalAmount = amount;
          finalSender = _auth.currentUser!.uid;
          finalReceiver = receiverUid;
          break;
        case SplitOption.partnerPaidSplit:
          finalAmount = amount / 2;
          finalSender = receiverUid;
          finalReceiver = _auth.currentUser!.uid;
          break;
        case SplitOption.partnerPaidFull:
          finalAmount = amount;
          finalSender = receiverUid;
          finalReceiver = _auth.currentUser!.uid;
          break;
        case SplitOption.custom:
          finalAmount = _customOwedAmount;
          // If I paid, I am sender, Partner is receiver (Partner owes me).
          // If Partner paid, Partner is sender, I am receiver (I owe partner).
          final isMePayer =
              _customPayerUid == null ||
              _customPayerUid == _auth.currentUser?.uid;
          if (isMePayer) {
            finalSender = _auth.currentUser!.uid;
            finalReceiver = receiverUid;
          } else {
            finalSender = receiverUid;
            finalReceiver = _auth.currentUser!.uid;
          }
          break;
      }

      final newTx = TransactionModel(
        id: '', // Firestore generates this
        senderUid: finalSender,
        receiverUid: finalReceiver,
        amount: finalAmount,
        note: _selectedCategory == 'custom' ? _customCategoryText.trim() : note,
        photoUrl: photoUrl,
        timestamp: DateTime.now(),
        addedByUid: _auth.currentUser!.uid,
        category: _selectedCategory,
      );

      // 3. Save to Firestore
      await _firestore.collection('transactions').add(newTx.toMap());
      return true;
    } catch (e) {
      debugPrint("Error saving expense: $e");
      return false;
    } finally {
      setLoading(false);
    }
  }
}

class AddExpenseScreenState {
  File? selectedImage;
}
