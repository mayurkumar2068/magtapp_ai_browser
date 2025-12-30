import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/constant/constants.dart';

class AIService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 40),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      "Content-Type": "application/json",
      "x-use-cache": "true",
    },
  ));

  final String _apiKey = Constants.apiKey;

  /// Summarizes long text by first sanitizing it to fit LLM token limits (1024 tokens).
  Future<String> summarize(String text) async {
    if (text.trim().isEmpty) return "Text is empty.";
    final String cleanedText = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .trim();
    final String finalInput = cleanedText.length > 3000
        ? cleanedText.substring(0, 3000)
        : cleanedText;

    try {
      final response = await _dio.post(
        Constants.summaryEndpoint,
        options: Options(headers: {"Authorization": "Bearer $_apiKey"}),
        data: {
          "inputs": finalInput,
          "parameters": {
            "min_length": 60,
            "max_length": 160,
            "do_sample": false,
          },
          "options": {"wait_for_model": true} // Critical: Wakes up the model if idle
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return response.data[0]["summary_text"] ?? "No content found.";
      }
      return "Unexpected AI Response.";
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  Future<String> translate(String text, String targetLang) async {
    if (text.trim().isEmpty) return text;

    // Supported models mapping for Hugging Face Router
    final Map<String, String> langModels = {
      "hi": "Helsinki-NLP/opus-mt-en-hi", // English to Hindi
      "es": "Helsinki-NLP/opus-mt-en-es", // English to Spanish
      "fr": "Helsinki-NLP/opus-mt-en-fr", // English to French
    };

    final model = langModels[targetLang.toLowerCase()];
    if (model == null) return text; // Fallback to original text

    try {
      final response = await _dio.post(
        "${Constants.routerBaseUrl}$model",
        options: Options(headers: {"Authorization": "Bearer $_apiKey"}),
        data: {
          "inputs": text,
          "options": {"wait_for_model": true}
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return response.data[0]["translation_text"] ?? text;
      }
      return text;
    } catch (e) {
      debugPrint("Translation Error: $e");
      return text;
    }
  }

  /// Standardized error handling for SDE 2 production-ready code.
  String _handleDioError(DioException e) {
    if (e.response?.statusCode == 503) return "AI is warming up... Try again in 5s.";
    if (e.response?.statusCode == 410) return "Endpoint Migration needed. Check Router URL.";
    return "AI Service Error: ${e.type}";
  }
}

