import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixora/core/server/local_web_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalWebServer', () {
    late LocalWebServer server;

    setUp(() async {
      server = await LocalWebServer.start(0);
    });

    tearDown(() => server.close());

    test('binds only to loopback and exposes a health endpoint', () async {
      final response = await _rawGet(server.healthUri);

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, '{"status":"ready"}');
      expect(server.appUri.host, '127.0.0.1');
    });

    test('rejects requests that do not contain the session token', () async {
      final response = await _rawGet(
        Uri.parse('http://127.0.0.1:${server.port}/wrong-token/'),
      );

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('serves the built React app with isolation headers', () async {
      final response = await _rawGet(server.appUri);

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers['cross-origin-opener-policy'], 'same-origin');
      expect(response.headers['cross-origin-embedder-policy'], 'require-corp');
      expect(response.body, contains('<div id="root"></div>'));
    });

    test('serves the home artwork as a local image', () async {
      final response = await _rawRequest(
        server.appUri.resolve('home-media.png'),
        method: 'HEAD',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers['content-type'], 'image/png');
    });

    test('serves the updated converter bundle, not the old Add files UI', () async {
      final index = File('website/dist/index.html').readAsStringSync();
      final bundleName = RegExp(r'assets/(index-[\w-]+\.js)').firstMatch(index);
      expect(bundleName, isNotNull);
      final response = await _rawGet(server.appUri.resolve(bundleName!.group(0)!));

      expect(response.statusCode, HttpStatus.ok);
      expect(response.body, contains('pixora-videos.zip'));
      expect(response.body, contains('pixora-backgrounds.zip'));
      expect(response.body, isNot(contains('Add files')));
    });

    test(
      'serves nested WASM and local AI assets with correct MIME types',
      () async {
        final assetDirectory = Directory('website/dist/assets');
        final wasmFiles = assetDirectory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.wasm'))
            .toList();
        final wasmNames = wasmFiles
            .map((file) => file.uri.pathSegments.last)
            .toList();
        expect(wasmNames.any((name) => name.startsWith('magick-')), isTrue);
        expect(
          wasmNames.any((name) => name.startsWith('ffmpeg-core-')),
          isTrue,
        );
        expect(wasmNames.any((name) => name.startsWith('index_bg-')), isTrue);
        for (final wasm in wasmFiles) {
          final response = await _rawRequest(
            server.appUri.resolve('assets/${wasm.uri.pathSegments.last}'),
            method: 'HEAD',
          );
          expect(response.statusCode, HttpStatus.ok);
          expect(response.headers['content-type'], 'application/wasm');
        }
        final modelResponse = await _rawRequest(
          server.appUri.resolve('ai/u2netp.onnx'),
          method: 'HEAD',
        );
        final ortResponse = await _rawRequest(
          server.appUri.resolve('ai/ort-wasm-simd-threaded.wasm'),
          method: 'HEAD',
        );

        expect(modelResponse.statusCode, HttpStatus.ok);
        expect(
          modelResponse.headers['content-type'],
          'application/octet-stream',
        );
        expect(ortResponse.statusCode, HttpStatus.ok);
        expect(ortResponse.headers['content-type'], 'application/wasm');
      },
    );
  });
}

class _RawResponse {
  const _RawResponse(this.statusCode, this.headers, this.body);
  final int statusCode;
  final Map<String, String> headers;
  final String body;
}

Future<_RawResponse> _rawGet(Uri uri) async {
  return _rawRequest(uri);
}

Future<_RawResponse> _rawRequest(Uri uri, {String method = 'GET'}) async {
  final socket = await Socket.connect(uri.host, uri.port);
  socket.write(
    '$method ${uri.path} HTTP/1.0\r\nHost: ${uri.host}:${uri.port}\r\nConnection: close\r\n\r\n',
  );
  await socket.flush();
  final raw = await utf8.decoder.bind(socket).join();
  final parts = raw.split('\r\n\r\n');
  final head = parts.first.split('\r\n');
  final statusCode = int.parse(head.first.split(' ')[1]);
  final headers = <String, String>{};
  for (final line in head.skip(1)) {
    final separator = line.indexOf(':');
    if (separator > 0) {
      headers[line.substring(0, separator).toLowerCase()] = line
          .substring(separator + 1)
          .trim();
    }
  }
  return _RawResponse(statusCode, headers, parts.skip(1).join('\r\n\r\n'));
}
