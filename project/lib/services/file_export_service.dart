import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';

class FileExportService {
  Future<void> exportAndShare(dynamic content, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');

      if (content is String) {
        await file.writeAsString(content);
      } else if (content is Uint8List) {
        await file.writeAsBytes(content);
      } else {
        throw ArgumentError('Unsupported content type');
      }

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      print('Error exporting file: $e');
    }
  }
}
