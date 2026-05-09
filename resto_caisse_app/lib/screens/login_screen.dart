import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _pin = '';
  bool _isLoading = false;

  void _onKeypadTap(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == 4) {
        _login();
      }
    }
  }

  void _onBackspaceTap() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _login() async {
    if (_pin.length != 4) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.loginWithPinOnly(_pin);

    setState(() => _isLoading = false);

    if (!result['success']) {
      setState(() {
        _pin = ''; // Reset pin on failure
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Code PIN incorrect',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPinDots({double dotSize = 24, double spacing = 12}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppTheme.brandGold : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppTheme.brandGold : Colors.grey.shade400,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypadButton(
    String text,
    VoidCallback onTap, {
    required double buttonSize,
    required double buttonPadding,
    required double fontSize,
  }) {
    return Padding(
      padding: EdgeInsets.all(buttonPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad({
    required double buttonSize,
    required double buttonPadding,
    required double fontSize,
  }) {
    final slotWidth = buttonSize + (buttonPadding * 2);
    final backspaceIconSize = buttonSize * 0.4;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(
              '1',
              () => _onKeypadTap('1'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
            _buildKeypadButton(
              '2',
              () => _onKeypadTap('2'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
            _buildKeypadButton(
              '3',
              () => _onKeypadTap('3'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(
              '4',
              () => _onKeypadTap('4'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
            _buildKeypadButton(
              '5',
              () => _onKeypadTap('5'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
            _buildKeypadButton(
              '6',
              () => _onKeypadTap('6'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(
              '7',
              () => _onKeypadTap('7'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
            _buildKeypadButton(
              '8',
              () => _onKeypadTap('8'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
            _buildKeypadButton(
              '9',
              () => _onKeypadTap('9'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: slotWidth), // Spacer for empty button placeholder
            _buildKeypadButton(
              '0',
              () => _onKeypadTap('0'),
              buttonSize: buttonSize,
              buttonPadding: buttonPadding,
              fontSize: fontSize,
            ),
            Padding(
              padding: EdgeInsets.all(buttonPadding),
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: IconButton(
                  onPressed: _onBackspaceTap,
                  icon: Icon(
                    Icons.backspace_outlined,
                    size: backspaceIconSize,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth < 500
              ? constraints.maxWidth - 24
              : 450.0;
          final isCompact =
              constraints.maxHeight < 740 || constraints.maxWidth < 900;
          final contentPadding = isCompact ? 22.0 : 40.0;
          final buttonSize = isCompact ? 62.0 : 80.0;
          final buttonPadding = isCompact ? 5.0 : 8.0;
          final keypadFontSize = isCompact ? 24.0 : 28.0;
          final logoHeight = isCompact ? 90.0 : 120.0;
          final titleSize = isCompact ? 21.0 : 24.0;
          final dotSize = isCompact ? 20.0 : 24.0;
          final dotSpacing = isCompact ? 8.0 : 12.0;
          final gapAfterPin = isCompact ? 22.0 : 40.0;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: cardWidth,
                padding: EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: logoHeight,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.storefront,
                        color: AppTheme.brandGold,
                        size: 72,
                      ),
                    ),
                    SizedBox(height: isCompact ? 20 : 30),
                    Text(
                      'Entrez votre Code PIN',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Saisissez votre code PIN à 4 chiffres pour accéder à la caisse.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 13 : 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: isCompact ? 20 : 30),
                    if (_isLoading)
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: AppTheme.brandGold,
                        ),
                      )
                    else
                      _buildPinDots(dotSize: dotSize, spacing: dotSpacing),
                    SizedBox(height: gapAfterPin),
                    _buildKeypad(
                      buttonSize: buttonSize,
                      buttonPadding: buttonPadding,
                      fontSize: keypadFontSize,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
