import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Uint8List> getOrCreateTestKey(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty.');
    }

    final keyName = 'mr_chatwave_local_test_key_v1_$userId';

    final existingKey = await _storage.read(key: keyName);

    if (existingKey != null) {
      final decoded = base64Url.decode(existingKey);

      if (decoded.length != 32) {
        throw StateError('Stored test key has invalid length.');
      }

      return Uint8List.fromList(decoded);
    }

    final random = Random.secure();

    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );

    await _storage.write(key: keyName, value: base64UrlEncode(key));

    return key;
  }
}
