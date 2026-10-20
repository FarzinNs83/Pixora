import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixora/core/server/port_service.dart';

void main() {
  const service = PortService();

  group('PortService', () {
    test('accepts user ports in the supported range', () {
      expect(service.validateValue(1024).isValid, isTrue);
      expect(service.validateValue(47832).isValid, isTrue);
      expect(service.validateValue(65535).isValid, isTrue);
    });

    test('rejects invalid and reserved ports', () {
      expect(
        service.validateValue(null).failure,
        PortValidationFailure.invalid,
      );
      expect(service.validateValue(0).failure, PortValidationFailure.invalid);
      expect(service.validateValue(80).failure, PortValidationFailure.reserved);
      expect(
        service.validateValue(65536).failure,
        PortValidationFailure.invalid,
      );
    });

    test('detects an occupied loopback port', () async {
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(socket.close);
      expect(await service.isAvailable(socket.port), isFalse);
    });

    test('suggests a valid available port', () async {
      final port = await service.suggestAvailable();
      expect(service.validateValue(port).isValid, isTrue);
      expect(await service.isAvailable(port), isTrue);
    });
  });
}
