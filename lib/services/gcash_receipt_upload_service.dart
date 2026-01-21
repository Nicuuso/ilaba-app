import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for uploading GCash receipts to Supabase storage
class GCashReceiptUploadService {
  static const String bucketName = 'gcash-receipts';
  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2MB

  /// Upload a receipt file and return the public URL
  /// 
  /// Parameters:
  /// - filePath: Path to the image file
  /// - userId: Authenticated user's Supabase ID (for RLS policy path)
  /// 
  /// Returns: Public URL of uploaded file or null if upload fails
  static Future<String?> uploadReceipt(
    String filePath,
    String userId,
  ) async {
    try {
      final file = File(filePath);

      // Check file exists
      if (!await file.exists()) {
        debugPrint('❌ File does not exist: $filePath');
        return null;
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        debugPrint(
          '❌ File too large: ${fileSize / 1024 / 1024}MB (max: 2MB)',
        );
        throw Exception(
          'File too large. Maximum size is 2MB. Your file is ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
        );
      }

      debugPrint('📤 Uploading GCash receipt...');
      debugPrint('📁 File size: ${(fileSize / 1024).toStringAsFixed(2)}KB');
      debugPrint('👤 Supabase User ID: $userId');

      // Use admin client (service role) to bypass RLS
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
      
      debugPrint('🔑 SUPABASE_URL: $supabaseUrl');
      debugPrint('🔑 SERVICE_ROLE_KEY exists: ${serviceRoleKey != null && serviceRoleKey.isNotEmpty}');
      debugPrint('🔑 SERVICE_ROLE_KEY length: ${serviceRoleKey?.length}');
      debugPrint('🔑 SERVICE_ROLE_KEY starts with: ${serviceRoleKey?.substring(0, 20)}...');
      
      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        throw Exception('SUPABASE_URL not found in .env');
      }
      if (serviceRoleKey == null || serviceRoleKey.isEmpty) {
        throw Exception('SUPABASE_SERVICE_ROLE_KEY not found in .env');
      }
      
      debugPrint('✅ Creating admin client with service role key...');
      final adminClient = SupabaseClient(supabaseUrl, serviceRoleKey);
      debugPrint('✅ Admin client created');

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'gcash_receipt_$timestamp.jpg';
      final filePath2 = '$userId/$fileName';

      debugPrint('📝 Uploading to: $filePath2');
      debugPrint('📝 Bucket: $bucketName');

      // Upload file with admin client (bypasses RLS)
      debugPrint('🚀 Calling adminClient.storage.from().upload()...');
      await adminClient.storage.from(bucketName).upload(
            filePath2,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      debugPrint('✅ File uploaded to storage');

      // Get public URL using regular client
      final supabase = Supabase.instance.client;
      final publicUrl = supabase.storage.from(bucketName).getPublicUrl(filePath2);

      debugPrint('✅ Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      rethrow;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}
