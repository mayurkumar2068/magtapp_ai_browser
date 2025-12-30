// lib/features/browser/data/repositories/browser_repository_impl.dart
import 'package:hive/hive.dart';

import '../../domain/entities/browser_tab.dart';

class BrowserRepository {
  final _stateBox = Hive.box('browser_state');
  final _historyBox = Hive.box('browser_history');

  void saveBrowserState(List<BrowserTab> tabs, int activeIndex) {
    _stateBox.put('tabs', tabs.map((e) => e.toMap()).toList());
    _stateBox.put('activeIndex', activeIndex);
  }

  Map<String, dynamic> loadBrowserState() {
    return {
      'tabs': _stateBox.get('tabs'),
      'activeIndex': _stateBox.get('activeIndex'),
    };
  }

  void saveHistory(String url) {
    _historyBox.put(url, DateTime.now().millisecondsSinceEpoch);
  }
}