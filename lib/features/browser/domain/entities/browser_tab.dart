class BrowserTab {
  final String id;
  final String url;
  final String title;
  final int progress;

  BrowserTab({
    required this.id,
    this.url = 'magtapp://home',
    this.title = 'New Tab',
    this.progress = 0,
  });

  BrowserTab copyWith({String? url, String? title, int? progress}) {
    return BrowserTab(
      id: this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'url': url,
    'title': title,
  };

  factory BrowserTab.fromMap(Map<dynamic, dynamic> map) => BrowserTab(
    id: map['id'],
    url: map['url'],
    title: map['title'],
    progress: 0,
  );
}