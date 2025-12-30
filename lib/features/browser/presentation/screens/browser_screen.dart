import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/constant/constants.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/provider/setting_provider.dart';
import '../../../file_manager/data/source/pdf_service.dart';
import '../../../summary/presentation/screen/summary_pannel_widget.dart';
import '../provider/browser_provider.dart';
import '../../../summary/presentation/providers/summary_provider.dart';
import '../provider/speech_provider.dart';


class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final Map<String, InAppWebViewController> _controllers = {};
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    await _speech.initialize(
        onError: (error) => debugPrint('Speech Error: $error'),
        onStatus: (status) => debugPrint('Speech Status: $status'));
  }

  void _syncSearchController(String url) {
    _searchController.text = (url == 'magtapp://home' || url.isEmpty) ? '' : url;
  }

  void _handleUrlSubmit(String input, dynamic state) {
    if (input.trim().isEmpty) return;
    String finalUrl = input.trim();
    if (!finalUrl.contains("://")) {
      finalUrl = finalUrl.contains(".")
          ? "https://$finalUrl"
          : Constants.googleSearchUrl(finalUrl);
    }

    ref.read(browserProvider.notifier).updateUrl(state.activeIndex, finalUrl);
    _controllers[state.tabs[state.activeIndex].id]
        ?.loadUrl(urlRequest: URLRequest(url: WebUri(finalUrl)));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(browserProvider);
    final activeTab = browserState.tabs.isNotEmpty
        ? browserState.tabs[browserState.activeIndex]
        : null;
    final currentLang = ref.watch(appLanguageProvider);

    if (activeTab == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isHome = activeTab.url == 'magtapp://home';

    return Scaffold(
      appBar: isHome ? null : _buildBrowserAppBar(browserState, activeTab, currentLang),
      body: Stack(
        children: [
          IndexedStack(
            index: browserState.activeIndex,
            children: browserState.tabs.map((tab) {
              if (tab.url == 'magtapp://home') return _buildHomeScreen(currentLang, browserState);
              return InAppWebView(
                key: ValueKey(tab.id),
                initialUrlRequest: URLRequest(url: WebUri(tab.url)),
                onWebViewCreated: (controller) => _controllers[tab.id] = controller,
                onProgressChanged: (c, p) =>
                    ref.read(browserProvider.notifier).updateProgress(tab.id, p),
                onLoadStop: (c, url) {
                  ref.read(browserProvider.notifier)
                      .updateUrl(browserState.tabs.indexOf(tab), url.toString());
                  _syncSearchController(url.toString());
                },
              );
            }).toList(),
          ),
          if (!isHome && activeTab.progress < 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: activeTab.progress / 100,
                backgroundColor: Colors.transparent,
                color: Colors.blueAccent,
                minHeight: 2,
              ),
            ),
        ],
      ),
      floatingActionButton:
      isHome ? null : _buildAIButton(context, activeTab.id, currentLang),
    );
  }

  // ---------------- APP BAR ----------------
  AppBar _buildBrowserAppBar(dynamic browserState, dynamic activeTab, String lang) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(10),
        child: const SizedBox(),
      ),
      titleSpacing: 0,
      shape: const Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueAccent,size: 26,),
        onPressed: () => _controllers[activeTab.id]?.goBack(),
      ),
      title: Container(
        margin: const EdgeInsets.only(right: 12),
        child: _buildSearchField(browserState, isLarge: true, lang: lang),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent,size: 26,),
          onPressed: () => _controllers[activeTab.id]?.reload(),
        ),
        InkWell(
          onTap: () => _showTabSwitcher(browserState),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3),),
            ),
            child: Center(
              child: Text(
                "${browserState.tabs.length}",
                style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) => _handleMenuAction(value, activeTab, browserState),
          itemBuilder: (context) => [
            _menuItem(Icons.download_rounded, L10n.t('download_file', lang), "download"),
            _menuItem(Icons.add_box_outlined, L10n.t('new_tab', lang), "new_tab"),
            _menuItem(Icons.history_rounded, L10n.t('history', lang), "history"),
            _menuItem(Icons.bookmark, "Bookmark", "bookmark"),
            _menuItem(Icons.delete_forever, "Clear Database", "clear_database"),
            _menuItem(Icons.close, "Close Tab", "close_tab"),
            const PopupMenuDivider(),
            _menuItem(Icons.computer_rounded, L10n.t('desktop_site', lang), "desktop_mode"),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ---------------- SEARCH FIELD ----------------
  Widget _buildSearchField(dynamic state, {required bool isLarge, required String lang}) {
    return Container(
      height: isLarge ? 52 : 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: L10n.t('browser_hint', lang),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 24),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  ref.watch(speechProvider).isListening ? Icons.mic : Icons.mic_none,
                  color: ref.watch(speechProvider).isListening ? Colors.red : Colors.grey,
                ),
                onPressed: () {
                  ref.read(speechProvider.notifier).listen((words) {
                    _searchController.text = words;
                    if (!ref.read(speechProvider).isListening) {
                      _handleUrlSubmit(_searchController.text, ref.read(browserProvider));
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_circle_right_rounded,
                    color: Colors.blueAccent, size: 28),
                onPressed: () => _handleUrlSubmit(_searchController.text, state),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
        onSubmitted: (val) => _handleUrlSubmit(val, state),
      ),
    );
  }

  // ---------------- HOME SCREEN ----------------
  Widget _buildHomeScreen(String lang, dynamic state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withOpacity(0.05), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.auto_awesome_rounded, size: 70, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text('MagTapp AI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: _buildSearchField(state, isLarge: true, lang: lang),
            ),
            const SizedBox(height: 24),
            Text(L10n.t('browser_welcome', lang), style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ---------------- POPUP MENU ITEM ----------------
  PopupMenuItem<String> _menuItem(IconData icon, String text, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ---------------- AI SUMMARIZE BUTTON ----------------
  Widget _buildAIButton(BuildContext context, String tabId, String lang) {
    final summaryState = ref.watch(summaryProvider);
    final bool isProcessing = summaryState.isLoading;

    return FloatingActionButton.extended(
      elevation: isProcessing ? 0 : 4,
      backgroundColor: isProcessing ? Colors.grey : Colors.blueAccent,
      onPressed: isProcessing
          ? null
          : () async {
        final controller = _controllers[tabId];
        if (controller != null) {
          await ref.read(summaryProvider.notifier).summarizeWebPage(controller);
          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: const SummaryPanel(),
              ),
            );
          }
        }
      },
      label: isProcessing
          ? Text(L10n.t('processing', lang),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
          : Text(L10n.t('summarize', lang),
          style: const TextStyle(fontWeight: FontWeight.bold)),
      icon: isProcessing
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      )
          : const Icon(Icons.auto_awesome_rounded),
    );
  }

  // ---------------- TAB SWITCHER ----------------
  void _showTabSwitcher(dynamic browserState) {
    final currentLang = ref.watch(appLanguageProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${L10n.t('open_tabs', currentLang)} (${browserState.tabs.length})",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: Colors.blueAccent, size: 30),
                      onPressed: () {
                        ref.read(browserProvider.notifier).addTab();
                        _searchController.clear();
                        Navigator.pop(context);
                      },
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: browserState.tabs.length,
                  itemBuilder: (context, index) {
                    final tab = browserState.tabs[index];
                    final bool isActive = index == browserState.activeIndex;
                    return ListTile(
                      title: Text(
                        tab.url.isEmpty || tab.url == 'magtapp://home'
                            ? 'New Tab'
                            : tab.url,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.blueAccent : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isActive
                          ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                          : null,
                      onTap: () {
                        ref.read(browserProvider.notifier).switchTab(index);
                        _syncSearchController(tab.url);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- MENU ACTIONS ----------------
  void _handleMenuAction(String value, dynamic activeTab, dynamic browserState) async {
    final controller = _controllers[activeTab.id];

    switch (value) {
      case "download":
        final url = await controller?.getUrl();
        if (url != null) {
          ref.read(fileProvider.notifier).downloadFileFromUrl(
            url.toString(),
            "${DateTime.now().millisecondsSinceEpoch}.pdf",
          );
        }
        break;

      case "new_tab":
        ref.read(browserProvider.notifier).addTab();
        _searchController.clear();
        break;

      case "history":
        Navigator.pushNamed(context, "/history");
        break;

      case "desktop_mode":
        break;

      case "bookmark":
        final url = await controller?.getUrl();
        if (url != null) {
          ref.read(fileProvider.notifier).saveBookmark(url.toString());
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Bookmark saved")));
        }
        break;

      case "clear_database":
        await ref.read(fileProvider.notifier).clearDatabase();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Database cleared")));
        break;

      case "close_tab":
        ref.read(browserProvider.notifier).closeTab(browserState.activeIndex);
        break;
    }
  }
}


