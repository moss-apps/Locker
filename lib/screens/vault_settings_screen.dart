import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';
import '../providers/vault_providers.dart';
import '../services/auth_service.dart';
import '../services/auto_kill_service.dart';
import '../services/screenshot_protection_service.dart';
import '../services/vault_service.dart';
import '../themes/app_colors.dart';
import 'accent_color_picker_screen.dart';
import 'change_security_screen.dart';
import 'local_backup_screen.dart';

class VaultSettingsScreen extends ConsumerStatefulWidget {
  const VaultSettingsScreen({super.key});

  @override
  ConsumerState<VaultSettingsScreen> createState() =>
      _VaultSettingsScreenState();
}

class _VaultSettingsScreenState extends ConsumerState<VaultSettingsScreen> {
  static const List<int> _autoKillDelayOptions = [0, 5, 10, 30, 60];
  static const List<int> _lockoutAttemptOptions = [3, 5, 7, 10];
  static const List<int> _lockoutDurationOptions = [30, 60, 300, 900];
  static const List<int> _wipeAttemptOptions = [10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(vaultSettingsProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'ProductSans',
            color: context.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: settingsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.accentColor),
        ),
        error: (_, __) => Center(
          child: Text(
            'Failed to load settings',
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: context.textPrimary,
            ),
          ),
        ),
        data: (settings) {
          final autoKillSupported = AutoKillService.isSupported;
          final screenshotProtectionSupported =
              ScreenshotProtectionService.isSupported;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _buildSectionTitle(context, 'Security'),
              ListTile(
                leading:
                    Icon(Icons.security_outlined, color: context.accentColor),
                title: const Text(
                  'Change Security',
                  style: TextStyle(fontFamily: 'ProductSans'),
                ),
                subtitle: Text(
                  'Change password, PIN, or biometric',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangeSecurityScreen(),
                    ),
                  );
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text(
                  'Encrypt New Files',
                  style: TextStyle(fontFamily: 'ProductSans'),
                ),
                subtitle: Text(
                  'AES-256 encryption for all new imports',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
                value: settings.encryptionEnabled,
                onChanged: (value) async {
                  await _saveVaultSettings(
                    settings.copyWith(encryptionEnabled: value),
                  );
                },
                activeThumbColor: context.accentColor,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text(
                  'Secure Delete',
                  style: TextStyle(fontFamily: 'ProductSans'),
                ),
                subtitle: Text(
                  'Overwrite files before deletion',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
                value: settings.secureDelete,
                onChanged: (value) async {
                  await _saveVaultSettings(
                    settings.copyWith(secureDelete: value),
                  );
                },
                activeThumbColor: context.accentColor,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text(
                  'In-App Screenshot Protection',
                  style: TextStyle(fontFamily: 'ProductSans'),
                ),
                subtitle: Text(
                  screenshotProtectionSupported
                      ? 'Blocks screenshots and app previews while Locker is open'
                      : 'Available on supported Android devices',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
                value: settings.screenshotProtectionEnabled,
                onChanged: screenshotProtectionSupported
                    ? (value) async {
                        await _saveVaultSettings(
                          settings.copyWith(
                            screenshotProtectionEnabled: value,
                          ),
                        );
                      }
                    : null,
                activeThumbColor: context.accentColor,
                contentPadding: EdgeInsets.zero,
              ),
              _buildSecurityOptionDropdown(
                context: context,
                title: 'Auto-Kill Delay',
                subtitle: autoKillSupported
                    ? 'How long Locker waits after going to the background before it closes itself'
                    : 'Available on supported Android devices',
                value: settings.autoKillDelaySeconds,
                options: _autoKillDelayOptions,
                labelBuilder: _autoKillDelayLabel,
                enabled: autoKillSupported,
                onChanged: (value) async {
                  if (value == null) return;
                  await _saveVaultSettings(
                    settings.copyWith(autoKillDelaySeconds: value),
                  );
                },
              ),
              const SizedBox(height: 20),
              Divider(color: context.borderColor),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Appearance'),
              _buildThemeToggle(context, ref),
              _buildAccentColorOption(context, ref),
              const SizedBox(height: 20),
              Divider(color: context.borderColor),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Storage'),
              ListTile(
                leading:
                    Icon(Icons.backup_outlined, color: context.accentColor),
                title: const Text(
                  'Local Backup',
                  style: TextStyle(fontFamily: 'ProductSans'),
                ),
                subtitle: Text(
                  'Save vault as ZIP to a folder',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocalBackupScreen(),
                    ),
                  );
                },
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text(
                  'Compress Media',
                  style: TextStyle(fontFamily: 'ProductSans'),
                ),
                subtitle: Text(
                  'Reduce file size for images and videos',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
                value: settings.compressionEnabled,
                onChanged: (value) async {
                  await _saveVaultSettings(
                    settings.copyWith(compressionEnabled: value),
                  );
                },
                activeThumbColor: context.accentColor,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              Divider(color: context.borderColor),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Unlock Protection'),
              SwitchListTile(
                title: const Text(
                  'Failed Unlock Protection',
                  style: TextStyle(fontFamily: 'ProductSans'),
                ),
                subtitle: Text(
                  'Adds a cooldown after repeated wrong PIN, password, or biometric attempts',
                  style: TextStyle(
                    fontFamily: 'ProductSans',
                    fontSize: 12,
                    color: context.textTertiary,
                  ),
                ),
                value: settings.failedUnlockProtectionEnabled,
                onChanged: (value) async {
                  await _toggleFailedUnlockProtection(settings, value);
                },
                activeThumbColor: context.accentColor,
                contentPadding: EdgeInsets.zero,
              ),
              if (settings.failedUnlockProtectionEnabled) ...[
                _buildSecurityOptionDropdown(
                  context: context,
                  title: 'Attempts Before Cooldown',
                  subtitle:
                      'How many failed unlocks are allowed before access is paused',
                  value: settings.maxFailedAttemptsBeforeLockout,
                  options: _lockoutAttemptOptions,
                  labelBuilder: (value) => value.toString(),
                  onChanged: (value) async {
                    if (value == null) return;
                    await _saveUnlockProtectionSettings(
                      settings.copyWith(maxFailedAttemptsBeforeLockout: value),
                    );
                  },
                ),
                _buildSecurityOptionDropdown(
                  context: context,
                  title: 'Cooldown Timer',
                  subtitle:
                      'How long unlock stays disabled after the cooldown threshold is hit',
                  value: settings.lockoutDurationSeconds,
                  options: _lockoutDurationOptions,
                  labelBuilder: _lockoutDurationLabel,
                  onChanged: (value) async {
                    if (value == null) return;
                    await _saveUnlockProtectionSettings(
                      settings.copyWith(lockoutDurationSeconds: value),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text(
                    'Wipe Vault At Hard Limit',
                    style: TextStyle(fontFamily: 'ProductSans'),
                  ),
                  subtitle: Text(
                    'Permanently erases real and decoy vault files after too many failed unlocks',
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 12,
                      color: context.textTertiary,
                    ),
                  ),
                  value: settings.wipeVaultOnMaxFailedAttempts,
                  onChanged: (value) async {
                    await _toggleVaultWipeProtection(settings, value);
                  },
                  activeThumbColor: AppColors.error,
                  contentPadding: EdgeInsets.zero,
                ),
                if (settings.wipeVaultOnMaxFailedAttempts) ...[
                  _buildSecurityOptionDropdown(
                    context: context,
                    title: 'Attempts Before Wipe',
                    subtitle:
                        'Locker erases all vault files when this failed-attempt total is reached',
                    value: settings.maxFailedAttemptsBeforeWipe,
                    options: _wipeAttemptOptions,
                    labelBuilder: (value) => value.toString(),
                    onChanged: (value) async {
                      if (value == null) return;
                      await _saveUnlockProtectionSettings(
                        settings.copyWith(maxFailedAttemptsBeforeWipe: value),
                      );
                    },
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      'Warning: wiping the vault is permanent and cannot be undone.',
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Future<void> _saveVaultSettings(VaultSettings settings) async {
    await ref.read(vaultServiceProvider).updateSettings(settings);
    await AutoKillService.setDelaySeconds(settings.autoKillDelaySeconds);
    await ScreenshotProtectionService.setEnabled(
      settings.screenshotProtectionEnabled,
    );
    ref.invalidate(vaultSettingsProvider);
  }

  Future<void> _saveUnlockProtectionSettings(VaultSettings settings) async {
    await _saveVaultSettings(settings);
    await AuthService().resetUnlockAttempts();
  }

  Future<void> _toggleFailedUnlockProtection(
    VaultSettings settings,
    bool enabled,
  ) async {
    await _saveUnlockProtectionSettings(
      settings.copyWith(failedUnlockProtectionEnabled: enabled),
    );
  }

  Future<void> _toggleVaultWipeProtection(
    VaultSettings settings,
    bool enabled,
  ) async {
    if (enabled) {
      final confirmed = await _confirmDangerousWipeProtection();
      if (confirmed != true) return;
    }

    await _saveUnlockProtectionSettings(
      settings.copyWith(wipeVaultOnMaxFailedAttempts: enabled),
    );
  }

  Future<bool?> _confirmDangerousWipeProtection() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).scaffoldBackgroundColor,
        title: const Text(
          'Enable Vault Wipe?',
          style: TextStyle(fontFamily: 'ProductSans'),
        ),
        content: const Text(
          'When the failed-attempt limit is reached, Locker will permanently erase the real and decoy vault files on this device. This cannot be undone.',
          style: TextStyle(fontFamily: 'ProductSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOptionDropdown({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int value,
    required List<int> options,
    required String Function(int value) labelBuilder,
    bool enabled = true,
    required ValueChanged<int?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'ProductSans'),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 12,
          color: context.textTertiary,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          borderRadius: BorderRadius.circular(12),
          items: options
              .map(
                (option) => DropdownMenuItem<int>(
                  value: option,
                  child: Text(
                    labelBuilder(option),
                    style: const TextStyle(fontFamily: 'ProductSans'),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  String _lockoutDurationLabel(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }

    final minutes = seconds ~/ 60;
    return minutes == 1 ? '1 min' : '$minutes min';
  }

  String _autoKillDelayLabel(int seconds) {
    if (seconds == 0) return 'Instant';
    return _lockoutDurationLabel(seconds);
  }

  Widget _buildThemeToggle(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return SwitchListTile(
      title: const Text(
        'Dark Mode',
        style: TextStyle(fontFamily: 'ProductSans'),
      ),
      subtitle: Text(
        isDarkMode ? 'Eye-friendly dark theme' : 'Clean light theme',
        style: TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 12,
          color: context.textTertiary,
        ),
      ),
      secondary: Icon(
        isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: context.accentColor,
      ),
      value: isDarkMode,
      onChanged: (_) {
        ref.read(themeModeProvider.notifier).toggleTheme();
      },
      activeThumbColor: context.accentColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAccentColorOption(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);

    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.getColor(
                context.isDarkMode ? Brightness.dark : Brightness.light,
              ),
              accentColor.getVariantColor(
                context.isDarkMode ? Brightness.dark : Brightness.light,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
      ),
      title: const Text(
        'Accent Color',
        style: TextStyle(fontFamily: 'ProductSans'),
      ),
      subtitle: Text(
        accentColor.name,
        style: TextStyle(
          fontFamily: 'ProductSans',
          fontSize: 12,
          color: context.textTertiary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AccentColorPickerScreen(),
          ),
        );
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
