import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

// Represents the status of a single file upload
enum UploadStatus { idle, uploading, success, failed }

// Holds all state for one file being uploaded
class UploadItem {
  final File file;
  final String fileName;
  final String storagePath; // full path in Firebase Storage
  final String fileType; // "image" | "video" | "file"

  UploadStatus status;
  double progress; // 0.0 – 1.0
  String? downloadUrl;
  String? error;

  UploadItem({
    required this.file,
    required this.fileName,
    required this.storagePath,
    required this.fileType,
    this.status = UploadStatus.idle,
    this.progress = 0.0,
  });
}

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Detect file type from extension
  static String detectFileType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png') return 'image';
    if (ext == '.mp4') return 'video';
    if (ext == '.pdf') return 'file';
    return 'file'; // default fallback
  }

  // Upload a single file, tracking progress via callback
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(storagePath);

    final uploadTask = ref.putFile(file);

    // Listen for progress events
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      if (onProgress != null && snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    // Wait for upload to complete
    await uploadTask;

    // Return the public download URL
    return await ref.getDownloadURL();
  }

  // Upload all items in a list, updating each UploadItem in place.
  // Call setState externally after each update via the onItemUpdated callback.
  Future<void> uploadAll({
    required List<UploadItem> items,
    void Function(UploadItem item)? onItemUpdated,
  }) async {
    for (final item in items) {
      item.status = UploadStatus.uploading;
      item.progress = 0.0;
      item.error = null;
      onItemUpdated?.call(item);

      try {
        item.downloadUrl = await uploadFile(
          file: item.file,
          storagePath: item.storagePath,
          onProgress: (progress) {
            item.progress = progress;
            onItemUpdated?.call(item);
          },
        );
        item.status = UploadStatus.success;
      } catch (e) {
        item.status = UploadStatus.failed;
        item.error = e.toString();
      }

      onItemUpdated?.call(item);
    }
  }

  // Retry only the failed items
  Future<void> retryFailed({
    required List<UploadItem> items,
    void Function(UploadItem item)? onItemUpdated,
  }) async {
    final failedItems = items.where((i) => i.status == UploadStatus.failed).toList();
    await uploadAll(items: failedItems, onItemUpdated: onItemUpdated);
  }
}