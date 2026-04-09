import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isError = false;
  bool _isLoading = false;
  String _errorMessage = 'Code PIN incorrect';

  // Used only for first-time PIN creation (two-step: enter + confirm)
  String? _firstPin;
  bool _isConfirming = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  bool get _isFirstTime {
    final authService = Provider.of<AuthService>(context, listen: false);
    return !(authService.currentUser?.hasPin ?? false);
  }

  void _onKeyTap(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _isError = false;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _submitPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onClear() {
    setState(() => _pin = '');
  }

  Future<void> _submitPin() async {
    if (_isLoading) return;
    // Guard: widget may have been disposed during the 150ms delay
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    final firstTime = _isFirstTime;

    if (firstTime) {
      // --- First-time PIN creation flow ---
      if (!_isConfirming) {
        // Step 1: store first entry and ask for confirmation
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
        return;
      }

      // Step 2: confirm
      if (_pin != _firstPin) {
        _showError('Les codes ne correspondent pas');
        setState(() {
          _isConfirming = false;
          _firstPin = null;
        });
        return;
      }

      // PINs match — save to backend
      setState(() => _isLoading = true);
      final result = await authService.setPin(_pin);
      if (!mounted) return;

      if (result['success'] == true) {
        // setPin updated currentUser.hasPin; now unlock (sets activeServeur)
        final valid = await authService.verifyPin(_pin);
        if (mounted && !valid) {
          setState(() => _isLoading = false);
          _showError('Erreur inattendue. Réessayez.');
        }
      } else {
        setState(() => _isLoading = false);
        _showError(
          result['message'] as String? ?? 'Impossible de créer le PIN',
        );
      }
      return;
    }

    // --- Normal PIN verification ---
    setState(() => _isLoading = true);
    final valid = await authService.verifyPin(_pin);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!valid) {
      _showError('Code PIN incorrect');
    }
  }

  void _showError(String message) {
    setState(() {
      _isError = true;
      _errorMessage = message;
      _pin = '';
    });
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isError = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final firstTime = _isFirstTime;

    String title;
    String subtitle;
    if (firstTime) {
      if (_isConfirming) {
        title = 'Confirmer votre PIN';
        subtitle = 'Entrez à nouveau votre code à 4 chiffres';
      } else {
        title = 'Créer votre PIN';
        subtitle = 'Choisissez un code à 4 chiffres';
      }
    } else {
      title = 'Code PIN';
      subtitle = user != null ? 'Bonjour, ${user.name}' : 'Entrez votre PIN';
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!firstTime)
            TextButton.icon(
              onPressed: () {
                Provider.of<AuthService>(context, listen: false).logout();
              },
              icon: const Icon(Icons.logout, size: 18, color: Colors.black54),
              label: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brandGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.brandGold.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  user?.initials ?? '?',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandGold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 36),

            // PIN dots with shake animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final shake = _isError
                    ? ((_shakeAnimation.value * 10) % 2 - 1) * 8
                    : 0.0;
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isError
                          ? Colors.red
                          : filled
                          ? AppTheme.brandGold
                          : Colors.transparent,
                      border: Border.all(
                        color: _isError
                            ? Colors.red
                            : filled
                            ? AppTheme.brandGold
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_isError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(
                  color: AppTheme.brandGold,
                  strokeWidth: 2.5,
                ),
              ),

            const Spacer(),

            // Numeric keypad
            _buildKeypad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeyRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeyRow(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildClearKey(), _buildKey('0'), _buildDeleteKey()],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildKey).toList(),
    );
  }

  Widget _buildKey(String digit) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _onKeyTap(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return GestureDetector(
      onTap: _isLoading ? null : _onDelete,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 22,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildClearKey() {
    return GestureDetector(
      onTap: _isLoading ? null : _onClear,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'C',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
