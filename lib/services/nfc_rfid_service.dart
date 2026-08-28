import 'dart:async';

import 'package:nfc_manager/nfc_manager.dart';

class NFCRFIDService {
  static bool _isScanning = false;

  /// Kiểm tra thiết bị có hỗ trợ NFC không
  static Future<bool> isNFCAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      print('Lỗi kiểm tra NFC: $e');
      return false;
    }
  }

  /// Kiểm tra có đang quét không
  static bool isCurrentlyScanning() => _isScanning;

  /// Bắt đầu quét thẻ NFC/RFID
  static Future<Map<String, dynamic>?> scanRFIDTag({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      bool isAvailable = await isNFCAvailable();
      if (!isAvailable) {
        throw Exception('Thiết bị không hỗ trợ NFC');
      }

      if (_isScanning) {
        throw Exception('Đang quét thẻ, vui lòng đợi');
      }

      _isScanning = true;
      Map<String, dynamic>? rfidData;
      Completer<void> completer = Completer<void>();

      try {
        await NfcManager.instance.startSession(
          pollingOptions: {
            NfcPollingOption.iso14443, // MIFARE, NFC-A/B
            NfcPollingOption.iso15693, // ISO 15693 tags
            NfcPollingOption.iso18092, // FeliCa, NFC-F
          },
          onDiscovered: (NfcTag tag) async {
            rfidData = _parseNFCTag(tag);
            await NfcManager.instance.stopSession();
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );

        // Đợi cho đến khi có tag hoặc timeout
        try {
          await completer.future.timeout(timeout);
        } catch (e) {
          print('Timeout quét NFC hoặc không phát hiện thẻ');
        }
      } catch (e) {
        print('Lỗi trong quá trình quét NFC: $e');
      }

      return rfidData;
    } catch (e) {
      print('Lỗi quét RFID: $e');
      return null;
    } finally {
      _isScanning = false;
    }
  }

  /// Dừng quét NFC
  static Future<void> stopScanning() async {
    try {
      if (_isScanning) {
        await NfcManager.instance.stopSession();
        _isScanning = false;
      }
    } catch (e) {
      print('Lỗi dừng quét: $e');
    }
  }

  /// Parse dữ liệu từ tag NFC
  static Map<String, dynamic> _parseNFCTag(NfcTag tag) {
    String tagId = 'Unknown';
    String tagType = 'Unknown';

    try {
      // Cast tag.data sang Map
      final tagData = tag.data as Map<dynamic, dynamic>;

      // Parse từ NFC-A (MIFARE, ISO14443A)
      if (tagData.containsKey('nfca')) {
        final nfcaData = tagData['nfca'] as Map<dynamic, dynamic>?;
        if (nfcaData != null && nfcaData.containsKey('identifier')) {
          final identifier = nfcaData['identifier'] as List<dynamic>?;
          if (identifier != null) {
            tagId = identifier
                .map((byte) => (byte as int).toRadixString(16).padLeft(2, '0'))
                .join(':');
            tagType = 'NFC-A (MIFARE)';
          }
        }
      }
      // Parse từ NFC-B (ISO14443B)
      else if (tagData.containsKey('nfcb')) {
        final nfcbData = tagData['nfcb'] as Map<dynamic, dynamic>?;
        if (nfcbData != null && nfcbData.containsKey('identifier')) {
          final identifier = nfcbData['identifier'] as List<dynamic>?;
          if (identifier != null) {
            tagId = identifier
                .map((byte) => (byte as int).toRadixString(16).padLeft(2, '0'))
                .join(':');
            tagType = 'NFC-B (ISO14443B)';
          }
        }
      }
      // Parse từ NFC-F (FeliCa, ISO18092)
      else if (tagData.containsKey('nfcf')) {
        final nfcfData = tagData['nfcf'] as Map<dynamic, dynamic>?;
        if (nfcfData != null && nfcfData.containsKey('identifier')) {
          final identifier = nfcfData['identifier'] as List<dynamic>?;
          if (identifier != null) {
            tagId = identifier
                .map((byte) => (byte as int).toRadixString(16).padLeft(2, '0'))
                .join(':');
            tagType = 'NFC-F (FeliCa)';
          }
        }
      }
      // Parse từ ISO-Dep
      else if (tagData.containsKey('isodep')) {
        final isodepData = tagData['isodep'] as Map<dynamic, dynamic>?;
        if (isodepData != null && isodepData.containsKey('identifier')) {
          final identifier = isodepData['identifier'] as List<dynamic>?;
          if (identifier != null) {
            tagId = identifier
                .map((byte) => (byte as int).toRadixString(16).padLeft(2, '0'))
                .join(':');
            tagType = 'ISO-Dep';
          }
        }
      }
      // Parse từ Mifare Classic
      else if (tagData.containsKey('mifareClassic')) {
        final mifareData = tagData['mifareClassic'] as Map<dynamic, dynamic>?;
        if (mifareData != null && mifareData.containsKey('identifier')) {
          final identifier = mifareData['identifier'] as List<dynamic>?;
          if (identifier != null) {
            tagId = identifier
                .map((byte) => (byte as int).toRadixString(16).padLeft(2, '0'))
                .join(':');
            tagType = 'Mifare Classic';
          }
        }
      }
      // Parse từ Mifare UltraLight
      else if (tagData.containsKey('mifareUltralight')) {
        final mifareData =
        tagData['mifareUltralight'] as Map<dynamic, dynamic>?;
        if (mifareData != null && mifareData.containsKey('identifier')) {
          final identifier = mifareData['identifier'] as List<dynamic>?;
          if (identifier != null) {
            tagId = identifier
                .map((byte) => (byte as int).toRadixString(16).padLeft(2, '0'))
                .join(':');
            tagType = 'Mifare UltraLight';
          }
        }
      }
    } catch (e) {
      print('Lỗi parse tag: $e');
    }

    return {
      'tagId': tagId,
      'type': tagType,
      'data': tag.data,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Xác minh thẻ RFID với dữ liệu trong database
  static bool verifyUniformBadge(
      String scannedTagId,
      String expectedTagId,
      ) {
    return scannedTagId.toLowerCase() == expectedTagId.toLowerCase();
  }

  /// Lấy thông tin nhân viên từ ID thẻ
  static Future<Map<String, dynamic>?> getEmployeeFromRFIDTag(
      String tagId,
      List<Map<String, dynamic>> employees,
      ) async {
    try {
      final employee = employees.firstWhere(
            (emp) =>
        emp['rfid_tag_id'].toString().toLowerCase() == tagId.toLowerCase(),
        orElse: () => {},
      );
      return employee.isNotEmpty ? employee : null;
    } catch (e) {
      print('Lỗi tìm kiếm nhân viên từ RFID: $e');
      return null;
    }
  }

  /// Ghi lại chấm công qua RFID
  static Map<String, dynamic> recordRFIDAttendance(
      String employeeId,
      String tagId,
      String uniformStatus,
      ) {
    return {
      'employee_id': employeeId,
      'rfid_tag_id': tagId,
      'uniform_status': uniformStatus, // 'correct', 'incorrect', 'damaged'
      'attendance_time': DateTime.now().toIso8601String(),
      'method': 'RFID',
    };
  }
}
