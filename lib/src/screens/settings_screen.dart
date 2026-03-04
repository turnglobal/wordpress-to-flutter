import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../repositories/post_repository.dart';
import '../theme/theme_controller.dart';
import '../widgets/premium_background.dart';
import '../widgets/responsive_frame.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _pushNotificationsKey = 'push_notifications_enabled';
  static const _breakingNewsKey = 'breaking_news_enabled';

  bool _pushNotifications = true;
  bool _breakingNews = true;
  bool _offlineModeEnabled = false;
  bool _clearingOfflineData = false;
  String _buildNumber = '-';
  String _version = '-';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBuildInfo();
    _loadOfflineMode();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _pushNotifications = prefs.getBool(_pushNotificationsKey) ?? true;
      _breakingNews = prefs.getBool(_breakingNewsKey) ?? true;
    });
  }

  Future<void> _loadBuildInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }

    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _loadOfflineMode() async {
    final repo = context.read<PostRepository>();
    final enabled = await repo.isOfflineModeEnabled();
    if (!mounted) {
      return;
    }
    setState(() => _offlineModeEnabled = enabled);
  }

  Future<void> _toggleOfflineMode(bool value) async {
    setState(() => _offlineModeEnabled = value);
    final repo = context.read<PostRepository>();
    await repo.setOfflineModeEnabled(value);
  }

  Future<void> _clearOfflineNews() async {
    if (_clearingOfflineData) {
      return;
    }
    setState(() => _clearingOfflineData = true);
    try {
      final repo = context.read<PostRepository>();
      await repo.clearOfflineCache();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline news cache cleared')),
      );
    } finally {
      if (mounted) {
        setState(() => _clearingOfflineData = false);
      }
    }
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _openPrivacyPolicy() async {
    final base = AppConfig.wpDomain;
    if (base.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Privacy policy URL is not configured.')),
      );
      return;
    }

    final uri = Uri.parse('$base/privacy-policy');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildBody(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      children: [
        ResponsiveFrame(
          maxWidth: 760,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const SectionHeader(
                  title: 'Appearance',
                  subtitle: 'Personalize app theme',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest_outlined),
                          label: Text('Auto'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {themeController.themeMode},
                      onSelectionChanged: (selection) {
                        if (selection.isNotEmpty) {
                          themeController.setThemeMode(selection.first);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SectionHeader(
                  title: 'Notifications',
                  subtitle: 'Control alerts and breaking news',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Push Notifications'),
                          subtitle: const Text(
                            'Enable or disable all notifications',
                          ),
                          value: _pushNotifications,
                          onChanged: (value) {
                            setState(() => _pushNotifications = value);
                            _saveToggle(_pushNotificationsKey, value);
                          },
                        ),
                        const Divider(height: 0),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Breaking News Alerts'),
                          subtitle: const Text(
                            'Receive important post updates',
                          ),
                          value: _breakingNews,
                          onChanged: _pushNotifications
                              ? (value) {
                                  setState(() => _breakingNews = value);
                                  _saveToggle(_breakingNewsKey, value);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SectionHeader(
                  title: 'Offline Mode',
                  subtitle: 'Save news on your device for offline reading',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable Offline News'),
                          subtitle: const Text(
                            'Keep cached news available without internet',
                          ),
                          value: _offlineModeEnabled,
                          onChanged: _toggleOfflineMode,
                        ),
                        const Divider(height: 0),
                        ListTile(
                          title: const Text('Clear Offline News'),
                          subtitle: const Text(
                            'Delete all saved news from this device',
                          ),
                          trailing: _clearingOfflineData
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Icon(Icons.delete_outline),
                          onTap: _clearingOfflineData
                              ? null
                              : _clearOfflineNews,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SectionHeader(
                  title: 'Legal',
                  subtitle: 'Privacy and policy information',
                ),
                Card(
                  child: ListTile(
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Open website privacy policy page'),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: _openPrivacyPolicy,
                  ),
                ),
                const SizedBox(height: 14),
                const SectionHeader(
                  title: 'Build Info',
                  subtitle: 'Production metadata',
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Version'),
                          trailing: Text(_version),
                        ),
                        const Divider(height: 0),
                        ListTile(
                          title: const Text('Build Number'),
                          trailing: Text(_buildNumber),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: bottomInset + 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = PremiumBackground(child: _buildBody(context));
    if (!widget.showScaffold) {
      return content;
    }
    return Scaffold(body: content);
  }
}
