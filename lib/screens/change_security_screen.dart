import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';
import 'gallery_vault_screen.dart';

/// Security option type for the change security screen
enum SecurityOption {
  changePassword,
  changePIN,
  switchToPassword,
  switchToPIN,
  enableBiometric,
}

/// Screen for changing security credentials
class ChangeSecurityScreen extends StatefulWidget {
  const ChangeSecurityScreen({super.key});

  @override
  State<ChangeSecurityScreen> createState() => _ChangeSecurityScreenState();
}

class _ChangeSecurityScreenState extends State<ChangeSecurityScreen> {
  final AuthService _authService = AuthService();
  String? _currentAuthMethod;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthMethod();
  }

  Future<void> _loadAuthMethod() async {
    final method = await _authService.getAuthMethod();
    if (mounted) {
      setState(() {
        _currentAuthMethod = method;
        _isLoading = false;
      });
    }
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          currentAuthMethod: _currentAuthMethod!,
        ),
      ),
    );
  }

  void _navigateToChangePIN() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePINScreen(
          currentAuthMethod: _currentAuthMethod!,
        ),
      ),
    );
  }

  void _navigateToSetupBiometric() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BiometricSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Security',
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: context.textPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Current method: ${_currentAuthMethod!.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textTertiary,
                        fontFamily: 'ProductSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (_currentAuthMethod == 'password') ...[
                      _buildOptionCard(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your current password',
                        onTap: _navigateToChangePassword,
                      ),
                      const SizedBox(height: 16),
                      _buildOptionCard(
                        icon: Icons.pin_outlined,
                        title: 'Switch to PIN',
                        subtitle: 'Change from password to 6-digit PIN',
                        onTap: _navigateToChangePIN,
                      ),
                    ] else if (_currentAuthMethod == 'pin') ...[
                      _buildOptionCard(
                        icon: Icons.pin_outlined,
                        title: 'Change PIN',
                        subtitle: 'Update your current PIN',
                        onTap: _navigateToChangePIN,
                      ),
                      const SizedBox(height: 16),
                      _buildOptionCard(
                        icon: Icons.lock_outline,
                        title: 'Switch to Password',
                        subtitle: 'Change from PIN to alphanumeric password',
                        onTap: _navigateToChangePassword,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FutureBuilder<bool>(
                      future: _authService.isBiometricAvailable(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return _buildOptionCard(
                            icon: Icons.fingerprint,
                            title: 'Enable Biometric',
                            subtitle: 'Use fingerprint or face to unlock',
                            onTap: _navigateToSetupBiometric,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBackgroundSecondary
              : AppColors.lightBackgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'ProductSans',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'ProductSans',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextTertiary
                          : context.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextTertiary
                  : context.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for changing password
class ChangePasswordScreen extends StatefulWidget {
  final String currentAuthMethod;

  const ChangePasswordScreen({super.key, required this.currentAuthMethod});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _currentCredentialController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  int _step = 0;
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCredentialController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_step == 0) {
      if (_currentCredentialController.text.isEmpty) {
        setState(() {
          _errorMessage = widget.currentAuthMethod == 'password'
              ? 'Please enter your current password'
              : 'Please enter your current PIN';
        });
        return;
      }
      setState(() {
        _step = 1;
        _errorMessage = null;
      });
    } else if (_step == 1) {
      if (_newPasswordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a new password';
        });
        return;
      }
      setState(() {
        _step = 2;
        _errorMessage = null;
      });
    } else {
      if (_confirmPasswordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please confirm your new password';
        });
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      bool success;
      if (widget.currentAuthMethod == 'password') {
        success = await _authService.changePassword(
          _currentCredentialController.text,
          _newPasswordController.text,
        );
      } else {
        success = await _authService.switchFromPINToPassword(
          _currentCredentialController.text,
          _newPasswordController.text,
        );
      }

      if (success && mounted) {
        ToastUtils.showSuccess('Password changed successfully');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const GalleryVaultScreen(),
          ),
          (route) => false,
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = widget.currentAuthMethod == 'password'
              ? 'Current password is incorrect'
              : 'Current PIN is incorrect';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Verify Current', 'New Password', 'Confirm Password'];
    final subtitles = [
      widget.currentAuthMethod == 'password'
          ? 'Enter your current password'
          : 'Enter your current PIN',
      'Create a new secure password',
      'Enter your new password again to confirm',
    ];
    final controllers = [
      _currentCredentialController,
      _newPasswordController,
      _confirmPasswordController,
    ];
    final obscureValues = [_obscureCurrent, _obscureNew, _obscureConfirm];
    final obscureIcons = [
      _obscureCurrent
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
      _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      _obscureConfirm
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
    ];
    final toggleCallbacks = [
      () => setState(() => _obscureCurrent = !_obscureCurrent),
      () => setState(() => _obscureNew = !_obscureNew),
      () => setState(() => _obscureConfirm = !_obscureConfirm),
    ];
    final labels = [
      widget.currentAuthMethod == 'password'
          ? 'Current Password'
          : 'Current PIN',
      'New Password',
      'Confirm Password',
    ];
    final hints = [
      widget.currentAuthMethod == 'password'
          ? 'Enter current password'
          : 'Enter current PIN',
      'Enter new password',
      'Re-enter new password',
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: _isLoading
              ? null
              : () {
                  if (_step > 0) {
                    setState(() {
                      _step--;
                      _errorMessage = null;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
        ),
        title: Text(
          titles[_step],
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: context.textPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      subtitles[_step],
                      style: TextStyle(
                        fontSize: 18,
                        color: context.textSecondary,
                        fontFamily: 'ProductSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    TextField(
                      controller: controllers[_step],
                      obscureText: obscureValues[_step],
                      decoration: InputDecoration(
                        labelText: labels[_step],
                        hintText: hints[_step],
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureIcons[_step],
                            color: context.textTertiary,
                          ),
                          onPressed: toggleCallbacks[_step],
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                      ),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _handleContinue,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _step == 2 ? 'Change Password' : 'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Screen for changing PIN
class ChangePINScreen extends StatefulWidget {
  final String currentAuthMethod;

  const ChangePINScreen({super.key, required this.currentAuthMethod});

  @override
  State<ChangePINScreen> createState() => _ChangePINScreenState();
}

class _ChangePINScreenState extends State<ChangePINScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _currentCredentialController =
      TextEditingController();
  final TextEditingController _newPINController = TextEditingController();
  final TextEditingController _confirmPINController = TextEditingController();
  int _step = 0;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentCredentialController.dispose();
    _newPINController.dispose();
    _confirmPINController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_step == 0) {
      if (_currentCredentialController.text.isEmpty) {
        setState(() {
          _errorMessage = widget.currentAuthMethod == 'pin'
              ? 'Please enter your current PIN'
              : 'Please enter your current password';
        });
        return;
      }
      setState(() {
        _step = 1;
        _errorMessage = null;
      });
    } else if (_step == 1) {
      if (_newPINController.text.isEmpty ||
          _newPINController.text.length != 6) {
        setState(() {
          _errorMessage = 'PIN must be 6 digits';
        });
        return;
      }
      if (!RegExp(r'^[0-9]{6}$').hasMatch(_newPINController.text)) {
        setState(() {
          _errorMessage = 'PIN must contain only digits';
        });
        return;
      }
      setState(() {
        _step = 2;
        _errorMessage = null;
      });
    } else {
      if (_confirmPINController.text.isEmpty ||
          _confirmPINController.text.length != 6) {
        setState(() {
          _errorMessage = 'PIN must be 6 digits';
        });
        return;
      }
      if (_newPINController.text != _confirmPINController.text) {
        setState(() {
          _errorMessage = 'PINs do not match';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      bool success;
      if (widget.currentAuthMethod == 'pin') {
        success = await _authService.changePIN(
          _currentCredentialController.text,
          _newPINController.text,
        );
      } else {
        success = await _authService.switchFromPasswordToPIN(
          _currentCredentialController.text,
          _newPINController.text,
        );
      }

      if (success && mounted) {
        ToastUtils.showSuccess('PIN changed successfully');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const GalleryVaultScreen(),
          ),
          (route) => false,
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = widget.currentAuthMethod == 'pin'
              ? 'Current PIN is incorrect'
              : 'Current password is incorrect';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Verify Current', 'New PIN', 'Confirm PIN'];
    final subtitles = [
      widget.currentAuthMethod == 'pin'
          ? 'Enter your current PIN'
          : 'Enter your current password',
      'Enter a new 6-digit PIN',
      'Enter your new PIN again to confirm',
    ];
    final controllers = [
      _currentCredentialController,
      _newPINController,
      _confirmPINController,
    ];
    final labels = [
      widget.currentAuthMethod == 'pin' ? 'Current PIN' : 'Current Password',
      'New PIN',
      'Confirm PIN',
    ];
    final hints = [
      widget.currentAuthMethod == 'pin'
          ? 'Enter current PIN'
          : 'Enter current password',
      'Enter 6-digit PIN',
      'Re-enter PIN',
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: _isLoading
              ? null
              : () {
                  if (_step > 0) {
                    setState(() {
                      _step--;
                      _errorMessage = null;
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
        ),
        title: Text(
          titles[_step],
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: context.textPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      subtitles[_step],
                      style: TextStyle(
                        fontSize: 18,
                        color: context.textSecondary,
                        fontFamily: 'ProductSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    TextField(
                      controller: controllers[_step],
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: _step >= 1 ? 6 : null,
                      decoration: InputDecoration(
                        labelText: labels[_step],
                        hintText: hints[_step],
                        counterText: '',
                      ),
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                      ),
                      onChanged: (_) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _handleContinue,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _step == 2 ? 'Change PIN' : 'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'ProductSans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Screen for setting up biometric authentication
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isAvailable = available;
      });
    }
  }

  Future<void> _setupBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authService.setupBiometricAuthentication();

    if (mounted) {
      if (success) {
        ToastUtils.showSuccess('Biometric enabled successfully');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const GalleryVaultScreen(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Biometric setup failed or was cancelled';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enable Biometric',
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: context.textPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Icon(
                      Icons.fingerprint,
                      size: 80,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Use your fingerprint or face to unlock the app quickly',
                      style: TextStyle(
                        fontSize: 18,
                        color: context.textSecondary,
                        fontFamily: 'ProductSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                            fontFamily: 'ProductSans',
                          ),
                        ),
                      ),
                    if (_isAvailable)
                      ElevatedButton(
                        onPressed: _setupBiometric,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Enable Biometric',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'ProductSans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        'Biometric authentication is not available on this device',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontFamily: 'ProductSans',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
