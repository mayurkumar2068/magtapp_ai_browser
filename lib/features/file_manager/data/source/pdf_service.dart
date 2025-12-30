import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../domain/entities/file_entity.dart';

class PdfService {

  Future<String> extractTextFromPdf(String filePath) async {
    try {
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      return "Error extracting PDF text: $e";
    }
  }
}
class FileNotifier extends StateNotifier<List<FileEntity>> {
  final _bookmarkBox = Hive.box('bookmarks_box');
  final _fileBox = Hive.box('files_box');
  FileNotifier() : super([]) {
    _loadFilesFromHive();
  }

  Future<void> saveAiReport(File file, String originalName) async {
    final fileSize = (await file.length()) / 1024;
    final entity = FileEntity(
      path: file.path,
      name: originalName,
      size: "${fileSize.toStringAsFixed(2)} KB",
      type: 'pdf',
      date: DateTime.now(),
      isDownloaded: true,
    );
    await _saveToHive(entity);
  }



  Future<void> _saveToHive(FileEntity entity) async {
    await _fileBox.put(entity.path, entity.toMap());
    state = [entity, ...state.where((f) => f.path != entity.path)];
  }

  void _loadFilesFromHive() {
    try {
      final savedFiles = _fileBox.values
          .map((item) => FileEntity.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      savedFiles.sort((a, b) => b.date.compareTo(a.date));
      state = savedFiles;
    } catch (e) {
      debugPrint("Hive Load Error: $e");
    }
  }


  Future<void> pickAndSaveFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx', 'xlsx'],
      );
      if (result != null && result.files.single.path != null) {
        File pickedFile = File(result.files.single.path!);
        String fileName = result.files.single.name;
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String savePath = p.join(appDocDir.path, fileName);
        await pickedFile.copy(savePath);
        final newFile = FileEntity(
          path: savePath,
          name: fileName,
          size: "${(result.files.single.size / 1024).toStringAsFixed(2)} KB",
          type: result.files.single.extension ?? 'file',
          date: DateTime.now(),
          isDownloaded: false,
        );

        await _fileBox.put(newFile.path, newFile.toMap());
        state = [newFile, ...state.where((f) => f.path != newFile.path)];
      }
    } catch (e) {
      debugPrint("File Picking Error: $e");
    }
  }

  Future<void> downloadFileFromUrl(String url, String fileName) async {
    try {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');

        // Create folder if not exists
        if (!downloadsDir.existsSync()) {
          downloadsDir.createSync(recursive: true);
        }
      } else {
        // iOS only supports app folder
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      String savePath = p.join(downloadsDir.path, fileName);

      await Dio().download(url, savePath);
      final fileSize = await File(savePath).length();

      final fileEntity = FileEntity(
        path: savePath,
        name: fileName,
        size: "${(fileSize / 1024).toStringAsFixed(2)} KB",
        type: fileName.split('.').last,
        date: DateTime.now(),
        isDownloaded: true,
      );

      // Save inside Hive (for showing in your File Manager screen)
      await _fileBox.put(fileEntity.path, fileEntity.toMap());
      state = [fileEntity, ...state.where((f) => f.path != fileEntity.path)];

      debugPrint("Downloaded to: $savePath");

    } catch (e) {
      debugPrint("Download Error: $e");
    }
  }


  Future<void> deleteFile(FileEntity file) async {
    try {
      final ioFile = File(file.path);
      if (await ioFile.exists()) {
        await ioFile.delete();
      }
      await _fileBox.delete(file.path);
      state = state.where((f) => f.path != file.path).toList();
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  Future<void> viewFile(String filePath) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      debugPrint("Could not open file: ${result.message}");
    }
  }

  Future<void> saveBookmark(String url) async {
    if (!_bookmarkBox.containsKey(url)) {
      await _bookmarkBox.put(url, {'url': url, 'date': DateTime.now().toIso8601String()});
    }
  }

  /// Clear all files and bookmarks
  Future<void> clearDatabase() async {
    await _fileBox.clear();
    await _bookmarkBox.clear();
    state = [];
  }


}


final fileProvider = StateNotifierProvider<FileNotifier, List<FileEntity>>((ref) {
  return FileNotifier();
});