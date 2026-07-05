import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? firestoreId;
  final int? id;
  final String title;
  final double price;
  final String description;
  final String? sellerId;
  final String? sellerName;
  final String? sellerEmail;
  final String? imagePath;
  final String? imageBase64;
  final double? latitude;
  final double? longitude;
  final String? videoUrl;
  Product({
    this.firestoreId,
    this.id,
    required this.title,
    required this.price,
    required this.description,
    this.sellerId,
    this.sellerName,
    this.sellerEmail,
    this.imagePath,
    this.imageBase64,
    this.latitude,
    this.longitude,
    this.videoUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      firestoreId: doc.id,
      title: data['title'] ?? '',
      price: (data['price'] as num).toDouble(),
      description: data['description'] ?? '',
      sellerId: data['sellerId'],
      sellerName: data['sellerName'],
      sellerEmail: data['sellerEmail'],
      imageBase64: data['imageBase64'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      videoUrl: data['video_url'],
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      title: map['title'] ?? '',
      price: (map['price'] as num).toDouble(),
      description: map['description'] ?? '',
      sellerId: map['seller_id']?.toString(),
      sellerName: map['seller_name'],
      sellerEmail: map['seller_email'],
      imagePath: map['image_path'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      videoUrl: map['video_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'price': price,
      'description': description,
      if (sellerId != null) 'seller_id': sellerId,
      if (sellerName != null) 'seller_name': sellerName,
      if (sellerEmail != null) 'seller_email': sellerEmail,
      'image_path': imagePath,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (videoUrl != null) 'video_url': videoUrl,
    };
  }
}
