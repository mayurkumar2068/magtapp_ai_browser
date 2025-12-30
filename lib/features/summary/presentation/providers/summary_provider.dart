import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../data/source/ai_service.dart';
import '../../domain/entities/summary_result.dart';

final aiServiceProvider = Provider((ref) => AIService());

class SummaryNotifier extends StateNotifier<AsyncValue<SummaryResult?>> {
  final AIService _aiService;

  SummaryNotifier(this._aiService) : super(const AsyncValue.data(null));

  /// Summarize the content of a WebView page
  Future<void> summarizeWebPage(InAppWebViewController controller) async {
    state = const AsyncValue.loading();
    try {
      String script = "document.body.innerText";
      final rawText = await controller.evaluateJavascript(source: script);
      final original = rawText.toString();
      final summary = await _aiService.summarize(original);

      final result = SummaryResult(
        originalText: original,
        summarizedText: summary,
        displaySummary: summary,
        language: 'English',
        currentLanguage: 'en',
        translations: {'en': summary},
      );

      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Language switch logic using your copyWith
  Future<void> changeLanguage(String targetLangCode, String langName) async {
    final currentData = state.value;
    if (currentData == null) return;

    /// Check if translation already exists in cache
    if (currentData.translations.containsKey(targetLangCode)) {
      state = AsyncValue.data(currentData.copyWith(
        displaySummary: currentData.translations[targetLangCode],
        currentLanguage: targetLangCode,
        language: langName,
      ));
      return;
    }

    /// Otherwise, call API and update cache
    state = const AsyncValue.loading();
    final translated = await _aiService.translate(currentData.summarizedText, targetLangCode);

    final newTranslations = Map<String, String>.from(currentData.translations);
    newTranslations[targetLangCode] = translated;

    state = AsyncValue.data(currentData.copyWith(
      displaySummary: translated,
      translations: newTranslations,
      currentLanguage: targetLangCode,
      language: langName,
    ));
  }

  /// Summarize raw text
  Future<void> summarizeRawText(String text) async {
    if (text.trim().isEmpty) return;
    state = const AsyncValue.loading();

    try {
      final summary = await _aiService.summarize(text);
      state = AsyncValue.data(SummaryResult(
        originalText: text,
        summarizedText: summary,
        translations: {},
        currentLanguage: 'en',
        displaySummary: summary,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
    }
  }

  /// Translate the summary to target language
  Future<void> translate(String targetLang) async {
    final current = state.value;
    if (current == null) return;

    /// Already translated?
    if (current.translations.containsKey(targetLang)) {
      state = AsyncValue.data(current.copyWith(
        currentLanguage: targetLang,
        displaySummary: current.translations[targetLang],
      ));
      return;
    }

    state = const AsyncValue.loading();
    try {
      final translated = await _aiService.translate(current.summarizedText, targetLang);

      final updatedTranslations = Map<String, String>.from(current.translations);
      updatedTranslations[targetLang] = translated;

      state = AsyncValue.data(current.copyWith(
        translations: updatedTranslations,
        currentLanguage: targetLang,
        displaySummary: translated,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
    }
  }

  /// Switch displayed language to already translated summary
  void switchLanguage(String langCode) {
    state.whenData((data) {
      if (data != null && data.translations.containsKey(langCode)) {
        state = AsyncValue.data(data.copyWith(
          currentLanguage: langCode,
          displaySummary: data.translations[langCode],
        ));
      }
    });
  }
}

final summaryProvider =
StateNotifierProvider<SummaryNotifier, AsyncValue<SummaryResult?>>((ref) {
  return SummaryNotifier(ref.read(aiServiceProvider));
});
