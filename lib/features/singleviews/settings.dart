import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/localization/localization.dart';
import '../../core/provider/setting_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/localization/localization.dart';
import '../../core/provider/setting_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          /// Header / AppBar
          SliverAppBar.large(
            pinned: true,
            title: Text(
              L10n.t('settings', currentLang),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  /// Appearance / Theme Card
                  _buildCard(
                    context: context,
                    title: L10n.t('theme', currentLang),
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.deepPurpleAccent,
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (val) => ref.read(themeProvider.notifier).state =
                      val ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildCard(
                    context: context,
                    title: L10n.t('language', currentLang),
                    subtitle: currentLang,
                    icon: Icons.translate_rounded,
                    color: Colors.blueAccent,
                    onTap: () => _showLanguagePicker(context, ref),
                    trailing: const Icon(Icons.expand_more_rounded, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  _buildCard(
                    context: context,
                    title: L10n.t('clear_ai_cache', currentLang),
                    icon: Icons.auto_delete_rounded,
                    color: Colors.orangeAccent,
                    onTap: () => _showDeleteDialog(context, currentLang),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  const SizedBox(height: 32),

                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "App Version: 1.0.0",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(L10n.t('select_language', ref.watch(appLanguageProvider)),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...['English', 'Hindi', 'Spanish'].map((lang) => ListTile(
                leading: const Icon(Icons.language_rounded, color: Colors.blueAccent),
                title: Text(lang, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: ref.watch(appLanguageProvider) == lang
                    ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                    : null,
                onTap: () {
                  ref.read(appLanguageProvider.notifier).state = lang;
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(L10n.t('clear_all_data', lang),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(L10n.t('clear_data_hint', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.t('cancel', lang), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await Hive.box('summaries').clear();
              await Hive.box('browser_history').clear();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(L10n.t('data_cleared', lang))),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(L10n.t('clear_all', lang)),
          ),
        ],
      ),
    );
  }
}
