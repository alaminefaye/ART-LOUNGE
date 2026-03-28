import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/cart.dart';
import '../../services/menu_service.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../config/app_brand.dart';
import '../menu/products_screen.dart';
import '../menu/product_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../orders/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showBackButton;
  final int? targetOrderId;

  const HomeScreen({
    super.key,
    this.showBackButton = false,
    this.targetOrderId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _brandGold = Color(0xFFD0A030);
  final MenuService _menuService = MenuService();
  List<Category> _categories = [];
  List<Product> _products = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _menuService.getCategories(),
        _menuService.getProducts(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _products = results[1] as List<Product>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_selectedCategoryId != null) {
      return _products
          .where((p) => p.categorieId == _selectedCategoryId && p.disponible)
          .toList();
    }
    return _products.where((p) => p.disponible).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 17) return 'Bon après-midi';
    return 'Bonsoir';
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('pizza')) return Icons.local_pizza;
    if (name.contains('burger')) return Icons.lunch_dining;
    if (name.contains('boisson') || name.contains('drink')) {
      return Icons.local_bar;
    }
    if (name.contains('dessert')) return Icons.cake;
    if (name.contains('pâte') || name.contains('pasta')) {
      return Icons.ramen_dining;
    }
    if (name.contains('salade')) return Icons.eco;
    if (name.contains('grill') || name.contains('bbq')) {
      return Icons.outdoor_grill;
    }
    if (name.contains('entrée') || name.contains('entree')) {
      return Icons.restaurant;
    }
    if (name.contains('plat')) return Icons.dinner_dining;
    return Icons.restaurant_menu;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = authService.currentUser?.name ?? 'Invité';
    final userPhone = authService.currentUser?.phone ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header fixe (gradient doré) ──────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD0A030), Color(0xFFB07018)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                22,
                MediaQuery.of(context).padding.top + 18,
                22,
                24,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (widget.showBackButton)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppBrand.displayName,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            child: userPhone.isNotEmpty
                                ? Text(
                                    userPhone[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.showBackButton) ...[
                    const SizedBox(height: 18),
                    // Afficher un résumé du panier pour le staff
                    Consumer<Cart>(
                      builder: (context, cart, child) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CartScreen(
                                  showBackButton: true,
                                  targetOrderId: widget.targetOrderId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Panier de la commande',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                              alpha: 0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${cart.itemCount} produits - ${Formatters.formatCurrency(cart.total)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Barre de recherche
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(0, 6),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Trouvez vos plats',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon:
                            Icon(Icons.search, color: Colors.grey[500]),
                        suffixIcon: const Icon(
                          Icons.tune,
                          color: Color(0xFFD0A030),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenu scrollable ────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),

                            // Section Categories
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Catégories',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ProductsScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Tout →',
                                      style: TextStyle(color: _brandGold),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Liste horizontale des catégories
                            SizedBox(
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                itemCount: _categories.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    final bool isSelected =
                                        _selectedCategoryId == null;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          right: 12.0, bottom: 5),
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _selectedCategoryId = null),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _brandGold
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Colors.black
                                                  .withValues(alpha: 0.06),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isSelected
                                                    ? _brandGold.withValues(
                                                        alpha: 0.3)
                                                    : Colors.black.withValues(
                                                        alpha: 0.08),
                                                offset: const Offset(0, 10),
                                                blurRadius: 22,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Tout',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final category = _categories[index - 1];
                                  final isSelected =
                                      _selectedCategoryId == category.id;

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        right: 12.0, bottom: 5),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedCategoryId =
                                              category.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? _brandGold
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                            color: Colors.black
                                                .withValues(alpha: 0.06),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSelected
                                                  ? _brandGold.withValues(
                                                      alpha: 0.3)
                                                  : Colors.black.withValues(
                                                      alpha: 0.08),
                                              offset: const Offset(0, 10),
                                              blurRadius: 22,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getCategoryIcon(category.nom),
                                              size: 16,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              category.nom,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Section New Dishes
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Nouveaux plats',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ProductsScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Tout →',
                                      style: TextStyle(color: _brandGold),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Grille de produits
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: _buildProductsGrid(),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    final filtered = _searchQuery.isEmpty
        ? _filteredProducts
        : _filteredProducts
              .where((p) => p.nom.toLowerCase().contains(_searchQuery))
              .toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text('No dishes found', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.70,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final product = filtered[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit avec ombre noire
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product_${product.id}',
                      child: product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFFFF0DC),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/app_icon.png',
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/app_icon.png',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Info du produit
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.nom,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: _brandGold, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '4.8(163)',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '20 min',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            Formatters.formatCurrency(product.prix),
                            style: const TextStyle(
                              color: _brandGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AbsorbPointer(
                          absorbing: false,
                          child: GestureDetector(
                            onTap: product.disponible
                                ? () {
                                    _addToCart(product);
                                  }
                                : null,
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (_) {},
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: product.disponible
                                    ? _brandGold
                                    : Colors.grey[700],
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: product.disponible
                                    ? [
                                        BoxShadow(
                                          color:
                                              _brandGold.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _addToCart(Product product) {
    if (!product.disponible) return;

    try {
      final cart = Provider.of<Cart>(context, listen: false);
      cart.addProduct(product);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.nom} added to cart'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout au panier: $e');
    }
  }
}
