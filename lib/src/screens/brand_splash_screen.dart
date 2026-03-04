import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../widgets/premium_background.dart';
import '../widgets/responsive_frame.dart';

class BrandSplashScreen extends StatelessWidget {
  const BrandSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appName = AppConfig.appName.isNotEmpty
        ? AppConfig.appName
        : 'WordPress Feed';
    final logoPath = AppConfig.appLogoPath.isNotEmpty
        ? AppConfig.appLogoPath
        : AppConfig.appIconPath;

    return Scaffold(
      body: PremiumBackground(
        child: Center(
          child: ResponsiveFrame(
            maxWidth: 420,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BrandLogo(path: logoPath),
                const SizedBox(height: 18),
                Text(
                  appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading latest content...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final framedFallback = Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.newspaper_rounded,
        size: 48,
        color: theme.colorScheme.primary,
      ),
    );

    if (path.isEmpty) {
      return framedFallback;
    }

    final fallbackIcon = Icon(
      Icons.newspaper_rounded,
      size: 48,
      color: theme.colorScheme.primary,
    );

    final image = path.startsWith('http://') || path.startsWith('https://')
        ? Image.network(
            path,
            width: 104,
            height: 104,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => fallbackIcon,
          )
        : Image.asset(
            path,
            width: 104,
            height: 104,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => fallbackIcon,
          );

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: Alignment.center,
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: image),
    );
  }
}
