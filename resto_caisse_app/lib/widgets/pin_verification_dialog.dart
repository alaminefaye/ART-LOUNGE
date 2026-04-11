import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class PinVerificationDialog extends StatefulWidget {
  final String title;
  final bool requireAdmin;

  const PinVerificationDialog({super.key, required this.title, this.requireAdmin = false});

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  String currentInput = '';
  String? errorMessage;
  bool isLoading = false;

  void onKeyTap(String digit) {
    if (isLoading) return;
    if (currentInput.length < 4) {
      setState(() {
        currentInput += digit;
        errorMessage = null;
      });
      if (currentInput.length == 4) {
        _verifyPin();
      }
    }
  }

  void onBackspace() {
    if (isLoading) return;
    if (currentInput.isNotEmpty) {
      setState(() => currentInput = currentInput.substring(0, currentInput.length - 1));
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.verifyPin(currentInput);

    if (!mounted) return;

    if (result['success']) {
      if (widget.requireAdmin) {
        final currentUser = authService.currentUser;
        if (currentUser == null || (!currentUser.hasRole('admin') && !currentUser.hasRole('superadmin') && !currentUser.hasRole('manager'))) {
          setState(() {
            isLoading = false;
            errorMessage = 'Droits administrateur requis';
            currentInput = '';
          });
          return;
        }
      }
      Navigator.pop(context, true);
    } else {
      setState(() {
        isLoading = false;
        errorMessage = result['message'] ?? 'Code PIN incorrect';
        currentInput = '';
      });
    }
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
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(32),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppTheme.brandGold),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Veuillez saisir votre code PIN pour confirmer cette action.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
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
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 32),
            if (isLoading)
              const CircularProgressIndicator(color: AppTheme.brandGold)
            else
              Column(
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
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
        )
      ],
    );
  }
}
