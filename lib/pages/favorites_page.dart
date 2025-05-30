import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import 'product_detail_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please sign in to view your favorites'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('favorites')
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

        final favoriteItems = snapshot.data?.docs ?? [];

        if (favoriteItems.isEmpty) {
          return const Center(child: Text('You have no favorites yet'));
        }

        return ListView.builder(
          itemCount: favoriteItems.length,
          itemBuilder: (context, index) {
            final item = favoriteItems[index].data() as Map<String, dynamic>;

            // Create a Product object from the Firestore data
            final product = Product(
              id: item['productId'],
              title: item['title'] ?? 'Unknown Product',
              price: item['price'] ?? 0.0,
              description: item['description'] ?? '',
              category: item['category'] ?? '',
              image: item['image'] ?? '',
              rating: item['rating'] ?? {'rate': 0.0, 'count': 0},
            );

            return ListTile(
              leading: Image.network(
                product.image,
                width: 50,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported),
              ),
              title: Text(product.title),
              subtitle: Text('\$${product.price}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('favorites')
                      .doc(user.uid)
                      .collection('products')
                      .doc(favoriteItems[index].id)
                      .delete();
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(product: product),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}