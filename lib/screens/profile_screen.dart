import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../services/firebase_service.dart';
import '../models/product_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _fbService = FirebaseService();
  final ImagePicker _picker = ImagePicker();
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  String? _avatarBase64;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final session = _fbService.getCurrentSessionSync();
    final uid = session?['current_user_id'];
    setState(() {
      _userName = session?['current_user_name'] ?? 'Guest';
      _userEmail = session?['current_user_email'] ?? '';
    });
    if (uid != null) {
      final doc = await _fbService.getUserDoc(uid);
      if (doc != null && doc['avatarBase64'] != null && mounted) {
        setState(() => _avatarBase64 = doc['avatarBase64']);
      }
    }
  }

  Future<void> _changeAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: 50,
        minWidth: 300,
        minHeight: 300,
      );
      if (compressed == null) return;
      final base64 = base64Encode(compressed);
      final uid = _fbService.currentUserId;
      if (uid != null) {
        await _fbService.updateUserAvatar(uid, base64);
        if (mounted) setState(() => _avatarBase64 = base64);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              await FirebaseAuth.instance.currentUser?.updateDisplayName(
                newName,
              );
              if (!mounted) return;
              setState(() => _userName = newName);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Name',
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _changeAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.teal,
                        backgroundImage: _avatarBase64 != null
                            ? MemoryImage(base64Decode(_avatarBase64!))
                            : null,
                        child: _isUploadingAvatar
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : _avatarBase64 == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _changeAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap avatar to change photo',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(_userEmail, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Name'),
                  onPressed: _showEditProfileDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bookmark_border, color: Colors.teal),
            title: const Text('My Listed Items'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToProductList(
              'My Listed Items',
              _fbService.getMyListedItems(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.teal),
            title: const Text('My Favorites'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToProductList(
              'My Favorites',
              _fbService.getMyFavorites(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.teal),
            title: const Text('Browse History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToBrowseHistory(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _fbService.clearSession();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToProductList(String title, Future<List<Product>> dataFuture) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ProductListPage(title: title, dataFuture: dataFuture),
      ),
    );
  }

  void _navigateToBrowseHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _BrowseHistoryPage(fbService: _fbService),
      ),
    );
  }
}

// ─── Product List Page ────────────────────────────────────────────────────────

class _ProductListPage extends StatelessWidget {
  final String title;
  final Future<List<Product>> dataFuture;
  const _ProductListPage({required this.title, required this.dataFuture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Product>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final product = snapshot.data![index];
              return Card(
                child: ListTile(
                  leading:
                      product.imageBase64 != null &&
                          product.imageBase64!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            base64Decode(product.imageBase64!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag,
                              color: Colors.teal,
                            ),
                          ),
                        )
                      : const Icon(Icons.shopping_bag, color: Colors.teal),
                  title: Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('RM ${product.price.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/content',
                    arguments: {'product': product},
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Browse History Page ──────────────────────────────────────────────────────

class _BrowseHistoryPage extends StatefulWidget {
  final FirebaseService fbService;
  const _BrowseHistoryPage({required this.fbService});

  @override
  State<_BrowseHistoryPage> createState() => _BrowseHistoryPageState();
}

class _BrowseHistoryPageState extends State<_BrowseHistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.fbService.getBrowseHistory();
  }

  void _reload() => setState(() {
    _historyFuture = widget.fbService.getBrowseHistory();
  });

  String _formatTime(int ms) {
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Browse History?'),
                  content: const Text(
                    'All browsing records will be permanently removed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await widget.fbService.clearBrowseHistory();
                _reload();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No browse history yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final entry = snapshot.data![index];
              final String? imageBase64 =
                  entry['product_image_base64'] as String?;
              final double price = (entry['product_price'] as num).toDouble();
              final int viewedAt = entry['viewed_at'] as int;
              return Card(
                child: ListTile(
                  leading: imageBase64 != null && imageBase64.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            base64Decode(imageBase64),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag,
                              color: Colors.teal,
                            ),
                          ),
                        )
                      : const Icon(Icons.shopping_bag, color: Colors.teal),
                  title: Text(
                    entry['product_title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('RM ${price.toStringAsFixed(2)}'),
                  trailing: Text(
                    _formatTime(viewedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () async {
                    final String productId = entry['product_id'] as String;
                    final products = await widget.fbService.getProducts();
                    final Product? product = products
                        .where((p) => p.firestoreId == productId)
                        .firstOrNull;
                    if (!mounted) return;
                    if (product != null) {
                      await Navigator.pushNamed(
                        context,
                        '/content',
                        arguments: {'product': product},
                      );
                      _reload();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This item has been removed.'),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
