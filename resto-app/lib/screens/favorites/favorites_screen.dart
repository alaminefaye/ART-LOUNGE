import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/favorites.dart';
import '../../models/product.dart';
import '../../models/cart.dart';
import '../../utils/formatters.dart';
import '../menu/product_detail_screen.dart';
import '../../widgets/app_header.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const Color _brandGold = Color(0xFFD0A030);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient (no back button, it's a tab)
            const AppHeader(
              title: 'Mes Favoris',
              showBackButton: false,
            ),
            // Content
            Expanded(
              child: Consumer<Favorites>(
                builder: (context, favorites, _) {
                  debugPrint(
                    '📋 FavoritesScreen rebuild - Nombre de favoris: ${favorites.products.length}',
                  );
                  if (favorites.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  offset: const Offset(0, 10),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite_border,
                              size: 60,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucun favori',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez des produits à vos favoris',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: favorites.products.length,
                      itemBuilder: (context, index) {
                        final product = favorites.products[index];
                        return _buildFavoriteItem(context, product);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, Product product) {
    final favorites = Provider.of<Favorites>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 5,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFFFFF0DC),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _brandGold,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/app_icon.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/app_icon.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 15),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.formatCurrency(product.prix),
                      style: const TextStyle(
                        color: _brandGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  // Bouton favoris
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(0, 10),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        favorites.removeFavorite(product);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bouton ajouter au panier
                  if (product.disponible)
                    Container(
                      decoration: BoxDecoration(
                        color: _brandGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _brandGold.withValues(alpha: 0.4),
                            offset: const Offset(2, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          cart.addProduct(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.nom} ajouté au panier'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
