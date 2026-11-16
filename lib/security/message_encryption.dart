import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class MessageEncryption {
  static final AesGcm _algorithm = AesGcm.with256bits();

  static Future<Map<String, String>> encrypt({
    required String message,
    required Uint8List sharedKey,
  }) async {
    if (sharedKey.length != 32) {
      throw ArgumentError('AES-256 key must be exactly 32 bytes.');
    }

    final secretBox = await _algorithm.encrypt(
      utf8.encode(message),
      secretKey: SecretKey(sharedKey),
    );

    return {
      'cipherText': base64UrlEncode(secretBox.cipherText),
      'nonce': base64UrlEncode(secretBox.nonce),
      'mac': base64UrlEncode(secretBox.mac.bytes),
    };
  }

  static Future<String> decrypt({
    required Map<String, String> encryptedData,
    required Uint8List sharedKey,
  }) async {
    if (sharedKey.length != 32) {
      throw ArgumentError('AES-256 key must be exactly 32 bytes.');
    }

    final secretBox = SecretBox(
      base64Url.decode(encryptedData['cipherText']!),
      nonce: base64Url.decode(encryptedData['nonce']!),
      mac: Mac(base64Url.decode(encryptedData['mac']!)),
    );

    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: SecretKey(sharedKey),
    );

    return utf8.decode(clearBytes);
  }
}
