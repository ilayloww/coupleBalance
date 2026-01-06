import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../models/transaction_model.dart';

class AddExpenseViewModel extends ChangeNotifier {
  final AddExpenseScreenState _state = AddExpenseScreenState();
  AddExpenseScreenState get state => _state;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
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
      // 1. Upload Image if exists
      String? photoUrl;
      if (_state.selectedImage != null) {
        try {
          final ref = firebase_storage.FirebaseStorage.instance
              .ref()
              .child('expenses')
              .child(_auth.currentUser!.uid)
              .child('${DateTime.now().toIso8601String()}.jpg');

          await ref.putFile(_state.selectedImage!);
          photoUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint("Image upload failed: $e");
          // Continue without image or handle error
        }
      }

      // 2. Create Transaction Object
      final newTx = TransactionModel(
        id: '', // Firestore generates this
        senderUid: _auth.currentUser!.uid,
        receiverUid: receiverUid,
        amount: amount,
        note: note,
        photoUrl: photoUrl,
        timestamp: DateTime.now(),
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
