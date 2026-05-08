import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/menu_service.dart';
import '../../state/cart_state.dart';
import '../../state/auth_state.dart';
import '../../state/favorites_state.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

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

  Future<void> _openNotifications() async {
    final auth = context.read<AuthState>();
    if (!auth.isAuthenticated) {
      final ok = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (ok != true || !mounted) return;
    }

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
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
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    '../resto_caisse_app/assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
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
              GestureDetector(
                onTap: _openNotifications,
                behavior: HitTestBehavior.opaque,
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
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.text,
                  ),
                ),
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
                    child: (product.imageUrlCacheBusted == null)
                        ? Container(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: const Icon(
                              Icons.fastfood,
                              color: AppTheme.textMuted,
                              size: 34,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.imageUrlCacheBusted!,
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
                        child: (product.imageUrlCacheBusted == null)
                            ? Container(
                                color: Colors.white.withValues(alpha: 0.06),
                              )
                            : CachedNetworkImage(
                                imageUrl: product.imageUrlCacheBusted!,
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
  int _stars = 0;
  double? _avgRating;
  int _ratingCount = 0;
  bool _ratingLoading = true;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRating());
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRating() async {
    setState(() => _ratingLoading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('produits/${widget.product.id}/rating');
      final data = res.data;
      if (!mounted) return;

      if (data is Map && data['data'] is Map) {
        final d = Map<String, dynamic>.from(data['data'] as Map);
        final moyenne = d['moyenne'];
        final total = d['total'];
        setState(() {
          _avgRating = (moyenne is num)
              ? moyenne.toDouble()
              : double.tryParse('$moyenne');
          _ratingCount = (total is num)
              ? total.toInt()
              : int.tryParse('$total') ?? 0;
        });
      }
    } on DioException {
    } finally {
      if (mounted) setState(() => _ratingLoading = false);
    }
  }

  Widget _buildAverageStars(double avg) {
    final clamped = avg.clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final idx = i + 1;
        final icon = clamped >= idx
            ? Icons.star
            : (clamped >= idx - 0.5 ? Icons.star_half : Icons.star_border);
        final color = icon == Icons.star_border
            ? Colors.white.withValues(alpha: 0.40)
            : const Color(0xFFFFC23C);
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(icon, size: 18, color: color),
        );
      }),
    );
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
                  child: (p.imageUrlCacheBusted == null)
                      ? Container(
                          color: Colors.white.withValues(alpha: 0.06),
                          child: const Icon(
                            Icons.fastfood,
                            size: 54,
                            color: AppTheme.textMuted,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: p.imageUrlCacheBusted!,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_ratingLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accent,
                            ),
                          )
                        else
                          _buildAverageStars(_avgRating ?? 0.0),
                        const SizedBox(width: 8),
                        Text(
                          _ratingLoading
                              ? '...'
                              : '${(_avgRating ?? 0.0).toStringAsFixed(1)}${_ratingCount > 0 ? ' ($_ratingCount)' : ''}',
                          style: const TextStyle(
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Votre note',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final idx = i + 1;
                        final active = idx <= _stars;
                        return GestureDetector(
                          onTap: () => setState(() => _stars = idx),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              active ? Icons.star : Icons.star_border,
                              size: 20,
                              color: active
                                  ? const Color(0xFFFFC23C)
                                  : Colors.white.withValues(alpha: 0.40),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
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

class _UserNotification {
  const _UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.readAt,
    required this.createdAt,
  });

  final int id;
  final String? type;
  final String? title;
  final String? body;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  _UserNotification copyWith({DateTime? readAt}) {
    return _UserNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  static _UserNotification fromJson(Map<String, dynamic> json) {
    return _UserNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString(),
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  int _unreadCount = 0;
  List<_UserNotification> _items = const [];

  final _date = DateFormat('dd/MM/yyyy • HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('notifications');
      final data = res.data;
      if (!mounted) return;

      if (data is Map) {
        final unread = (data['unread_count'] as num?)?.toInt() ?? 0;
        final list = data['data'];
        final items = (list is List)
            ? list
                  .whereType<Map>()
                  .map(
                    (e) => _UserNotification.fromJson(
                      Map<String, dynamic>.from(e),
                    ),
                  )
                  .toList(growable: false)
            : const <_UserNotification>[];

        setState(() {
          _unreadCount = unread;
          _items = items;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString())
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Impossible de charger les notifications'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final api = context.read<ApiClient>();
      await api.dio.post('notifications/mark-all-read');
      if (!mounted) return;
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString())
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Erreur lors du marquage')),
      );
    }
  }

  Future<void> _markRead(_UserNotification n) async {
    if (n.isRead) return;
    try {
      final api = context.read<ApiClient>();
      await api.dio.patch('notifications/${n.id}/read');
      if (!mounted) return;

      final now = DateTime.now();
      setState(() {
        _items = _items
            .map((x) => x.id == n.id ? x.copyWith(readAt: now) : x)
            .toList(growable: false);
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString())
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Erreur lors du marquage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppTheme.accent,
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
                      child: Text(
                        'Notifications${_unreadCount > 0 ? ' ($_unreadCount)' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_unreadCount > 0)
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Container(
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
                          child: const Text(
                            'Tout lire',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                  )
                else if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: const Text(
                      'Aucune notification pour le moment.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  ..._items.map((n) {
                    final title = (n.title?.trim().isNotEmpty == true)
                        ? n.title!
                        : 'Notification';
                    final body = (n.body?.trim().isNotEmpty == true)
                        ? n.body!
                        : '';
                    final date = n.createdAt;
                    final dateLabel = date != null
                        ? _date.format(date.toLocal())
                        : '';
                    return GestureDetector(
                      onTap: () => _markRead(n),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.isRead
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: n.isRead
                                ? Colors.white.withValues(alpha: 0.10)
                                : AppTheme.accent.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Icon(
                                n.isRead
                                    ? Icons.notifications_none_rounded
                                    : Icons.notifications_active_rounded,
                                color: n.isRead
                                    ? AppTheme.textMuted
                                    : AppTheme.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: n.isRead
                                          ? AppTheme.text
                                          : AppTheme.text,
                                    ),
                                  ),
                                  if (body.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      body,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                  if (dateLabel.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      dateLabel,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.55,
                                        ),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
