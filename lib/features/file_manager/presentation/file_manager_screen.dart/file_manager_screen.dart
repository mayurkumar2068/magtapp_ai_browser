import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/provider/setting_provider.dart';
import '../../../summary/presentation/providers/summary_provider.dart';
import '../../../summary/presentation/screen/summary_pannel_widget.dart';
import '../../data/source/pdf_service.dart';

class FileManagerScreen extends ConsumerWidget {
  const FileManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(fileProvider);
    final currentLang = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
            L10n.t('files', currentLang),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.add_box_rounded, color: Colors.blueAccent, size: 30),
              onPressed: () => ref.read(fileProvider.notifier).pickAndSaveFile(),
            ),
          ),
        ],
      ),
      body: files.isEmpty
          ? _buildEmptyState(currentLang)
          : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildFileCard(context, ref, files[index], currentLang),
                childCount: files.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// --- Premium File Card ---
  Widget _buildFileCard(BuildContext context, WidgetRef ref, dynamic file, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildFileIcon(file.type),
            title: Text(
              file.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("${file.size} • ${file.date.toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildSourceBadge(file.isDownloaded, lang),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, ref, file, lang),
            ),
          ),

          /// --- Bottom Action Bar ---
          Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => ref.read(fileProvider.notifier).viewFile(file.path),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: Text(L10n.t('view', lang)),
                    style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.blueAccent.withOpacity(0.1)),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _handleFileSummarize(context, ref, file),
                    icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.blueAccent),
                    label: Text(L10n.t('summarize', lang),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// --- Logic for AI Extraction ---
  Future<void> _handleFileSummarize(BuildContext context, WidgetRef ref, dynamic file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String text = "";
      if (file.type.toLowerCase() == 'pdf') {
        text = await PdfService().extractTextFromPdf(file.path);
      } else {
        text = "Document parsing for ${file.type} is under development.";
      }

      await ref.read(summaryProvider.notifier).summarizeRawText(text);

      if (context.mounted) {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const SummaryPanel(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint("Summarize Error: $e");
    }
  }

  /// --- Icons & Badges Helpers ---
  Widget _buildFileIcon(String type) {
    IconData icon;
    Color color;
    switch (type.toLowerCase()) {
      case 'pdf': icon = Icons.picture_as_pdf_rounded; color = Colors.redAccent; break;
      case 'docx': icon = Icons.description_rounded; color = Colors.blue; break;
      case 'xlsx': icon = Icons.table_chart_rounded; color = Colors.green; break;
      default: icon = Icons.insert_drive_file_rounded; color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildSourceBadge(bool isDownloaded, String lang) {
    final color = isDownloaded ? Colors.teal : Colors.orange;
    final label = isDownloaded ? L10n.t('downloaded', lang) : L10n.t('local', lang);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  /// Empty State UI ---
  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_copy_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(L10n.t('no_files', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(L10n.t('files_empty_hint', lang),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic file, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(L10n.t('delete_file', lang)),
        content: Text("${L10n.t('confirm_delete', lang)} ${file.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(L10n.t('cancel', lang))),
          ElevatedButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(file);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text(L10n.t('delete', lang)),
          ),
        ],
      ),
    );
  }
}