import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/provider/setting_provider.dart';
import '../providers/summary_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../file_manager/data/source/pdf_service.dart';

final summaryDownloadProvider = StateProvider<bool>((ref) => false);

class SummaryPanel extends ConsumerWidget {
  const SummaryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(summaryProvider);
    final currentLang = ref.watch(appLanguageProvider);

    final isDownloading = ref.watch(summaryDownloadProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: summaryState.when(
              data: (result) {
                if (result == null) return const Center(child: Text("No Data Available"));

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header Download Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "AI Report",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          IconButton(
                            icon: isDownloading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.download_rounded, color: Colors.blueAccent),
                            onPressed: isDownloading
                                ? null
                                : () async {
                              await _downloadSummary(result.displaySummary, ref, context);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 30),

                      /// Summary content
                      Text(
                        "Summary",
                        style: const TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.displaySummary,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                  child: Text(err.toString(), style: const TextStyle(color: Colors.redAccent))),
            ),
          ),
        ],
      ),
    );
  }

  /// Download Summary PDF
  Future<void> _downloadSummary(String? text, WidgetRef ref, BuildContext context) async {
    if (text == null || text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No summary available to download")));
      return;
    }

    ref.read(summaryDownloadProvider.notifier).state = true;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = "AI_Summary_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final filePath = p.join(dir.path, fileName);

      final pdf = PdfDocument();
      final page = pdf.pages.add();

      page.graphics.drawRectangle(
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
        brush: PdfBrushes.white,
      );
      final pen = PdfPen(PdfColor(200, 200, 200), width: 0.5);
      const dashSize = 5.0;
      final width = page.getClientSize().width;
      final height = page.getClientSize().height;
      for (double x = 0; x < width; x += dashSize * 2) {
        page.graphics.drawLine(
          PdfPen(PdfColor(0, 0, 0), width: 0.5),
          Offset(x, 0),
          Offset(x + dashSize, 0),
        );
      }
      for (double x = 0; x < width; x += dashSize * 2) {
        page.graphics.drawLine(
          pen,
          Offset(x, height),
          Offset(x + dashSize, height),
        );
      }
      for (double y = 0; y < height; y += dashSize * 2) {
        page.graphics.drawLine(
          pen,
          Offset(0, y),
          Offset(0, y + dashSize),
        );
      }
      for (double y = 0; y < height; y += dashSize * 2) {
        page.graphics.drawLine(
          pen,
          Offset(width, y),
          Offset(width, y + dashSize),
        );
      }

      final textElement = PdfTextElement(
        text: text,
        font: PdfStandardFont(PdfFontFamily.helvetica, 12),
      );
      textElement.draw(
        page: page,
        bounds: Rect.fromLTWH(20, 50, width - 40, height - 60),
      );

      final bytes = await pdf.save();
      pdf.dispose();

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await ref.read(fileProvider.notifier).saveAiReport(file, fileName);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Summary downloaded successfully")));
    } catch (e) {
      debugPrint("Error downloading summary: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error downloading summary: $e")));
    } finally {
      ref.read(summaryDownloadProvider.notifier).state = false;
    }
  }
}


