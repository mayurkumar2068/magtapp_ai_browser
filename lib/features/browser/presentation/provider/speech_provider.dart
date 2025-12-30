import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechState {
  final bool isListening;
  final bool isEnabled;

  SpeechState({this.isListening = false, this.isEnabled = false});

  SpeechState copyWith({bool? isListening, bool? isEnabled}) {
    return SpeechState(
      isListening: isListening ?? this.isListening,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class SpeechNotifier extends StateNotifier<SpeechState> {
  SpeechNotifier() : super(SpeechState()) {
    _speech = stt.SpeechToText();
    initSpeech();
  }

  late final stt.SpeechToText _speech;

  Future<void> initSpeech() async {
    final enabled = await _speech.initialize(
      onError: (error) => print('Speech Error: $error'),
      onStatus: (status) => print('Speech Status: $status'),
    );
    state = state.copyWith(isEnabled: enabled);
  }

  Future<void> listen(Function(String) onResult) async {
    if (!state.isEnabled) return;

    if (!state.isListening) {
      final available = await _speech.listen(
        onResult: (val) {
          onResult(val.recognizedWords);
          if (val.finalResult) stop();
        },
      );
      if (available ?? false) state = state.copyWith(isListening: true);
    } else {
      await stop();
    }
  }

  Future<void> stop() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }
}

final speechProvider = StateNotifierProvider<SpeechNotifier, SpeechState>((ref) {
  return SpeechNotifier();
});
