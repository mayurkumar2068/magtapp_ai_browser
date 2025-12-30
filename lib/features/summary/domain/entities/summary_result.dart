class SummaryResult {
  final String originalText;
  final String summarizedText;
  final String translatedText;
  final String language;
  final String displaySummary;
  final String currentLanguage;
  final Map<String, String> translations;

  SummaryResult({
    required this.originalText,
    required this.summarizedText,
    this.translatedText = '',
    this.language = 'English',
    this.displaySummary = '',
    this.currentLanguage = 'en',
    this.translations = const {},
  });

  SummaryResult copyWith({
    String? displaySummary,
    String? currentLanguage,
    String? translatedText,
    String? language,
    Map<String, String>? translations,
  }) {
    return SummaryResult(
      originalText: originalText,
      summarizedText: summarizedText,
      translations: translations ?? this.translations,
      translatedText: translatedText ?? this.translatedText,
      language: language ?? this.language,
      displaySummary: displaySummary ?? this.displaySummary,
      currentLanguage: currentLanguage ?? this.currentLanguage,
    );
  }
}
