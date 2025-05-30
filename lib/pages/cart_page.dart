import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please sign in to view your cart'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('products')
          .orderBy('addedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final cartItems = snapshot.data?.docs ?? [];

        if (cartItems.isEmpty) {
          return const Center(child: Text('Your cart is empty'));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: Image.network(
                      item['image'] ?? '',
                      width: 50,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                    ),
                    title: Text(item['title'] ?? 'Unknown Item'),
                    subtitle: Text('\$${item['price']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('carts')
                            .doc(user.uid)
                            .collection('products')
                            .doc(cartItems[index].id)
                            .delete();
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: cartItems.isEmpty ? null : () {
                  // Implement checkout functionality here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checkout coming soon')),
                  );
                },
                child: const Text('Checkout'),
              ),
            ),
          ],
        );
      },
    );
  }
}