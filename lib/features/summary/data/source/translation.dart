import 'package:dio/dio.dart';

class TranslationService {
  final Dio _dio = Dio();

  Future<String> translate(String text, String targetLang) async {
    try {
      final response = await _dio.get(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: {
          'client': 'gtx',
          'sl': 'en',
          'tl': targetLang,
          'dt': 't',
          'q': text,
        },
      );
      return response.data[0][0][0].toString();
    } catch (e) {
      return text;
    }
  }
}