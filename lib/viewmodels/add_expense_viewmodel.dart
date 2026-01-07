import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/transaction_model.dart';

enum SplitOption {
  youPaidSplit,
  youPaidFull,
  partnerPaidSplit,
  partnerPaidFull,
}

class AddExpenseViewModel extends ChangeNotifier {
  final AddExpenseScreenState _state = AddExpenseScreenState();
  AddExpenseScreenState get state => _state;

  SplitOption _selectedOption = SplitOption.youPaidSplit;
  SplitOption get selectedOption => _selectedOption;

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
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        imageQuality: 50,
      );
      if (image != null) {
        _state.selectedImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<bool> saveExpense({
    required double amount,
    required String note,
    required String receiverUid, // Partner's UID
  }) async {
    if (_auth.currentUser == null) return false;

    setLoading(true);
    try {
      // 1. Encode Image to Base64 if exists
      String? photoUrl;
      if (_state.selectedImage != null) {
        try {
          final bytes = await _state.selectedImage!.readAsBytes();
          photoUrl = base64Encode(bytes);
        } catch (e) {
          debugPrint("Image encoding failed: $e");
        }
      }

      // 2. Create Transaction Object
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
