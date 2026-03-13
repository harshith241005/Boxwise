import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class PinLockScreen extends StatefulWidget {
  final Widget child;
  const PinLockScreen({super.key, required this.child});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _input = '';
  bool _unlocked = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkBiometrics();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() => _canCheckBiometrics = canCheck && isDeviceSupported);
      if (_canCheckBiometrics) {
        _authenticateWithBiometrics();
      }
    } catch (_) {
      setState(() => _canCheckBiometrics = false);
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your Boxvise inventory',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        setState(() => _unlocked = true);
      }
    } catch (_) {}
  }

  void _addChar(String char) {
    if (_input.length < 4) {
      setState(() => _input += char);
      if (_input.length == 4) {
        _checkPin();
      }
    }
  }

  void _checkPin() {
    final provider = context.read<InventoryProvider>();
    if (provider.checkPin(_input)) {
      setState(() => _unlocked = true);
    } else {
      _shakeController.forward(from: 0);
      setState(() => _input = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    if (!provider.usePinLock || _unlocked) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF5F5FA),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon with gradient background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withAlpha(51), AppTheme.accentColor.withAlpha(28)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text('Enter App PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Your inventory is secured', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            const SizedBox(height: 48),
            // PIN dots with shake animation
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final sineValue = _shakeController.isAnimating
                    ? (10 * (0.5 - (_shakeController.value - 0.5).abs()) * 2 * (_shakeController.value < 0.5 ? 1 : -1))
                    : 0.0;
                return Transform.translate(
                  offset: Offset(sineValue, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: index < _input.length ? 22 : 18,
                  height: index < _input.length ? 22 : 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _input.length ? AppTheme.primaryColor : Colors.transparent,
                    border: Border.all(
                      color: index < _input.length ? AppTheme.primaryColor : (isDark ? Colors.white30 : Colors.black26),
                      width: 2,
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 48),
            _buildKeypad(),
            if (_canCheckBiometrics) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _authenticateWithBiometrics,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fingerprint_rounded, color: AppTheme.primaryColor, size: 28),
                      SizedBox(width: 10),
                      Text('Use Fingerprint', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var j = 1; j <= 3; j++) _keypadBtn((i * 3 + j).toString()),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80),
            _keypadBtn('0'),
            _keypadBtn('back', icon: Icons.backspace_rounded),
          ],
        ),
      ],
    );
  }

  Widget _keypadBtn(String val, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (val == 'back') {
          if (_input.isNotEmpty) setState(() => _input = _input.substring(0, _input.length - 1));
        } else {
          _addChar(val);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.all(10),
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(13) : Colors.black.withAlpha(10),
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13)),
        ),
        alignment: Alignment.center,
        child: icon != null 
          ? Icon(icon, color: AppTheme.primaryColor)
          : Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
