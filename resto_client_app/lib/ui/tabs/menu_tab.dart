import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/menu_service.dart';
import '../../state/cart_state.dart';
import '../../state/auth_state.dart';
import '../../state/favorites_state.dart';
import '../../theme/app_theme.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  bool _loading = true;
  List<Category> _categories = const [];
  List<Product> _products = const [];
  int? _selectedCategoryId;
  String _query = '';

  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final menu = context.read<MenuService>();
      final categories = await menu.fetchCategories();
      final products = await menu.fetchProducts();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _products = products;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _categories = const [];
        _products = const [];
      });
      final code = e.response?.statusCode;
      final url = e.requestOptions.uri.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur API ${code ?? ''} sur $url')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Product> get _filteredProducts {
    final q = _query.trim().toLowerCase();
    return _products
        .where((p) {
          if (_selectedCategoryId != null &&
              p.categorieId != _selectedCategoryId)
            return false;
          if (q.isEmpty) return true;
          return p.nom.toLowerCase().contains(q) ||
              (p.description ?? '').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final featured = _filteredProducts.isNotEmpty
        ? _filteredProducts.first
        : null;
    final gridProducts = _filteredProducts.take(10).toList(growable: false);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(Icons.search, color: AppTheme.text),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  auth.isAuthenticated
                      ? 'Bonjour, ${auth.userName ?? 'Client'}'
                      : 'Bonjour, bienvenue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(Icons.person, color: AppTheme.text),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: AppTheme.text),
            decoration: InputDecoration(
              hintText: 'Rechercher un plat…',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else ...[
            if (featured != null) ...[
              _FeaturedCard(
                product: featured,
                priceLabel: _money.format(featured.prix),
                onAdd: featured.disponible
                    ? () => context.read<CartState>().add(featured)
                    : null,
              ),
              const SizedBox(height: 18),
            ],
            const Text(
              'Catégorie de repas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: 'Tout',
                    selected: _selectedCategoryId == null,
                    onTap: () => setState(() => _selectedCategoryId = null),
                  ),
                  for (final c in _categories.take(10))
                    _CategoryChip(
                      label: c.nom,
                      selected: _selectedCategoryId == c.id,
                      onTap: () => setState(() => _selectedCategoryId = c.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Populaire',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Voir plus',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (gridProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    'Aucun produit',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gridProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final p = gridProducts[index];
                  return _ModernProductCard(
                    product: p,
                    priceLabel: _money.format(p.prix),
                    onAdd: p.disponible
                        ? () => context.read<CartState>().add(p)
                        : null,
                  );
                },
              ),
            const SizedBox(height: 90),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? AppTheme.accent
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0 : 0.10),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.text,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.product,
    required this.priceLabel,
    required this.onAdd,
  });

  final Product product;
  final String priceLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 112,
                    height: 148,
                    child:
                        (product.imageUrl == null || product.imageUrl!.isEmpty)
                        ? Container(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: const Icon(
                              Icons.fastfood,
                              color: AppTheme.textMuted,
                              size: 34,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.nom,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description?.trim().isNotEmpty == true
                            ? product.description!
                            : 'Délicieux et préparé sur commande.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Seulement',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  priceLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onAdd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                          child: Text(
                            product.disponible ? 'Commander' : 'Indispo',
                            style: const TextStyle(fontWeight: FontWeight.w900),
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
      ),
    );
  }
}

class _ModernProductCard extends StatelessWidget {
  const _ModernProductCard({
    required this.product,
    required this.priceLabel,
    required this.onAdd,
  });

  final Product product;
  final String priceLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesState>();
    final isFav = fav.isFavorite(product.id);
    final radius = BorderRadius.circular(18);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child:
                            (product.imageUrl == null ||
                                product.imageUrl!.isEmpty)
                            ? Container(
                                color: Colors.white.withValues(alpha: 0.06),
                              )
                            : CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: GestureDetector(
                          onTap: () =>
                              context.read<FavoritesState>().toggle(product.id),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isFav ? AppTheme.accent : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nom,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description?.trim().isNotEmpty == true
                            ? product.description!
                            : '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFFC23C),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '4.8',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Text(
                              priceLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: onAdd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              product.disponible ? 'Commander' : 'Indispo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
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
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = context.read<CartState>().noteOf(widget.product.id);
      if (existing != null && existing.trim().isNotEmpty) {
        _noteCtrl.text = existing;
      }
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final fav = context.watch<FavoritesState>();
    final isFav = fav.isFavorite(p.id);
    final money = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final priceLabel = money.format(p.prix);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.text,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.read<FavoritesState>().toggle(p.id),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppTheme.accent : AppTheme.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 16 / 11,
                  child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                      ? Container(
                          color: Colors.white.withValues(alpha: 0.06),
                          child: const Icon(
                            Icons.fastfood,
                            size: 54,
                            color: AppTheme.textMuted,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: p.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                p.nom,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: Color(0xFFFFC23C)),
                        SizedBox(width: 6),
                        Text(
                          '4.8',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        priceLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  (p.description?.trim().isNotEmpty == true)
                      ? p.description!
                      : 'Aucune description.',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.text),
                decoration: const InputDecoration(
                  labelText: 'Note pour la cuisine (optionnel)',
                  prefixIcon: Icon(Icons.edit_note, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Quantité',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  _QtyPill(
                    qty: _qty,
                    onMinus: _qty <= 1 ? null : () => setState(() => _qty -= 1),
                    onPlus: () => setState(() => _qty += 1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !p.disponible
                      ? null
                      : () {
                          final cart = context.read<CartState>();
                          final existing = cart.quantityOf(p.id);
                          if (existing == 0) {
                            cart.add(p);
                            if (_qty > 1) {
                              cart.setQuantity(p.id, _qty);
                            }
                          } else {
                            cart.setQuantity(p.id, existing + _qty);
                          }
                          cart.setNote(p.id, _noteCtrl.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ajouté au panier (x$_qty)'),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    p.disponible ? 'Ajouter au panier' : 'Indisponible',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyPill extends StatelessWidget {
  const _QtyPill({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyIconButton(icon: Icons.remove, onTap: onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              qty.toString(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          _QtyIconButton(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _QtyIconButton extends StatelessWidget {
  const _QtyIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? Colors.white.withValues(alpha: 0.35)
              : AppTheme.text,
        ),
      ),
    );
  }
}
