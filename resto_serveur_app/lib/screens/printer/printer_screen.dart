import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/invoice.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/printer_service.dart';

class PrinterScreen extends StatefulWidget {
  final Order order;
  final String? serveurName;

  const PrinterScreen({super.key, required this.order, this.serveurName});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final PrinterService _printerService = PrinterService();
  final OrderService _orderService = OrderService();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isLoadingDevices = false;
  bool _isPrinting = false;
  bool _isLoadingInvoice = false;
  Invoice? _invoice;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _loadInvoice();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoadingDevices = true);
    try {
      final devices = await _printerService.getDevices();
      final connected = await _printerService.isConnected();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isConnected = connected;
          _isLoadingDevices = false;
          if (devices.isNotEmpty && _selectedDevice == null) {
            // Pre-select known printer patterns
            _selectedDevice = devices.firstWhere(
              (d) =>
                  d.name?.toLowerCase().contains('printer') == true ||
                  d.name?.toLowerCase().contains('pos') == true ||
                  d.name?.toLowerCase().contains('thermal') == true ||
                  d.name?.toLowerCase().contains('a7n') == true,
              orElse: () => devices.first,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDevices = false;
          _errorMessage = 'Erreur Bluetooth : $e';
        });
      }
    }
  }

  Future<void> _loadInvoice() async {
    setState(() => _isLoadingInvoice = true);
    try {
      final invoice = await _orderService.getInvoice(widget.order.id);
      if (mounted) {
        setState(() {
          _invoice = invoice;
          _isLoadingInvoice = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingInvoice = false);
      }
    }
  }

  Future<void> _connectDevice() async {
    if (_selectedDevice == null) return;
    setState(() {
      _statusMessage = 'Connexion à ${_selectedDevice!.name}...';
      _errorMessage = null;
    });
    try {
      await _printerService.connect(_selectedDevice!);
      final connected = await _printerService.isConnected();
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _statusMessage = connected
              ? 'Connecté à ${_selectedDevice!.name}'
              : 'Connexion échouée';
          _errorMessage = connected ? null : 'Impossible de se connecter';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = null;
          _errorMessage = 'Erreur de connexion : $e';
        });
      }
    }
  }

  Future<void> _printKitchenOrder() async {
    setState(() {
      _isPrinting = true;
      _errorMessage = null;
      _statusMessage = 'Impression du bon de commande...';
    });
    try {
      await _printerService.printKitchenOrder(
        widget.order,
        serveurName: widget.serveurName,
      );
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _statusMessage = 'Bon de commande imprimé !';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _statusMessage = null;
          _errorMessage = 'Erreur d\'impression : $e';
        });
      }
    }
  }

  Future<void> _printReceipt() async {
    if (_invoice == null) {
      setState(
        () => _errorMessage = 'Facture non disponible pour cette commande',
      );
      return;
    }
    setState(() {
      _isPrinting = true;
      _errorMessage = null;
      _statusMessage = 'Impression de la facture...';
    });
    try {
      await _printerService.printReceipt(
        _invoice!,
        serveurName: widget.serveurName,
      );
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _statusMessage = 'Facture imprimée !';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _statusMessage = null;
          _errorMessage = 'Erreur d\'impression : $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text('Impression')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary card
            _buildOrderSummary(),
            const SizedBox(height: 16),

            // Bluetooth section
            _buildBluetoothSection(),
            const SizedBox(height: 16),

            // Print options
            _buildPrintOptions(),
            const SizedBox(height: 16),

            // Status / Error messages
            if (_statusMessage != null) _buildStatusBanner(),
            if (_errorMessage != null) _buildErrorBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final order = widget.order;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppTheme.brandGold),
              const SizedBox(width: 8),
              Text(
                'Commande #${order.id}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (order.table != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Table ${order.table!.numero}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandGold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.serveurName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Serveur : ${widget.serveurName}',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
          const Divider(height: 20),
          if (order.produits != null)
            ...order.produits!.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(
                      '${item.quantite}x ',
                      style: const TextStyle(
                        color: AppTheme.brandGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(child: Text(item.produitNom)),
                    Text(
                      _fmtCurrency(item.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                _fmtCurrency(order.montantTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppTheme.brandGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bluetooth,
                color: _isConnected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 8),
              const Text(
                'Imprimante Bluetooth',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? Colors.green.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isConnected ? 'Connectée' : 'Déconnectée',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isConnected ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoadingDevices)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppTheme.brandGold),
              ),
            )
          else if (_devices.isEmpty)
            Column(
              children: [
                const Text(
                  'Aucune imprimante appairée trouvée.\nActivez le Bluetooth et appairez votre imprimante dans les paramètres Android.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadDevices,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualiser'),
                ),
              ],
            )
          else ...[
            // Device dropdown
            DropdownButtonFormField<BluetoothDevice>(
              initialValue: _selectedDevice,
              decoration: InputDecoration(
                labelText: 'Sélectionner imprimante',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: _devices
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        d.name ?? d.address ?? 'Appareil inconnu',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (d) => setState(() => _selectedDevice = d),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadDevices,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Rafraîchir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? null : _connectDevice,
                    icon: Icon(
                      _isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth,
                      size: 18,
                    ),
                    label: Text(_isConnected ? 'Connectée' : 'Connecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected
                          ? Colors.green
                          : AppTheme.brandGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrintOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.print, color: AppTheme.brandGold),
              SizedBox(width: 8),
              Text(
                'Options d\'impression',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Print kitchen order
          _PrintOption(
            icon: Icons.kitchen,
            title: 'Bon de commande',
            subtitle: 'Ticket pour la cuisine avec les articles',
            enabled: !_isPrinting,
            color: Colors.deepOrange,
            onTap: _printKitchenOrder,
          ),
          const SizedBox(height: 10),

          // Print receipt/invoice
          _PrintOption(
            icon: Icons.receipt_long,
            title: 'Reçu client',
            subtitle: _isLoadingInvoice
                ? 'Chargement de la facture...'
                : _invoice != null
                ? 'Total : ${_fmtCurrency(_invoice!.montantTotal)}'
                : 'Facture non disponible',
            enabled: !_isPrinting && !_isLoadingInvoice && _invoice != null,
            color: AppTheme.brandGold,
            onTap: _printReceipt,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(color: Colors.green.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtCurrency(double amount) {
    final n = amount.round();
    if (n == 0) return '0 FCFA';
    final digits = n.abs().toString();
    final rev = digits.split('').reversed.join();
    final parts = <String>[];
    for (var i = 0; i < rev.length; i += 3) {
      final end = i + 3 <= rev.length ? i + 3 : rev.length;
      parts.add(rev.substring(i, end));
    }
    final spaced = parts.join(' ');
    final forward = spaced.split('').reversed.join();
    return '$forward FCFA';
  }
}

class _PrintOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _PrintOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: enabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled ? Colors.black54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.print_rounded,
                color: enabled ? color : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
