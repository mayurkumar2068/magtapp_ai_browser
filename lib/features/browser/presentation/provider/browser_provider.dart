import '../../data/repositories/repositories.dart';
import '../../domain/entities/browser_tab.dart';
import 'package:riverpod/riverpod.dart';


class BrowserState {
  final List<BrowserTab> tabs;
  final int activeIndex;
  BrowserState({required this.tabs, required this.activeIndex});

  BrowserState copyWith({List<BrowserTab>? tabs, int? activeIndex}) {
    return BrowserState(
      tabs: tabs ?? this.tabs,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}

class BrowserNotifier extends StateNotifier<BrowserState> {
  final BrowserRepository _repo = BrowserRepository();

  BrowserNotifier() : super(BrowserState(tabs: [], activeIndex: 0)) {
    _init();
  }

  void _init() {
    final saved = _repo.loadBrowserState();
    if (saved['tabs'] != null) {
      state = BrowserState(
        tabs: (saved['tabs'] as List).map((e) => BrowserTab.fromMap(e)).toList(),
        activeIndex: saved['activeIndex'] ?? 0,
      );
    } else {
      addTab();
    }
  }

  void updateUrl(int index, String url) {
    final updated = [...state.tabs];
    updated[index] = updated[index].copyWith(url: url);
    state = state.copyWith(tabs: updated);

    if (url.startsWith('http') && !url.contains("magtapp://home")) {
      _repo.saveHistory(url);
    }
    _repo.saveBrowserState(state.tabs, state.activeIndex);
  }

  void updateProgress(String tabId, int progress) {
    state = state.copyWith(
      tabs: state.tabs.map((t) => t.id == tabId ? t.copyWith(progress: progress) : t).toList(),
    );
  }

  void addTab() {
    final newTab = BrowserTab(id: DateTime.now().millisecondsSinceEpoch.toString());
    state = state.copyWith(tabs: [...state.tabs, newTab], activeIndex: state.tabs.length);
    _repo.saveBrowserState(state.tabs, state.activeIndex);
  }

  void closeTab(int index) {
    if (state.tabs.length > 1) {
      final updated = [...state.tabs]..removeAt(index);
      state = state.copyWith(
        tabs: updated,
        activeIndex: state.activeIndex >= updated.length ? updated.length - 1 : state.activeIndex,
      );
      _repo.saveBrowserState(state.tabs, state.activeIndex);
    }
  }


  void switchTab(int index) {
    state = state.copyWith(activeIndex: index);
    _repo.saveBrowserState(state.tabs, state.activeIndex);
  }
}

final browserProvider = StateNotifierProvider<BrowserNotifier, BrowserState>((ref) => BrowserNotifier());