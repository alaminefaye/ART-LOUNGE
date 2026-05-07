import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/menu_service.dart';
import '../../state/cart_state.dart';
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

  final _money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Product> get _filteredProducts {
    final q = _query.trim().toLowerCase();
    return _products.where((p) {
      if (_selectedCategoryId != null && p.categorieId != _selectedCategoryId) return false;
      if (q.isEmpty) return true;
      return p.nom.toLowerCase().contains(q) || (p.description ?? '').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Menu'),
            actions: [
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un plat…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      selected: _selectedCategoryId == null,
                      label: const Text('Tout'),
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    ),
                  ),
                  for (final c in _categories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        selected: _selectedCategoryId == c.id,
                        label: Text(c.nom),
                        onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredProducts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Aucun produit')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              sliver: SliverList.separated(
                itemCount: _filteredProducts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = _filteredProducts[index];
                  return _ProductCard(
                    product: p,
                    priceLabel: _money.format(p.prix),
                    onAdd: p.disponible ? () => context.read<CartState>().add(p) : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.priceLabel,
    required this.onAdd,
  });

  final Product product;
  final String priceLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  color: AppTheme.backgroundColor,
                  child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                      ? const Icon(Icons.fastfood, color: AppTheme.brandGold)
                      : CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.fastfood, color: AppTheme.brandGold),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (product.description != null && product.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          priceLabel,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.brandGold,
                              ),
                        ),
                        ElevatedButton(
                          onPressed: onAdd,
                          child: Text(product.disponible ? 'Ajouter' : 'Indispo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

