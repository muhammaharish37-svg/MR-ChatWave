import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mr_chatwave/security/message_encryption.dart';

void main() {
  group('MessageEncryption', () {
    final sharedKey = Uint8List.fromList(
      List<int>.generate(32, (index) => index),
    );

    test('encrypts and decrypts a message correctly', () async {
      const originalMessage = 'MR ChatWave secure message test';

      final encrypted = await MessageEncryption.encrypt(
        message: originalMessage,
        sharedKey: sharedKey,
      );

      expect(encrypted['cipherText'], isNot(originalMessage));
      expect(encrypted['nonce'], isNotEmpty);
      expect(encrypted['mac'], isNotEmpty);

      final decrypted = await MessageEncryption.decrypt(
        encryptedData: encrypted,
        sharedKey: sharedKey,
      );

      expect(decrypted, originalMessage);
    });

    test('rejects decryption with an incorrect key', () async {
      final encrypted = await MessageEncryption.encrypt(
        message: 'Private test',
        sharedKey: sharedKey,
      );

      final wrongKey = Uint8List.fromList(
        List<int>.generate(32, (index) => index + 1),
      );

      expect(
        () => MessageEncryption.decrypt(
          encryptedData: encrypted,
          sharedKey: wrongKey,
        ),
        throwsA(anything),
      );
    });
  });
}
