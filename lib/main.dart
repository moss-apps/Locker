import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'themes/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth_method_selection_screen.dart';
import 'screens/unlock_screen.dart';
import 'utils/frame_rate_optimizer.dart';
import 'utils/performance_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure high frame rate support
  PerformanceConfig.configureHighFrameRate();
  PerformanceConfig.optimizeImageCache();
  
  // Start frame rate monitoring
  FrameRateOptimizer().startMonitoring();
  
  // Set preferred orientations and system UI
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const ProviderScope(child: LockerApp()));
}

class LockerApp extends ConsumerWidget {
  const LockerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Locker',
      theme: AppTheme.getLightTheme(accentColor),
      darkTheme: AppTheme.getDarkTheme(accentColor),
      themeMode: themeMode,
      home: const AppInitializer(),
    );
  }
}

/// Initialize app and determine initial route based on authentication state
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isFirstTime = await _authService.isFirstTime();

    setState(() {
      _isFirstTime = isFirstTime;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1D) : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color:
                isDarkMode ? const Color(0xFF5C9CE6) : const Color(0xFF1976D2),
          ),
        ),
      );
    }

    // Route to appropriate screen
    if (_isFirstTime) {
      return const AuthMethodSelectionScreen();
    } else {
      return const UnlockScreen();
    }
  }
}
