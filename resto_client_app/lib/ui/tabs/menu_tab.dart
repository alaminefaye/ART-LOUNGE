import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../core/api_config.dart';
import '../../services/menu_service.dart';
import '../../state/cart_state.dart';
import '../../state/auth_state.dart';
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.isAuthenticated
                          ? (auth.userName ?? 'Client')
                          : 'Bienvenue',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: AppTheme.text),
              ),
              const SizedBox(width: 6),
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
              hintText: 'Search food…',
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 10),
            Text(
              'API: ${ApiConfig.baseUrl}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
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
                for (final c in _categories)
                  _CategoryChip(
                    label: c.nom,
                    selected: _selectedCategoryId == c.id,
                    onTap: () => setState(() => _selectedCategoryId = c.id),
                  ),
              ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See all',
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
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                  ? const SizedBox.shrink()
                  : CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description?.trim().isNotEmpty == true
                      ? product.description!
                      : 'Best choice for you',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(product.disponible ? 'Order Now' : 'Indispo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                        (product.imageUrl == null || product.imageUrl!.isEmpty)
                        ? Container(color: Colors.white.withValues(alpha: 0.06))
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
                      child: const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Colors.white,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        priceLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(product.disponible ? 'Add' : 'Indispo'),
                    ),
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
