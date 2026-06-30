import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/product_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseService _fbService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();

  String _keyword = '';
  double? _minPrice;
  double? _maxPrice;

  bool _isLoading = false;
  List<Product> _searchResults = [];

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    List<Product> baseResults;
    if (_keyword.isEmpty) {
      baseResults = await _fbService.getProducts();
    } else {
      baseResults = await _fbService.searchProducts(_keyword);
    }

    final filtered = baseResults.where((p) {
      final double currentMin = _minPrice ?? 0.0;
      final double currentMax = _maxPrice ?? double.infinity;
      return p.price >= currentMin && p.price <= currentMax;
    }).toList();

    setState(() {
      _searchResults = filtered;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Search')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search items or sellers...',
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
                    suffixIcon: _keyword.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _keyword = '');
                              _performSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _keyword = val.trim());
                    _performSearch();
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Price Range (RM)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Min Price',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal.shade100),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => _minPrice = double.tryParse(val));
                          _performSearch();
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '—',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Max Price',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.teal.shade100),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => _maxPrice = double.tryParse(val));
                          _performSearch();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No items match your criteria.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return Card(
                        child: ListTile(
                          leading:
                              item.imageBase64 != null &&
                                  item.imageBase64!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    base64Decode(item.imageBase64!),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.shopping_bag,
                                      color: Colors.teal,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.shopping_bag,
                                  color: Colors.teal,
                                ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Seller: ${item.sellerName ?? "Anonymous"}',
                          ),
                          trailing: Text(
                            'RM ${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              '/content',
                              arguments: {'product': item},
                            );
                            _performSearch();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
