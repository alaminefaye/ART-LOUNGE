import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart'; // Import pour Order
import '../models/cart.dart';
import '../services/menu_service.dart';
import '../services/order_service.dart'; // Import pour OrderService
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/cart_ticket.dart';
import 'order_management_screen.dart';
import 'caisse/session_management_screen.dart';
import '../widgets/printer_settings_dialog.dart';

class PosScreen extends StatefulWidget {
  final VoidCallback? onRequireSessionCheck;
  const PosScreen({super.key, this.onRequireSessionCheck});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final MenuService _menuService = MenuService();
  final OrderService _orderService = OrderService();
  List<Category> _categories = [];
  List<Product> _products = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;
  Timer? _refreshTimer;
  int _lastOrderCount = 0;
  bool _showCartInMobile = false; // Pour afficher le panier en plein écran sur mobile

  @override
  void initState() {
    super.initState();
    _loadData();
    // Système d'actualisation auto toutes les 30s
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadData(isAutoRefresh: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool isAutoRefresh = false}) async {
    if (!isAutoRefresh) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _menuService.getCategories(),
        _menuService.getProducts(),
        _orderService.getCurrentOrders(),
      ]);

      if (mounted) {
        final currentOrders = results[2] as List<Order>;
        
        // Notification si nouvelle commande client (en attente)
        if (isAutoRefresh && currentOrders.length > _lastOrderCount) {
          final newOrders = currentOrders.where((o) => o.statut == OrderStatus.attente).toList();
          if (newOrders.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('${newOrders.length} nouvelles commandes clients !'),
                  ],
                ),
                backgroundColor: AppTheme.brandGold,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'VOIR',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => const OrderManagementScreen()));
                  },
                ),
              ),
            );
          }
        }

        setState(() {
          _categories = results[0] as List<Category>;
          _products = (results[1] as List<Product>).where((p) => p.disponible).toList();
          _lastOrderCount = currentOrders.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Product> get _filteredProducts {
    var list = _products;
    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categorieId == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) => p.nom.toLowerCase().contains(_searchQuery)).toList();
    }
    return list;
  }

  Widget _buildCategoryItem(BuildContext context, String title, int? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandGold : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.brandGold.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.brandGold)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1100;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          // Mobile FAB to show cart
          floatingActionButton: isMobile ? Consumer<Cart>(
            builder: (context, cart, _) => FloatingActionButton.extended(
              onPressed: () => setState(() => _showCartInMobile = true),
              backgroundColor: AppTheme.brandGold,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                '${Formatters.formatCurrency(cart.total)} (${cart.itemCount})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ) : null,
          body: Stack(
            children: [
              Row(
                children: [
                  // Left side: Main Content
                  Expanded(
                    child: Column(
                      children: [
                        // Top Header (Logo, Search, User, Actions)
                        _buildHeader(context, isMobile),

                        // Categories Row
                        Container(
                          height: isMobile ? 80 : 90,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 32, 
                            vertical: isMobile ? 8 : 16
                          ),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length + 1,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildCategoryItem(context, 'Tous', null);
                              final c = _categories[index - 1];
                              return _buildCategoryItem(context, c.nom, c.id);
                            },
                          ),
                        ),

                        // Products Grid
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32),
                            child: _filteredProducts.isEmpty
                                ? const Center(child: Text('Aucun produit trouvé', style: TextStyle(fontSize: 18, color: Colors.grey)))
                                : GridView.builder(
                                    padding: const EdgeInsets.only(bottom: 80),
                                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: isMobile ? 180 : 220,
                                      childAspectRatio: isMobile ? 0.75 : 0.8,
                                      crossAxisSpacing: isMobile ? 12 : 24,
                                      mainAxisSpacing: isMobile ? 12 : 24,
                                    ),
                                    itemCount: _filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final p = _filteredProducts[index];
                                      return _buildProductCard(context, p, isMobile);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Desktop side: Ticket
                  if (!isMobile) 
                    const SizedBox(width: 400, child: CartTicket()),
                ],
              ),
              
              // Mobile Cart Overlay
              if (isMobile && _showCartInMobile)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _showCartInMobile = false),
                          child: Container(width: 60, color: Colors.transparent, child: const Icon(Icons.chevron_left, color: Colors.white, size: 40)),
                        ),
                        const Expanded(child: CartTicket()),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = authService.currentUser?.name ?? 'Caissier';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32, 
        vertical: isMobile ? 12 : 24
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), offset: const Offset(0, 4), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset('assets/logo.png', height: isMobile ? 32 : 48),
              if (!isMobile) ...[
                const SizedBox(width: 48),
                Expanded(child: _buildSearchField()),
              ],
              const Spacer(),
              _buildHeaderActions(context, userName, isMobile),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
            _buildSearchField(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Rechercher...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
    );
  }

  void _showChangePinDialog() {
    // Step 1: saisir l'ancien PIN | Step 2: saisir le nouveau PIN | Step 3: confirmer
    int step = 1; // 1=ancien, 2=nouveau, 3=confirmer
    String oldPin = '';
    String newPin = '';
    String confirmPin = '';
    String currentInput = '';
    String? errorMessage;
    bool isLoading = false;

    final Map<int, String> stepTitles = {
      1: 'Ancien code PIN',
      2: 'Nouveau code PIN',
      3: 'Confirmer le PIN',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (statefulCtx, setStateDialog) {
            void onKeyTap(String digit) {
              if (currentInput.length < 4) {
                setStateDialog(() {
                  currentInput += digit;
                  errorMessage = null;
                });
                if (currentInput.length == 4) {
                  // Auto-valider après le 4e chiffre
                  Future.delayed(const Duration(milliseconds: 200), () {
                    setStateDialog(() {
                      if (step == 1) {
                        oldPin = currentInput;
                        currentInput = '';
                        step = 2;
                      } else if (step == 2) {
                        newPin = currentInput;
                        currentInput = '';
                        step = 3;
                      } else if (step == 3) {
                        confirmPin = currentInput;
                        if (newPin != confirmPin) {
                          errorMessage = 'Les codes PIN ne correspondent pas';
                          currentInput = '';
                          step = 2;
                          newPin = '';
                        } else {
                          // Soumettre
                          isLoading = true;
                        }
                      }
                    });

                    if (isLoading) {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      authService.setPin(oldPin, newPin).then((result) {
                        if (!ctx.mounted) return;
                        if (result['success']) {
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code PIN modifié avec succès ✓'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          setStateDialog(() {
                            isLoading = false;
                            errorMessage = result['message'] ?? 'Erreur lors de la modification';
                            currentInput = '';
                            step = 1;
                            oldPin = '';
                            newPin = '';
                          });
                        }
                      });
                    }
                  });
                }
              }
            }

            void onBackspace() {
              if (currentInput.isNotEmpty) {
                setStateDialog(() => currentInput = currentInput.substring(0, currentInput.length - 1));
              }
            }

            Widget buildPinDots() {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < currentInput.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppTheme.brandGold : Colors.transparent,
                      border: Border.all(
                        color: filled ? AppTheme.brandGold : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  );
                }),
              );
            }

            Widget buildKeypadBtn(String label, VoidCallback onTap) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.backgroundColor,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }

            Widget buildKeypad() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    buildKeypadBtn('1', () => onKeyTap('1')),
                    buildKeypadBtn('2', () => onKeyTap('2')),
                    buildKeypadBtn('3', () => onKeyTap('3')),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    buildKeypadBtn('4', () => onKeyTap('4')),
                    buildKeypadBtn('5', () => onKeyTap('5')),
                    buildKeypadBtn('6', () => onKeyTap('6')),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    buildKeypadBtn('7', () => onKeyTap('7')),
                    buildKeypadBtn('8', () => onKeyTap('8')),
                    buildKeypadBtn('9', () => onKeyTap('9')),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    const SizedBox(width: 64),
                    buildKeypadBtn('0', () => onKeyTap('0')),
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: IconButton(
                        onPressed: onBackspace,
                        icon: const Icon(Icons.backspace_outlined, size: 26, color: Colors.grey),
                      ),
                    ),
                  ]),
                ],
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.pin, color: AppTheme.brandGold),
                  const SizedBox(width: 8),
                  Text(
                    stepTitles[step]!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Étapes visuelles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = i + 1 == step;
                        final done = i + 1 < step;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: done ? AppTheme.brandGold
                                : active ? AppTheme.brandGold.withValues(alpha: 0.5)
                                : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                        ]),
                      ),
                    isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: AppTheme.brandGold),
                          )
                        : buildPinDots(),
                    const SizedBox(height: 24),
                    if (!isLoading) buildKeypad(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderActions(BuildContext context, String userName, bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMobile) ...[
          GestureDetector(
            onTap: () => _showChangePinDialog(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.brandGold.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: AppTheme.brandGold, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Session Ouverte', style: TextStyle(color: Colors.green.shade600, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.lock_outline, size: 13, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        
        // Bouton Refresh
        IconButton(
          onPressed: () => _loadData(),
          icon: const Icon(Icons.refresh, color: AppTheme.brandGold),
          tooltip: 'Actualiser',
        ),
        
        // Bouton Printer Settings
        IconButton(
          onPressed: () => _showPrinterSettings(),
          icon: const Icon(Icons.print, color: AppTheme.brandGold),
          tooltip: 'Imprimante',
        ),
        
        // Popup Menu pour les actions sur mobile ou Row sur Desktop
        if (isMobile)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.brandGold),
            onSelected: (val) => _handleMenuAction(val),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'orders', child: Row(children: [Icon(Icons.receipt_long, size: 20), SizedBox(width: 8), Text('Commandes')])),
              const PopupMenuItem(value: 'caisse', child: Row(children: [Icon(Icons.point_of_sale, size: 20, color: Colors.green), SizedBox(width: 8), Text('Ma Caisse')])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text('Déconnexion')])),
            ],
          )
        else ...[
          const SizedBox(width: 8),
          _buildActionButton(
            onPressed: () => _handleMenuAction('orders'),
            icon: Icons.receipt_long,
            label: 'Commandes',
            color: AppTheme.brandGold,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            onPressed: () => _handleMenuAction('caisse'),
            icon: Icons.point_of_sale,
            label: 'Ma Caisse',
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          _buildLogoutButton(context),
        ],
      ],
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  void _handleMenuAction(String action) {
    if (action == 'orders') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderManagementScreen()));
    } else if (action == 'caisse') {
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionManagementScreen(
            onSessionOpened: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
              widget.onRequireSessionCheck?.call();
            },
          ),
        ),
      );
    } else if (action == 'logout') {
      _confirmLogout();
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Assurez-vous d\'avoir clôturé votre session de caisse.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await Provider.of<AuthService>(context, listen: false).logout();
    }
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Tooltip(
      message: 'Déconnexion',
      child: InkWell(
        onTap: _confirmLogout,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 22),
        ),
      ),
    );
  }

  void _showPrinterSettings() {
    showDialog(
      context: context,
      builder: (ctx) => const PrinterSettingsDialog(),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, bool isMobile) {
    final cart = Provider.of<Cart>(context, listen: false);
    return GestureDetector(
      onTap: () {
        cart.addProduct(product);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.nom} ajouté au panier'),
            duration: const Duration(seconds: 1),
            backgroundColor: AppTheme.brandGold,
            behavior: isMobile ? SnackBarBehavior.fixed : SnackBarBehavior.floating,
            width: isMobile ? null : 300,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 4),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppTheme.backgroundColor, child: const Center(child: CircularProgressIndicator())),
                        errorWidget: (context, url, error) => Image.asset('assets/app_icon.png', fit: BoxFit.cover),
                      )
                    : Image.asset('assets/app_icon.png', fit: BoxFit.cover),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      Formatters.formatCurrency(product.prix),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.brandGold),
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
}
