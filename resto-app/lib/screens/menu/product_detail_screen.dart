import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../models/cart.dart';
import '../../models/favorites.dart';
import '../../utils/formatters.dart';
import '../orders/cart_screen.dart';
import '../../widgets/app_header.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color _brandGold = Color(0xFFD0A030);
  static const Color _brandGoldDark = Color(0xFFB08010);
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient
            Consumer<Favorites>(
              builder: (context, favorites, _) {
                final isFavorite = favorites.isFavorite(widget.product);
                return AppHeader(
                  title: widget.product.nom,
                  titleFontSize: 18,
                  actions: [
                    HeaderActionButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      onTap: () {
                        favorites.toggleFavorite(widget.product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorite
                                  ? '${widget.product.nom} retiré des favoris'
                                  : '${widget.product.nom} ajouté aux favoris',
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: const Color(0xFFD0A030),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image du produit avec effet 3D
                    Hero(
                      tag: 'product_${widget.product.id}',
                      child: Container(
                        height: 260,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: widget.product.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.product.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: const Color(0xFFFFF0DC),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: _brandGold,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                        'assets/app_icon.png',
                                        fit: BoxFit.cover,
                                      ),
                                )
                              : Image.asset(
                                  'assets/app_icon.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),

                    // Informations du produit (style home)
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nom du produit
                          Text(
                            widget.product.nom,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Prix
                          Text(
                            Formatters.formatCurrency(widget.product.prix),
                            style: const TextStyle(
                              color: _brandGold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Statut de disponibilité
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF6EC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: widget.product.disponible
                                            ? Colors.green
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (widget.product.disponible
                                                        ? Colors.green
                                                        : Colors.red)
                                                    .withValues(alpha: 0.6),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.product.disponible
                                          ? 'Disponible'
                                          : 'Rupture de stock',
                                      style: TextStyle(
                                        color: widget.product.disponible
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.star, color: _brandGold, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '4.8 (163)',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.access_time,
                                color: Colors.grey[700],
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '20 min',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Description
                          if (widget.product.description != null &&
                              widget.product.description!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.product.description!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),

                          // Quantité
                          const Text(
                            'Quantité',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Bouton diminuer
                              _buildQuantityButton(
                                icon: Icons.remove,
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),

                              // Quantité
                              Container(
                                width: 48,
                                alignment: Alignment.center,
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              // Bouton augmenter
                              _buildQuantityButton(
                                icon: Icons.add,
                                onPressed: () => setState(() => _quantity++),
                                isAdd: true,
                              ),

                              const Spacer(),

                              // Prix total
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF6EC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _brandGold.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  Formatters.formatCurrency(
                                    widget.product.prix * _quantity,
                                  ),
                                  style: const TextStyle(
                                    color: _brandGold,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Bouton Ajouter au panier
                          GestureDetector(
                            onTap: widget.product.disponible
                                ? () => _addToCart(context)
                                : null,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: widget.product.disponible
                                    ? const LinearGradient(
                                        colors: [_brandGold, _brandGoldDark],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.grey.shade700,
                                          Colors.grey.shade800,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: widget.product.disponible
                                    ? [
                                        BoxShadow(
                                          color: _brandGold.withValues(
                                            alpha: 0.4,
                                          ),
                                          offset: const Offset(4, 4),
                                          blurRadius: 8,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          offset: const Offset(-2, -2),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_shopping_cart,
                                    size: 20,
                                    color: widget.product.disponible
                                        ? Colors.white
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ajouter au panier',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: widget.product.disponible
                                          ? Colors.white
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isAdd = false,
  }) {
    final isEnabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isAdd ? _brandGold : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: isAdd
                        ? _brandGold.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isAdd ? Colors.white : Colors.black87,
          size: 20,
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    final cart = Provider.of<Cart>(context, listen: false);

    // Ajouter le produit plusieurs fois selon la quantité
    for (int i = 0; i < _quantity; i++) {
      cart.addProduct(widget.product);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$_quantity x ${widget.product.nom} ajouté${_quantity > 1 ? 's' : ''} au panier',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Voir le panier',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }
}
