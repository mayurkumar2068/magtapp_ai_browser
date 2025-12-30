import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/localization/localization.dart';
import '../../core/provider/setting_provider.dart';
import '../browser/presentation/provider/browser_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = Hive.box('browser_history');
    final currentLang = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          L10n.t('history', currentLang),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 28),
              onPressed: () => _showClearAllDialog(context, box, currentLang),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.black12, height: 0.5),
        ),
      ),

      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box box, _) {
          final sortedEntries = box.toMap().entries.toList();

          try {
            sortedEntries.sort((a, b) {
              final valA = a.value is int ? a.value : 0;
              final valB = b.value is int ? b.value : 0;
              return (valB as int).compareTo(valA as int);
            });
          } catch (e) {
            debugPrint("Sort error: $e");
          }

          if (sortedEntries.isEmpty) {
            return _buildEmptyState(currentLang);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final entry = sortedEntries[index];
                      return _buildHistoryItem(
                          context,
                          ref,
                          entry.key.toString(),
                          entry.value is int ? entry.value : 0
                      );
                    },
                    childCount: sortedEntries.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, WidgetRef ref, String url, int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final formattedTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(url),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => Hive.box('browser_history').delete(url),
        background: _buildDeleteBackground(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.blueAccent.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.public_rounded, color: Colors.blueAccent, size: 20),
            ),
            title: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              formattedTime,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey),
            onTap: () {
              ref.read(browserProvider.notifier).updateUrl(
                  ref.read(browserProvider).activeIndex, url);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Opening..."), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 60, color: Colors.blueAccent.withOpacity(0.2)),
          ),
          const SizedBox(height: 20),
          Text(
            L10n.t('no_activity', lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              L10n.t('history_empty_hint', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, Box box, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(L10n.t('clear_history_title', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(L10n.t('clear_history_confirm', lang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(L10n.t('cancel', lang))),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: ElevatedButton(
              onPressed: () { box.clear(); Navigator.pop(ctx); },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(L10n.t('clear_all', lang)),
            ),
          ),
        ],
      ),
    );
  }
}
