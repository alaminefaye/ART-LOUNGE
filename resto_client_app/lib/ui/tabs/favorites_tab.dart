import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/menu_service.dart';
import '../../state/favorites_state.dart';
import '../../theme/app_theme.dart';
import 'menu_tab.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  bool _loading = true;
  List<Product> _products = const [];

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
      final products = await menu.fetchProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (_) {
      if (mounted) setState(() => _products = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesState>();
    final favProducts = _products.where((p) => fav.isFavorite(p.id)).toList(growable: false);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Favoris',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: fav.ids.isEmpty ? null : () => fav.clear(),
                icon: const Icon(Icons.delete_outline, color: AppTheme.text),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (favProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.favorite_border, color: AppTheme.textMuted, size: 34),
                  SizedBox(height: 10),
                  Text('Aucun favori', style: TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            )
          else
            for (final p in favProducts) ...[
              _FavoriteCard(product: p, priceLabel: _money.format(p.prix)),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.product, required this.priceLabel});

  final Product product;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesState>();
    final isFav = fav.isFavorite(product.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                      ? Container(
                          color: Colors.white.withValues(alpha: 0.06),
                          child: const Icon(Icons.fastfood, color: AppTheme.textMuted),
                        )
                      : CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: Colors.white.withValues(alpha: 0.06)),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceLabel,
                      style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => fav.toggle(product.id),
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: AppTheme.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

