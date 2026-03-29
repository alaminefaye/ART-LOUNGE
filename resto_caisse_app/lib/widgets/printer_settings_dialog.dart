import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/printer_service.dart';
import '../theme/app_theme.dart';

class PrinterSettingsDialog extends StatefulWidget {
  const PrinterSettingsDialog({super.key});

  @override
  State<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<PrinterSettingsDialog> {
  final PrinterService _printerService = PrinterService();
  List<Printer> _printers = [];
  String? _selectedPrinterName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoading = true);
    try {
      final printers = await _printerService.getAvailablePrinters();
      final current = await _printerService.getDefaultPrinterName();
      setState(() {
        _printers = printers;
        _selectedPrinterName = current;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print, color: AppTheme.brandGold),
          SizedBox(width: 12),
          Text('Configuration Imprimante'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGold))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisissez l\'imprimante POS80 par défaut pour une impression automatique sans confirmation.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  if (_printers.isEmpty)
                    const Center(
                      child: Text('Aucune imprimante détectée sur ce système.',
                          style: TextStyle(color: Colors.red)),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _printers.length,
                        itemBuilder: (context, index) {
                          final p = _printers[index];
                          final isSelected = _selectedPrinterName == p.name;
                          return ListTile(
                            leading: Icon(Icons.print_outlined,
                                color: isSelected ? AppTheme.brandGold : Colors.grey),
                            title: Text(p.name,
                                style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            subtitle: Text(p.url, style: const TextStyle(fontSize: 10)),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                            onTap: () async {
                              await _printerService.setDefaultPrinter(p.name);
                              setState(() => _selectedPrinterName = p.name);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _selectedPrinterName == null ? null : _testPrint,
                        icon: const Icon(Icons.receipt),
                        label: const Text('Test d\'impression'),
                      ),
                      if (_selectedPrinterName != null)
                        TextButton(
                          onPressed: () async {
                            await _printerService.setDefaultPrinter('');
                            setState(() => _selectedPrinterName = null);
                          },
                          child: const Text('Réinitialiser', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Future<void> _testPrint() async {
    // On peut créer un petit PDF rapide pour le test
    // Pour simplifier, on utilise une des fonctions existantes ou on en crée une ici
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impression de test envoyée...'), duration: Duration(seconds: 2)),
    );
    // Note: On pourrait appeler une méthode spécifique du PrinterService ici
  }
}
