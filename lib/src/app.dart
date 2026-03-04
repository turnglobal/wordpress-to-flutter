import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'repositories/post_repository.dart';
import 'screens/brand_splash_screen.dart';
import 'screens/main_shell_screen.dart';
import 'services/ad_service.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'services/wp_api_client.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'viewmodels/home_view_model.dart';

class Wp2fApp extends StatelessWidget {
  const Wp2fApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => WpApiClient()),
        Provider(
          create: (context) => PostRepository(context.read<WpApiClient>()),
        ),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(context.read<PostRepository>()),
        ),
        Provider(create: (_) => NotificationService()),
        Provider(create: (_) => AdService()),
        Provider(create: (_) => DeepLinkService()),
      ],
      child: const _Bootstrap(),
    );
  }
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _initializeIntegrations();
  }

  Future<void> _initializeIntegrations() async {
    final notificationService = context.read<NotificationService>();
    final adService = context.read<AdService>();
    final deepLinkService = context.read<DeepLinkService>();

    await Future.wait([
      _safeInitialize(notificationService.initialize),
      _safeInitialize(adService.initialize),
      _safeInitialize(deepLinkService.initialize),
    ]);
  }

  Future<void> _safeInitialize(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 3));
    } catch (_) {
      // Non-critical integrations should never block app startup.
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName.isNotEmpty ? AppConfig.appName : 'WP2F App',
      themeMode: themeController.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: FutureBuilder<void>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const MainShellScreen();
          }
          return const BrandSplashScreen();
        },
      ),
    );
  }
}
