import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as path;

class SyncService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();

  /// Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Upload image to Firebase Storage
  /// Returns the download URL or null if failed
  Future<String?> uploadImage(String imagePath, String itemId) async {
    final uid = _userId;
    if (uid == null) return null;
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final fileName = '${itemId}_${path.basename(imagePath)}';
        final ref = _storage.ref('users/$uid/receipts/$fileName');
        
        await ref.putFile(file);
        return await ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('SyncService: Image upload failed: $e');
    }
    return null;
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String? imageUrl) async {
    if (imageUrl == null) return;
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      debugPrint('SyncService: Image delete failed (non-critical): $e');
    }
  }
}
