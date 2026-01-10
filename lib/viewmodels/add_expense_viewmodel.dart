import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/transaction_model.dart';

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
  // If I paid, this is how much Partner owes Me.
  // If Partner paid, this is how much I owe Partner.
  double _customOwedAmount = 0;
  double get customOwedAmount => _customOwedAmount;

  String _partnerName = 'Partner';
  String get partnerName => _partnerName;

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
    try {
      final doc = await _firestore.collection('users').doc(partnerUid).get();
      if (doc.exists) {
        final data = doc.data();
        _partnerName = data?['displayName'] ?? 'Partner';
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

  void setCustomOwedAmount(double amount) {
    _customOwedAmount = amount;
    notifyListeners();
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
        note: note,
        photoUrl: photoUrl,
        timestamp: DateTime.now(),
        addedByUid: _auth.currentUser!.uid,
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
