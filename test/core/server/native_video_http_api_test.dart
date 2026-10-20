import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixora/core/server/local_web_server.dart';
import 'package:pixora/core/server/native_video_engine.dart';
import 'package:pixora/core/server/native_video_http_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'validates native video options and keeps paths as separate arguments',
    () {
      final options = NativeVideoOptions.fromJson({
        'outputFormat': 'mp4',
        'quality': 70,
        'keepAudio': true,
        'stripMetadata': true,
        'maxWidth': 1280,
      });
      final args = buildNativeVideoArgs(
        r'C:\Temp\my input.mp4',
        r'C:\Temp\my output.mp4',
        options,
      );
      expect(args, contains(r'C:\Temp\my input.mp4'));
      expect(args, contains(r'C:\Temp\my output.mp4'));
      expect(args, contains('libx264'));
      expect(args.join(' '), contains('min(1280,iw)'));
      expect(
        () => NativeVideoOptions.fromJson({
          'outputFormat': 'mp4',
          'quality': 70,
          'keepAudio': true,
          'stripMetadata': true,
          'maxWidth': -4,
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'streams a local video to the native engine and returns its result',
    () async {
      final server = await LocalWebServer.start(
        0,
        videoApi: NativeVideoHttpApi(engine: _FakeNativeVideoEngine()),
      );
      try {
        final capability = await _request(
          'GET',
          server.appUri.resolve('api/video/capabilities'),
        );
        expect(capability.status, HttpStatus.ok);
        expect(jsonDecode(utf8.decode(capability.bytes))['available'], isTrue);

        final converted = await _request(
          'POST',
          server.appUri.resolve('api/video/jobs/test-123/convert'),
          body: [1, 2, 3, 4],
          options: jsonEncode({
            'outputFormat': 'mp4',
            'quality': 70,
            'keepAudio': false,
            'stripMetadata': true,
          }),
        );
        expect(converted.status, HttpStatus.ok);
        expect(converted.bytes, [0, 0, 0, 12, 102, 116, 121, 112]);

        final unauthorized = await _request(
          'GET',
          Uri.parse(
            'http://127.0.0.1:${server.port}/wrong/api/video/capabilities',
          ),
        );
        expect(unauthorized.status, HttpStatus.notFound);
      } finally {
        await server.close();
      }
    },
  );

  test('native FFmpeg converts an MP4 without WebAssembly memory', () async {
    final engine = NativeVideoEngine();
    final executable = await engine.executable;
    if (executable == null) return;
    final directory = await Directory.systemTemp.createTemp(
      'pixora-native-test-',
    );
    try {
      final input = File('${directory.path}${Platform.pathSeparator}input.mp4');
      final output = File(
        '${directory.path}${Platform.pathSeparator}output.mp4',
      );
      final generated = await Process.run(executable, [
        '-hide_banner',
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        'testsrc2=size=128x96:rate=10',
        '-t',
        '1',
        '-c:v',
        'libx264',
        '-pix_fmt',
        'yuv420p',
        '-y',
        input.path,
      ]);
      expect(generated.exitCode, 0, reason: '${generated.stderr}');
      final options = NativeVideoOptions.fromJson({
        'outputFormat': 'mp4',
        'quality': 70,
        'keepAudio': false,
        'stripMetadata': true,
      });
      final progress = <double>[];
      await engine.convert(
        input: input.path,
        output: output.path,
        options: options,
        onProgress: progress.add,
        onProcess: (_) {},
      );
      final bytes = await output.readAsBytes();
      expect(bytes.length, greaterThan(100));
      expect(ascii.decode(bytes.sublist(4, 8)), 'ftyp');
      expect(progress.last, 1);

      final logo = File('${directory.path}${Platform.pathSeparator}logo.png');
      final generatedLogo = await Process.run(executable, [
        '-hide_banner',
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        'color=c=red:s=16x16',
        '-frames:v',
        '1',
        '-y',
        logo.path,
      ]);
      expect(generatedLogo.exitCode, 0, reason: '${generatedLogo.stderr}');
      final watermarked = File(
        '${directory.path}${Platform.pathSeparator}watermarked.mp4',
      );
      final watermarkOptions = NativeVideoOptions.fromJson({
        'outputFormat': 'mp4',
        'quality': 70,
        'keepAudio': false,
        'stripMetadata': true,
        'watermark': {
          'scalePercent': 20,
          'opacity': 75,
          'position': 'southeast',
        },
      });
      await engine.convert(
        input: input.path,
        output: watermarked.path,
        options: watermarkOptions,
        watermark: logo.path,
        onProgress: (_) {},
        onProcess: (_) {},
      );
      expect(await watermarked.length(), greaterThan(100));
    } finally {
      await directory.delete(recursive: true);
    }
  });
}

class _FakeNativeVideoEngine extends NativeVideoEngine {
  @override
  Future<String?> get executable async => 'fake-ffmpeg';

  @override
  Future<void> convert({
    required String input,
    required String output,
    required NativeVideoOptions options,
    String? watermark,
    required void Function(double) onProgress,
    required void Function(Process) onProcess,
  }) async {
    expect(await File(input).readAsBytes(), [1, 2, 3, 4]);
    expect(options.format, 'mp4');
    onProgress(0.5);
    await File(output).writeAsBytes([0, 0, 0, 12, 102, 116, 121, 112]);
    onProgress(1);
  }
}

class _Reply {
  _Reply(this.status, this.bytes);
  final int status;
  final List<int> bytes;
}

Future<_Reply> _request(
  String method,
  Uri uri, {
  List<int>? body,
  String? options,
}) async {
  final socket = await Socket.connect(uri.host, uri.port);
  final headers = StringBuffer()
    ..write('$method ${uri.path} HTTP/1.0\r\n')
    ..write('Host: ${uri.host}:${uri.port}\r\n')
    ..write('Connection: close\r\n');
  if (options != null) headers.write('X-Pixora-Options: $options\r\n');
  if (body != null) {
    headers.write('X-Pixora-Extension: mp4\r\n');
    headers.write('Content-Length: ${body.length}\r\n');
  }
  headers.write('\r\n');
  socket.add(ascii.encode(headers.toString()));
  if (body != null) socket.add(body);
  await socket.flush();
  final collected = await socket.fold<BytesBuilder>(BytesBuilder(), (
    buffer,
    chunk,
  ) {
    buffer.add(chunk);
    return buffer;
  });
  final raw = collected.takeBytes();
  final separator = ascii.encode('\r\n\r\n');
  var bodyStart = -1;
  for (var index = 0; index <= raw.length - separator.length; index++) {
    if (raw[index] == separator[0] &&
        raw[index + 1] == separator[1] &&
        raw[index + 2] == separator[2] &&
        raw[index + 3] == separator[3]) {
      bodyStart = index + 4;
      break;
    }
  }
  if (bodyStart < 0) throw StateError('Missing HTTP response separator.');
  final statusLine = ascii.decode(raw.sublist(0, raw.indexOf(13)));
  final status = int.parse(statusLine.split(' ')[1]);
  return _Reply(status, raw.sublist(bodyStart));
}
