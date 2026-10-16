import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'demo_files.dart';

class FileStorageService {
  static Directory? _storageDir;

  static const Set<String> protectedFiles = {
    'canvasdemo.html',
    'sanddemo.html',
    'particledemo.html',
  };

  static const Set<String> optionalFiles = {
    'spacedemo.html',
    'synthdemo.html',
    'mazedemo.html',
  };

  static bool isProtected(String filename) {
    return protectedFiles.contains(filename.toLowerCase());
  }

  static bool isOptional(String filename) {
    return optionalFiles.contains(filename.toLowerCase());
  }

  static Future<Directory> getStorageDirectory() async {
    if (_storageDir != null && await _storageDir!.exists()) {
      return _storageDir!;
    }

    Directory baseDir;
    try {
      final extDir = await getExternalStorageDirectory();
      baseDir = extDir ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir = Directory('${Directory.systemTemp.path}/droid_monitor_storage');
    }

    final dir = Directory('${baseDir.path}/served_files');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _storageDir = dir;
    await ensureDemoFiles();
    return dir;
  }

  static Future<void> ensureDemoFiles() async {
    if (_storageDir == null) return;
    final dir = _storageDir!;
    
    // Core protected demos
    final demos = {
      'canvasdemo.html': DemoFiles.canvasDemoHtml,
      'sanddemo.html': DemoFiles.sandDemoHtml,
      'particledemo.html': DemoFiles.particleDemoHtml,
    };

    for (final entry in demos.entries) {
      final file = File('${dir.path}/${entry.key}');
      final expectedLength = entry.value.length;
      if (!await file.exists() || await file.length() != expectedLength) {
        await file.writeAsString(entry.value);
      }
    }

    // Optional demos (seeded initially, but user can delete)
    final optionalDemos = {
      'spacedemo.html': DemoFiles.spaceDemoHtml,
      'synthdemo.html': DemoFiles.synthDemoHtml,
      'mazedemo.html': DemoFiles.mazeDemoHtml,
    };

    for (final entry in optionalDemos.entries) {
      final file = File('${dir.path}/${entry.key}');
      if (!await file.exists()) {
        await file.writeAsString(entry.value);
      }
    }
  }

  static Future<void> restoreOptionalDemos() async {
    final dir = await getStorageDirectory();
    final optionalDemos = {
      'spacedemo.html': DemoFiles.spaceDemoHtml,
      'synthdemo.html': DemoFiles.synthDemoHtml,
      'mazedemo.html': DemoFiles.mazeDemoHtml,
    };
    for (final entry in optionalDemos.entries) {
      final file = File('${dir.path}/${entry.key}');
      await file.writeAsString(entry.value);
    }
  }

  static Future<List<Map<String, dynamic>>> listFiles() async {
    final dir = await getStorageDirectory();
    final List<Map<String, dynamic>> files = [];

    if (!await dir.exists()) return files;

    final entities = dir.listSync();
    for (final entity in entities) {
      if (entity is File) {
        final stat = entity.statSync();
        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        final mimeType = lookupMimeType(entity.path) ?? 'application/octet-stream';
        final isImage = mimeType.startsWith('image/');
        final isVideo = mimeType.startsWith('video/');
        final isAudio = mimeType.startsWith('audio/');
        final isText = mimeType.startsWith('text/') || mimeType.contains('json') || mimeType.contains('javascript');

        final isProtectedFile = isProtected(name);
        final isOptionalFile = isOptional(name);

        files.add({
          'name': name,
          'sizeBytes': stat.size,
          'sizeFormatted': _formatBytes(stat.size),
          'modified': stat.modified.toIso8601String(),
          'mimeType': mimeType,
          'isImage': isImage,
          'isVideo': isVideo,
          'isAudio': isAudio,
          'isText': isText,
          'isProtected': isProtectedFile,
          'isOptional': isOptionalFile,
          'downloadUrl': '/files/${Uri.encodeComponent(name)}',
        });
      }
    }

    // Sort newest first
    files.sort((a, b) => (b['modified'] as String).compareTo(a['modified'] as String));
    return files;
  }

  static Future<Map<String, dynamic>> getStorageUsage() async {
    final files = await listFiles();
    int totalBytes = 0;
    for (final f in files) {
      totalBytes += (f['sizeBytes'] as int? ?? 0);
    }
    return {
      'count': files.length,
      'bytes': totalBytes,
      'formatted': _formatBytes(totalBytes),
    };
  }

  static Future<File?> saveFile(String rawFilename, List<int> bytes) async {
    final dir = await getStorageDirectory();
    final safeName = _sanitizeFilename(rawFilename);
    final targetFile = File('${dir.path}/$safeName');
    await targetFile.writeAsBytes(bytes);
    return targetFile;
  }

  static Future<File?> saveFileFromStream(String rawFilename, Stream<List<int>> byteStream) async {
    final dir = await getStorageDirectory();
    final safeName = _sanitizeFilename(rawFilename);
    final targetFile = File('${dir.path}/$safeName');
    final sink = targetFile.openWrite();
    try {
      await for (final chunk in byteStream) {
        sink.add(chunk);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return targetFile;
  }

  static Future<bool> deleteFile(String rawFilename) async {
    final safeName = _sanitizeFilename(rawFilename);
    if (isProtected(safeName)) {
      // Deletion blocked for protected demo files
      return false;
    }
    final dir = await getStorageDirectory();
    final file = File('${dir.path}/$safeName');
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  static Future<File?> getFile(String rawFilename) async {
    final dir = await getStorageDirectory();
    final safeName = _sanitizeFilename(rawFilename);
    final file = File('${dir.path}/$safeName');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  static String _sanitizeFilename(String name) {
    // Strip directories to prevent path traversal
    var clean = name.replaceAll('\\', '/').split('/').last;
    clean = clean.replaceAll(RegExp(r'[^\w\.\-\s\(\)\[\]]'), '_');
    if (clean.isEmpty) {
      clean = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(count >= 10 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}
