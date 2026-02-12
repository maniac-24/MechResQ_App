import 'dart:io';
import 'dart:async';

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

/// Production-grade Firebase Storage upload service
/// 
/// IMPORTANT NOTES FOR CALLERS:
/// - Storage paths must be unique to avoid overwriting files
/// - Recommended path format: "requests/{requestId}/attachments/{uuid}.{ext}"
/// - Include userId, timestamp, or UUID to prevent collisions
/// 
/// Example usage:
/// ```dart
/// final item = UploadItem(
///   file: file,
///   fileName: 'photo.jpg',
///   storagePath: 'requests/${requestId}/attachments/${uuid()}.jpg',
///   fileType: UploadService.detectFileType('photo.jpg'),
/// );
/// 
/// await uploadService.uploadAll(
///   items: [item],
///   onItemUpdated: (item) => setState(() {}),
/// );
/// ```
class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Detect file type from extension
  /// Supports common image, video, and document formats
  static String detectFileType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    
    // Image formats (including iOS HEIC and modern WebP)
    if ({'.jpg', '.jpeg', '.png', '.webp', '.heic'}.contains(ext)) {
      return 'image';
    }
    
    // Video formats
    if (ext == '.mp4') return 'video';
    
    // Document formats
    if (ext == '.pdf') return 'file';
    
    return 'file'; // default fallback
  }

  /// Upload a single file with progress tracking
  /// 
  /// Guarantees:
  /// - Progress callback receives values 0.0 to 1.0
  /// - Listener is always cancelled (no memory leaks)
  /// - Errors are properly propagated
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(storagePath);
    final uploadTask = ref.putFile(file);

    // Track subscription for guaranteed cleanup
    StreamSubscription<TaskSnapshot>? subscription;

    try {
      // Listen for progress events
      subscription = uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          if (onProgress != null && snapshot.totalBytes > 0) {
            onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
          }
        },
        onError: (_) {
          // Error handling happens in catch block below
          // This prevents uncaught async errors
        },
      );

      // Wait for upload to complete
      await uploadTask;

      // Return the public download URL
      return await ref.getDownloadURL();
    } finally {
      // CRITICAL: Always cancel subscription to prevent memory leaks
      await subscription?.cancel();
    }
  }

  /// Upload all items in a list, updating each UploadItem in place.
  /// 
  /// Upload strategy: Sequential (not parallel)
  /// - Prevents bandwidth spikes
  /// - Avoids Firebase throttling
  /// - Predictable progress UX
  /// 
  /// Call setState externally after each update via the onItemUpdated callback.
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
      } on FirebaseException catch (e) {
        // Handle Firebase-specific errors with user-friendly messages
        item.status = UploadStatus.failed;
        item.error = e.message ?? 'Upload failed';
      } catch (e) {
        // Handle other errors (network, file access, etc.)
        item.status = UploadStatus.failed;
        item.error = 'Upload failed';
      }

      onItemUpdated?.call(item);
    }
  }

  /// Retry only the failed items
  /// 
  /// Maintains upload order and reuses existing UploadItem state
  Future<void> retryFailed({
    required List<UploadItem> items,
    void Function(UploadItem item)? onItemUpdated,
  }) async {
    final failedItems = items.where((i) => i.status == UploadStatus.failed).toList();
    await uploadAll(items: failedItems, onItemUpdated: onItemUpdated);
  }
}