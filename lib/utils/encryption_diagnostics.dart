import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Diagnostics utility for encryption issues
class EncryptionDiagnostics {
  /// Analyze an encrypted file and provide diagnostic information
  static Future<FileDiagnostics> analyzeFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return FileDiagnostics(
          exists: false,
          error: 'File does not exist',
        );
      }

      final fileSize = await file.length();
      final raf = await file.open();
      
      // Read first 8 bytes (header)
      final header = await raf.read(8);
      await raf.close();

      // Detect format
      EncryptionFormat format = EncryptionFormat.unknown;
      String formatDescription = 'Unknown';
      
      if (header.length >= 4) {
        final magic = header.sublist(0, 4);
        
        if (magic[0] == 0x4C && magic[1] == 0x4B && magic[2] == 0x52) {
          if (magic[3] == 0x53) {
            format = EncryptionFormat.ctrStreamed;
            formatDescription = 'CTR Streamed (LKRS)';
          } else if (magic[3] == 0x47) {
            format = EncryptionFormat.gcm;
            formatDescription = 'GCM (LKRG)';
          } else if (magic[3] == 0x44) {
            format = EncryptionFormat.cbcWithHeader;
            formatDescription = 'CBC with Header (LKRD)';
          }
        } else {
          format = EncryptionFormat.legacyCbc;
          formatDescription = 'Legacy CBC (no header)';
        }
      }

      // Check if data length is valid for CBC
      bool validForCbc = false;
      int dataLength = fileSize;
      
      if (format == EncryptionFormat.cbcWithHeader) {
        dataLength = fileSize - 8; // Subtract header
      } else if (format == EncryptionFormat.legacyCbc) {
        dataLength = fileSize;
      }
      
      validForCbc = (dataLength % 16 == 0);

      return FileDiagnostics(
        exists: true,
        fileSize: fileSize,
        format: format,
        formatDescription: formatDescription,
        magicBytes: header.sublist(0, 4),
        validForCbc: validForCbc,
        dataLength: dataLength,
        remainder: dataLength % 16,
      );
    } catch (e) {
      return FileDiagnostics(
        exists: true,
        error: 'Error analyzing file: $e',
      );
    }
  }

  /// Print diagnostic information
  static Future<void> printDiagnostics(String filePath) async {
    final diag = await analyzeFile(filePath);
    
    debugPrint('=== Encryption Diagnostics ===');
    debugPrint('File: $filePath');
    debugPrint('Exists: ${diag.exists}');
    
    if (diag.error != null) {
      debugPrint('Error: ${diag.error}');
      return;
    }
    
    debugPrint('File Size: ${diag.fileSize} bytes');
    debugPrint('Format: ${diag.formatDescription}');
    debugPrint('Magic Bytes: ${diag.magicBytes?.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    debugPrint('Data Length: ${diag.dataLength} bytes');
    debugPrint('Valid for CBC: ${diag.validForCbc}');
    
    if (!diag.validForCbc) {
      debugPrint('⚠️ WARNING: Data length is not a multiple of 16 bytes');
      debugPrint('   Remainder: ${diag.remainder} bytes');
      debugPrint('   This file cannot be decrypted with CBC mode');
    }
    
    debugPrint('==============================');
  }

  /// Attempt to fix a corrupted CBC file by padding
  /// WARNING: This may not recover the original data!
  static Future<bool> attemptCbcPadFix(String filePath, String outputPath) async {
    try {
      final diag = await analyzeFile(filePath);
      
      if (diag.validForCbc) {
        debugPrint('[Fix] File is already valid for CBC');
        return false;
      }

      if (diag.format != EncryptionFormat.legacyCbc && 
          diag.format != EncryptionFormat.cbcWithHeader) {
        debugPrint('[Fix] File is not CBC format, cannot fix');
        return false;
      }

      final file = File(filePath);
      final data = await file.readAsBytes();
      
      // Calculate padding needed
      final remainder = data.length % 16;
      final paddingNeeded = 16 - remainder;
      
      debugPrint('[Fix] Adding $paddingNeeded bytes of padding');
      
      // Add zero padding (this is a last resort and may not work)
      final paddedData = Uint8List(data.length + paddingNeeded);
      paddedData.setRange(0, data.length, data);
      // Rest is already zeros
      
      await File(outputPath).writeAsBytes(paddedData);
      
      debugPrint('[Fix] Padded file saved to: $outputPath');
      debugPrint('[Fix] WARNING: This may not decrypt correctly!');
      
      return true;
    } catch (e) {
      debugPrint('[Fix] Error: $e');
      return false;
    }
  }
}

/// Encryption format types
enum EncryptionFormat {
  unknown,
  legacyCbc,      // Old format, no header
  cbcWithHeader,  // CBC with LKRD header
  ctrStreamed,    // CTR with LKRS header
  gcm,            // GCM with LKRG header
}

/// Diagnostic information about an encrypted file
class FileDiagnostics {
  final bool exists;
  final int? fileSize;
  final EncryptionFormat? format;
  final String? formatDescription;
  final List<int>? magicBytes;
  final bool validForCbc;
  final int? dataLength;
  final int? remainder;
  final String? error;

  FileDiagnostics({
    required this.exists,
    this.fileSize,
    this.format,
    this.formatDescription,
    this.magicBytes,
    this.validForCbc = false,
    this.dataLength,
    this.remainder,
    this.error,
  });

  @override
  String toString() {
    if (error != null) return 'Error: $error';
    
    return '''
FileDiagnostics:
  Exists: $exists
  Size: $fileSize bytes
  Format: $formatDescription
  Valid for CBC: $validForCbc
  Data Length: $dataLength bytes
  Remainder: $remainder bytes
''';
  }
}
