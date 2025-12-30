class Constants {
  static const String apiKey = String.fromEnvironment('HF_API_KEY');
  static const String routerBaseUrl = 'https://router.huggingface.co/hf-inference/models/';
  static const String bartSummaryModel = 'facebook/bart-large-cnn';
  static const String summaryEndpoint = '$routerBaseUrl$bartSummaryModel';
  static const String translationModel = 'Helsinki-NLP/opus-mt-en-es'; // example
  static const String translationEndpoint = '$routerBaseUrl$translationModel';

  static String googleSearchUrl(String query) =>
      'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
}
