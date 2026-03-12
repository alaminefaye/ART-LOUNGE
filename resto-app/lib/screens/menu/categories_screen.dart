import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/menu_service.dart';
import 'products_screen.dart';
import '../../widgets/app_header.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final MenuService _menuService = MenuService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _menuService.getCategories();
      debugPrint('Catégories chargées: ${categories.length}');

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });

        // Afficher un message si aucune catégorie
        if (categories.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune catégorie disponible'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Erreur lors du chargement des catégories: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(top: false,
        child: Column(
          children: [
            AppHeader(
              title: 'Catégories',
              showBackButton: false,
              actions: [
                HeaderActionButton(
                  icon: Icons.refresh,
                  onTap: _loadCategories,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD0A030)),
                    )
                  : _categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
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
                                  Icons.category_outlined,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Aucune catégorie disponible',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFD0A030),
                          backgroundColor: Colors.white,
                          onRefresh: _loadCategories,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
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
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductsScreen(
                                            categoryId: category.id,
                                            categoryName: category.nom,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF6EC),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.black.withValues(alpha: 0.06),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  offset: const Offset(0, 4),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                category.nom[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Color(0xFFD0A030),
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  category.nom,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (category.description != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    category.description!,
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (category.produitsCount != null)
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
                                              child: Text(
                                                '${category.produitsCount}',
                                                style: const TextStyle(
                                                  color: Color(0xFFD0A030),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey[700],
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
