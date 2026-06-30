import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';
import 'map_picker_screen.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _fbService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  String _title = '';
  double _price = 0.0;
  String _description = '';
  String? _selectedImagePath;
  LatLng? _pickedLocation;
  bool _isFavCached = false;
  bool _sessionLoaded = false;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionLoaded) {
      _loadSession();
    }
  }

  void _loadSession() async {
    setState(() => _sessionLoaded = true);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Product? product = args?['product'] as Product?;
    if (product != null && product.firestoreId != null) {
      if (product.latitude != null && product.longitude != null) {
        setState(
          () => _pickedLocation = LatLng(product.latitude!, product.longitude!),
        );
      }
      await _fbService.recordBrowseHistory(product);
      if (!mounted) return;
      final bool fav = await _fbService.isFavorite(product.firestoreId!);
      if (mounted) setState(() => _isFavCached = fav);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  Widget _buildImage(String? localPath, String? base64, double height) {
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder(height),
      );
    }
    if (base64 != null && base64.isNotEmpty) {
      return Image.memory(
        base64Decode(base64),
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder(height),
      );
    }
    return _imagePlaceholder(height);
  }

  Widget _imagePlaceholder(double height) {
    return SizedBox(
      height: height,
      child: const Center(
        child: Icon(Icons.image, size: 60, color: Colors.teal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isCreateMode = args != null && args['action'] == 'create';
    final bool isEditMode = args != null && args['action'] == 'edit';
    final Product? existingProduct = args?['product'] as Product?;
    final bool isOwner =
        existingProduct != null &&
        _sessionLoaded &&
        _fbService.currentUserId == existingProduct.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCreateMode
              ? 'Post Second-hand Item'
              : (isEditMode ? 'Edit Item' : 'Item Details'),
        ),
        actions: [
          if (!isCreateMode &&
              !isEditMode &&
              existingProduct != null &&
              isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(existingProduct.firestoreId!),
            ),
          if (!isCreateMode &&
              !isEditMode &&
              existingProduct != null &&
              !isOwner &&
              _sessionLoaded)
            IconButton(
              icon: Icon(
                _isFavCached ? Icons.favorite : Icons.favorite_border,
                color: _isFavCached ? Colors.red : Colors.white,
              ),
              onPressed: () async {
                if (existingProduct.firestoreId != null) {
                  await _fbService.toggleFavorite(existingProduct.firestoreId!);
                  setState(() => _isFavCached = !_isFavCached);
                }
              },
            ),
        ],
      ),
      body: isCreateMode
          ? _buildForm(null)
          : isEditMode && existingProduct != null
          ? _buildForm(existingProduct)
          : existingProduct != null
          ? _buildDetails(existingProduct, isOwner)
          : const Center(child: Text('Data Error')),
    );
  }

  Widget _buildForm(Product? product) {
    final bool isEdit = product != null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _selectedImagePath != null
                      ? _buildImage(_selectedImagePath, null, 150)
                      : isEdit && product.imageBase64 != null
                      ? _buildImage(null, product.imageBase64, 150)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.teal,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Upload Item Image (Tap to browse)',
                              style: TextStyle(color: Colors.teal),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.teal),
              title: Text(
                _pickedLocation == null
                    ? 'Set Meetup Location'
                    : 'Location Selected',
              ),
              subtitle: _pickedLocation != null
                  ? Text(
                      '${_pickedLocation!.latitude.toStringAsFixed(4)}, ${_pickedLocation!.longitude.toStringAsFixed(4)}',
                    )
                  : const Text('Tap to pick a location on map'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapPickerScreen(),
                  ),
                );
                if (result != null) {
                  setState(() => _pickedLocation = result);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: isEdit ? product.title : '',
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              validator: (val) =>
                  val!.isEmpty ? 'Please enter item name' : null,
              onSaved: (val) => _title = val!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: isEdit ? product.price.toString() : '',
              decoration: const InputDecoration(
                labelText: 'Expected Price (RM)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (val) => val!.isEmpty ? 'Please enter price' : null,
              onSaved: (val) => _price = double.tryParse(val!) ?? 0.0,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: isEdit ? product.description : '',
              decoration: const InputDecoration(
                labelText: 'Detailed Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onSaved: (val) => _description = val ?? '',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      _formKey.currentState!.save();
                      setState(() => _isSubmitting = true);
                      try {
                        if (isEdit) {
                          await _fbService.updateProduct(
                            Product(
                              firestoreId: product.firestoreId,
                              title: _title,
                              price: _price,
                              description: _description,
                              sellerId: product.sellerId,
                              sellerName: product.sellerName,
                              sellerEmail: product.sellerEmail,
                              imagePath: _selectedImagePath,
                              latitude: _pickedLocation?.latitude,
                              longitude: _pickedLocation?.longitude,
                              imageBase64: _selectedImagePath == null
                                  ? product.imageBase64
                                  : null,
                            ),
                          );
                        } else {
                          await _fbService.insertProduct(
                            Product(
                              title: _title,
                              price: _price,
                              description: _description,
                              imagePath: _selectedImagePath,
                              latitude: _pickedLocation?.latitude,
                              longitude: _pickedLocation?.longitude,
                            ),
                          );
                        }
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEdit ? 'Save Changes' : 'Confirm Post',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(Product product, bool isOwner) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(null, product.imageBase64, 200),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RM ${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOwner ? 'Your Listing' : 'Seller: ${product.sellerName}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          if (product.latitude != null && product.longitude != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Meetup Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      product.latitude!,
                      product.longitude!,
                    ),
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.secondhand_market',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(product.latitude!, product.longitude!),
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (isOwner)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Information'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                ),
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/content',
                    arguments: {'action': 'edit', 'product': product},
                  );
                  if (result == true && mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.email),
                label: const Text('Contact Seller via Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Simulating email to: ${product.sellerEmail}',
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String firestoreId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Take Down?'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _fbService.deleteProduct(firestoreId);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text(
              'Confirm Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
