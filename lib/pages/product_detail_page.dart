// lib/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isFavorite = false;
  bool _isInCart = false;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _checkCartStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('products')
          .doc(widget.product.id.toString())
          .get();

      setState(() {
        _isFavorite = doc.exists;
      });
    }
  }

  Future<void> _checkCartStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('products')
          .doc(widget.product.id.toString())
          .get();

      setState(() {
        _isInCart = doc.exists;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save favorites')),
      );
      return;
    }

    final favoriteRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(user.uid)
        .collection('products')
        .doc(widget.product.id.toString());

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      await favoriteRef.set({
        'productId': widget.product.id,
        'title': widget.product.title,
        'price': widget.product.price,
        'image': widget.product.image,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await favoriteRef.delete();
    }
  }

  Future<void> _toggleCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add items to cart')),
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('products')
        .doc(widget.product.id.toString());

    setState(() {
      _isInCart = !_isInCart;
    });

    if (_isInCart) {
      await cartRef.set({
        'productId': widget.product.id,
        'title': widget.product.title,
        'price': widget.product.price,
        'image': widget.product.image,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await cartRef.delete();
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a comment')),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      await FirebaseFirestore.instance.collection('comments').add({
        'productId': widget.product.id.toString(),
        'userId': user.uid,
        'userEmail': user.email,
        'text': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting comment: $e')),
      );
    } finally {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : null,
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Image.network(
                widget.product.image,
                fit: BoxFit.contain,
              ),
            ),

            // Product details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Category: ${widget.product.category}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(_isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart),
                      label: Text(_isInCart ? 'Remove from Cart' : 'Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _toggleCart,
                    ),
                  ),

                  // Comments section
                  const SizedBox(height: 32),
                  const Divider(),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Comment input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isSubmittingComment
                          ? const CircularProgressIndicator()
                          : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
                    ],
                  ),

                  // Comments list
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('comments')
                        .where('productId', isEqualTo: widget.product.id.toString())
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        print('snapshot error: ${snapshot.error}');
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No comments yet. Be the first to comment!'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          return ListTile(
                            title: Text(data['userEmail'] ?? 'Anonymous'),
                            subtitle: Text(data['text'] ?? ''),
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}