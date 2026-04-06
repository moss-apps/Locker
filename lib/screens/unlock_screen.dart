import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../themes/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/pin_input_widget.dart';
import 'gallery_vault_screen.dart';

// Unlock screen for returning users.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final AuthService _authService = AuthService();
  String? _authMethod;
  String? _errorMessage;
  bool _isLoading = true;
  bool _obscurePassword = true;
  final TextEditingController _passwordController = TextEditingController();
  final PinInputController _pinController = PinInputController();

  @override
  void initState() {
    super.initState();
    _loadAuthMethod();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthMethod() async {
    final method = await _authService.getAuthMethod();
    setState(() {
      _authMethod = method;
      _isLoading = false;
    });

    // Auto-trigger biometric if that's the method
    if (method == 'biometric') {
      _handleBiometricAuth();
    }
  }

  Future<void> _handlePinComplete(String pin) async {
    final isValid = await _authService.verifyPIN(pin);

    if (isValid && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const GalleryVaultScreen(),
        ),
      );
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
      _pinController.clear();
    }
  }

  void _handlePinChanged() {
    // Only trigger rebuild if there's an error to clear
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _handlePasswordAuth() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    // Batch state update for loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isValid = await _authService.verifyPassword(password);

    if (isValid && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const GalleryVaultScreen(),
        ),
      );
    } else if (mounted) {
      // Batch state update for error state
      setState(() {
        _isLoading = false;
        _errorMessage = 'Incorrect password. Please try again.';
      });
      _passwordController.clear();
    }
  }

  Future<void> _handleBiometricAuth() async {
    final isAuthenticated = await _authService.authenticateWithBiometrics();

    if (isAuthenticated && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const GalleryVaultScreen(),
        ),
      );
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Biometric authentication failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _authMethod == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: Stack(
          children: [
            _buildBackground(),
            Center(
              child: CircularProgressIndicator(
                color: context.accentColor,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildAppName(),
                  const SizedBox(height: 12),
                  _buildInstruction(),
                  const SizedBox(height: 64),
                  _buildAuthWidget(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.isDarkMode
              ? [
                  const Color(0xFF0F0F12),
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                ]
              : [
                  const Color(0xFFE8EEF5),
                  const Color(0xFFF5F7FA),
                  const Color(0xFFE4E9F2),
                ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.accentColor.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SvgPicture.asset(
                'assets/locker_logo_nobg.svg',
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  context.isDarkMode ? const Color(0xFFF5F5F5) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return Text(
      'Locker',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: context.textPrimary,
        fontFamily: 'ProductSans',
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInstruction() {
    return Text(
      _authMethod == 'pin'
          ? 'Enter your PIN to unlock'
          : _authMethod == 'password'
              ? 'Enter your password to unlock'
              : 'Use biometrics to unlock',
      style: TextStyle(
        fontSize: 16,
        color: context.textSecondary,
        fontFamily: 'ProductSans',
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAuthWidget() {
    if (_authMethod == 'pin') {
      return _buildPinAuth();
    } else if (_authMethod == 'password') {
      return _buildPasswordAuth();
    } else if (_authMethod == 'biometric') {
      return _buildBiometricAuth();
    }
    return const SizedBox.shrink();
  }

  Widget _buildPinAuth() {
    return Column(
      children: [
        PinInputWidget(
          onPinComplete: _handlePinComplete,
          onPinChanged: _handlePinChanged,
          errorMessage: _errorMessage,
          controller: _pinController,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _buildError(),
        ],
      ],
    );
  }

  Widget _buildPasswordAuth() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(
                  fontFamily: 'ProductSans',
                  fontSize: 16,
                  color: context.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  labelStyle: TextStyle(
                    fontFamily: 'ProductSans',
                    color: context.textSecondary,
                  ),
                  hintStyle: TextStyle(
                    fontFamily: 'ProductSans',
                    color: context.textTertiary,
                  ),
                  filled: true,
                  fillColor: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.textTertiary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: context.accentColor, width: 2),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                onSubmitted: (_) => _handlePasswordAuth(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildError(),
              ],
              const SizedBox(height: 24),
              _buildUnlockButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricAuth() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Icon(
                Icons.fingerprint,
                size: 64,
                color:
                    context.isDarkMode ? const Color(0xFFF5F5F5) : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null) ...[
          _buildError(),
          const SizedBox(height: 24),
        ],
        _buildUnlockButton(isBiometric: true),
      ],
    );
  }

  Widget _buildError() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            _errorMessage!,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 14,
              fontFamily: 'ProductSans',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockButton({bool isBiometric = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            context.accentColor,
            context.accentColor.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: context.accentColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isBiometric ? _handleBiometricAuth : _handlePasswordAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          isBiometric ? 'Unlock with Biometric' : 'Unlock',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'ProductSans',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
