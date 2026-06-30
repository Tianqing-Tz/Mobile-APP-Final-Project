import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/product_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Image Helpers ────────────────────────────────────────────────────

  Future<String?> imageToBase64(String filePath) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        filePath,
        quality: 40,
        minWidth: 600,
        minHeight: 600,
      );
      if (compressed == null) return null;
      return base64Encode(compressed);
    } catch (e) {
      return null;
    }
  }

  // ─── Current User Helpers ─────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName;
  String? get currentUserEmail => _auth.currentUser?.email;

  Map<String, dynamic>? getCurrentSessionSync() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return {
      'current_user_id': user.uid,
      'current_user_name': user.displayName ?? 'User',
      'current_user_email': user.email ?? '',
    };
  }

  Future<Map<String, dynamic>?> getCurrentSession() async {
    await _auth.authStateChanges().first;
    return getCurrentSessionSync();
  }

  // ─── User Profile ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserAvatar(String uid, String base64) async {
    await _db.collection('users').doc(uid).update({'avatarBase64': base64});
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── Auth ─────────────────────────────────────────────────────────────

  Future<String?> registerUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      await cred.user?.sendEmailVerification();
      await _auth.signOut();
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email already registered!';
      return e.message ?? 'Registration failed.';
    }
  }

  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (!_auth.currentUser!.emailVerified) {
        await _auth.signOut();
        return 'Please verify your email first! Check your inbox.';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return 'Invalid credentials! Please register or check details.';
      }
      return e.message ?? 'Login failed.';
    }
  }

  Future<void> clearSession() async => await _auth.signOut();

  // ─── Products ─────────────────────────────────────────────────────────

  Future<void> insertProduct(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return;
    String? imageBase64;
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      imageBase64 = await imageToBase64(product.imagePath!);
    }
    await _db.collection('products').add({
      'title': product.title,
      'price': product.price,
      'description': product.description,
      'sellerId': user.uid,
      'sellerName': user.displayName ?? 'Anonymous',
      'sellerEmail': user.email ?? '',
      'imageBase64': imageBase64 ?? '',
      'latitude': product.latitude,
      'longitude': product.longitude,
      'status': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Product>> getProducts() async {
    final snap = await _db
        .collection('products')
        .where('status', isEqualTo: 0)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<List<Product>> searchProducts(String keyword) async {
    final all = await getProducts();
    final lower = keyword.toLowerCase();
    return all
        .where(
          (p) =>
              p.title.toLowerCase().contains(lower) ||
              (p.sellerName?.toLowerCase().contains(lower) ?? false),
        )
        .toList();
  }

  Future<void> updateProduct(Product product) async {
    if (product.firestoreId == null) return;
    String? imageBase64 = product.imageBase64;
    if (product.imagePath != null &&
        product.imagePath!.isNotEmpty &&
        product.imageBase64 == null) {
      imageBase64 = await imageToBase64(product.imagePath!);
    }
    await _db.collection('products').doc(product.firestoreId).update({
      'title': product.title,
      'price': product.price,
      'description': product.description,
      'imageBase64': imageBase64 ?? '',
    });
  }

  Future<void> deleteProduct(String firestoreId) async {
    await _db.collection('products').doc(firestoreId).delete();
    final favSnap = await _db
        .collection('favorites')
        .where('productId', isEqualTo: firestoreId)
        .get();
    for (final doc in favSnap.docs) await doc.reference.delete();
    final histSnap = await _db
        .collection('browse_history')
        .where('productId', isEqualTo: firestoreId)
        .get();
    for (final doc in histSnap.docs) await doc.reference.delete();
  }

  Future<List<Product>> getMyListedItems() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final snap = await _db
        .collection('products')
        .where('sellerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  // ─── Favorites ────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String productId) async {
    final uid = currentUserId;
    if (uid == null) return;
    final docId = '${uid}_$productId';
    final ref = _db.collection('favorites').doc(docId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': uid,
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isFavorite(String productId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    final snap = await _db
        .collection('favorites')
        .doc('${uid}_$productId')
        .get();
    return snap.exists;
  }

  Future<List<Product>> getMyFavorites() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final favSnap = await _db
        .collection('favorites')
        .where('userId', isEqualTo: uid)
        .orderBy('addedAt', descending: true)
        .get();
    final productIds = favSnap.docs
        .map((d) => d.data()['productId'] as String)
        .toList();
    if (productIds.isEmpty) return [];
    final chunks = <List<String>>[];
    for (var i = 0; i < productIds.length; i += 30) {
      chunks.add(
        productIds.sublist(
          i,
          i + 30 > productIds.length ? productIds.length : i + 30,
        ),
      );
    }
    final products = <Product>[];
    for (final chunk in chunks) {
      final snap = await _db
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      products.addAll(snap.docs.map((doc) => Product.fromFirestore(doc)));
    }
    return products;
  }

  // ─── Browse History ───────────────────────────────────────────────────

  Future<void> recordBrowseHistory(Product product) async {
    final uid = currentUserId;
    if (uid == null || product.firestoreId == null) return;
    final docId = '${uid}_${product.firestoreId}';
    await _db.collection('browse_history').doc(docId).set({
      'userId': uid,
      'productId': product.firestoreId,
      'productTitle': product.title,
      'productPrice': product.price,
      'productImageBase64': product.imageBase64 ?? '',
      'viewedAt': FieldValue.serverTimestamp(),
    });
    final snap = await _db
        .collection('browse_history')
        .where('userId', isEqualTo: uid)
        .orderBy('viewedAt', descending: true)
        .get();
    if (snap.docs.length > 50) {
      for (final doc in snap.docs.sublist(50)) await doc.reference.delete();
    }
  }

  Future<List<Map<String, dynamic>>> getBrowseHistory() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final snap = await _db
        .collection('browse_history')
        .where('userId', isEqualTo: uid)
        .orderBy('viewedAt', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      final ts = data['viewedAt'];
      data['viewed_at'] = ts is Timestamp
          ? ts.millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch;
      data['product_id'] = data['productId'];
      data['product_title'] = data['productTitle'];
      data['product_price'] = data['productPrice'];
      data['product_image_base64'] = data['productImageBase64'];
      return data;
    }).toList();
  }

  Future<void> clearBrowseHistory() async {
    final uid = currentUserId;
    if (uid == null) return;
    final snap = await _db
        .collection('browse_history')
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in snap.docs) await doc.reference.delete();
  }
}
