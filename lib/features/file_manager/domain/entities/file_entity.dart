class FileEntity {
  final String path;
  final String name;
  final String size;
  final String type;
  final DateTime date;
  final bool isDownloaded;

  FileEntity({
    required this.path, required this.name, required this.size,
    required this.type, required this.date, this.isDownloaded = false,
  });

  Map<String, dynamic> toMap() => {
    'path': path, 'name': name, 'size': size, 'type': type,
    'date': date.toIso8601String(), 'isDownloaded': isDownloaded,
  };

  factory FileEntity.fromMap(Map<String, dynamic> map) => FileEntity(
    path: map['path'], name: map['name'], size: map['size'], type: map['type'],
    date: DateTime.parse(map['date']),
    isDownloaded: map['isDownloaded'] ?? false,
  );
}