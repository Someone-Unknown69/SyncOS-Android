import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:external_path/external_path.dart';
import '../domain/i_file_service.dart';

// storing and picking infrastructure of ftp

class FileServiceImpl implements IFileService {
  @override
  Future<String?> pickFile() async {
    final result = await FilePicker.pickFiles();
    return result?.files.single.path;
  }

  @override
  Future<String> getExternalStoragePath() async {
    return await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOAD);
  }

  @override
  Future<String> calculateChecksum(String filePath) async {
    final stream = File(filePath).openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  @override
  Stream<List<int>> getFileStream(String filePath) => File(filePath).openRead();
}