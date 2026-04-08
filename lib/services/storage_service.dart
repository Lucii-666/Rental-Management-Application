import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService extends ChangeNotifier {
  SupabaseStorageClient get _storage => Supabase.instance.client.storage;
  static const _bucket = 'uploads';

  Future<String?> uploadProfileImage(String uid, File file) async {
    try {
      final path = 'profiles/$uid.jpg';
      await _storage.from(_bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('StorageService Error: $e');
      if (e is StorageException) {
        throw e.message;
      }
      throw e.toString();
    }
  }

  Future<String?> uploadIdentityDoc(String uid, String type, File file) async {
    try {
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'identities/$uid/$fileName';
      await _storage.from(_bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('StorageService Error: $e');
      if (e is StorageException) {
        throw e.message;
      }
      throw e.toString();
    }
  }

  Future<String?> uploadPropertyImage(String propertyId, File file) async {
    try {
      final path = 'properties/$propertyId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _storage.from(_bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('StorageService Error: $e');
      if (e is StorageException) throw e.message;
      throw e.toString();
    }
  }

  Future<String?> uploadRoomImage(String propertyId, String roomId, File file) async {
    try {
      final path = 'rooms/$propertyId/$roomId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _storage.from(_bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('StorageService Error: $e');
      if (e is StorageException) throw e.message;
      throw e.toString();
    }
  }

  Future<String?> uploadMaintenanceImage(String requestId, File file) async {
    try {
      final path = 'maintenance/$requestId.jpg';
      await _storage.from(_bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('StorageService Error: $e');
      if (e is StorageException) {
        throw e.message;
      }
      throw e.toString();
    }
  }
}
