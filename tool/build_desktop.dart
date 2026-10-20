import 'dart:io';

Future<void> main(List<String> arguments) async {
  final target = arguments.isEmpty ? _currentTarget() : arguments.first;
  if (!{'windows', 'linux', 'macos'}.contains(target)) {
    stderr.writeln(
      'Usage: dart run tool/build_desktop.dart [windows|linux|macos]',
    );
    exitCode = 64;
    return;
  }
  if (!_canBuildHere(target)) {
    stderr.writeln('$target builds must run on $target.');
    exitCode = 65;
    return;
  }

  await _verifyPlatformDependencies(target);
  await _run(Platform.isWindows ? 'npm.cmd' : 'npm', [
    'ci',
  ], workingDirectory: 'website');
  await _run(Platform.isWindows ? 'npm.cmd' : 'npm', [
    'run',
    'build',
  ], workingDirectory: 'website');
  _verifyWebBundle();
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  await _run(flutter, ['pub', 'get']);
  await _run(flutter, ['build', target, '--release']);
}

void _verifyWebBundle() {
  final index = File('website/dist/index.html');
  final model = File('website/dist/ai/u2netp.onnx');
  final assets = Directory('website/dist/assets');
  final wasmNames = assets.existsSync()
      ? assets
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .where((name) => name.endsWith('.wasm'))
            .toSet()
      : <String>{};
  final hasImageMagick = wasmNames.any((name) => name.startsWith('magick-'));
  final hasFfmpeg = wasmNames.any((name) => name.startsWith('ffmpeg-core-'));
  final hasResvg = wasmNames.any((name) => name.startsWith('index_bg-'));
  if (!index.existsSync() ||
      !model.existsSync() ||
      !hasImageMagick ||
      !hasFfmpeg ||
      !hasResvg) {
    stderr.writeln(
      'The web build is incomplete: expected index.html, U2NetP and the ImageMagick/FFmpeg/resvg WASM files.',
    );
    exit(66);
  }
}

String _currentTarget() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  if (Platform.isMacOS) return 'macos';
  return '';
}

bool _canBuildHere(String target) =>
    (target == 'windows' && Platform.isWindows) ||
    (target == 'linux' && Platform.isLinux) ||
    (target == 'macos' && Platform.isMacOS);

Future<void> _verifyPlatformDependencies(String target) async {
  if (target == 'linux') {
    final webkit = await Process.run('pkg-config', [
      '--exists',
      'webkit2gtk-4.1',
    ]);
    final soup = await Process.run('pkg-config', ['--exists', 'libsoup-3.0']);
    if (webkit.exitCode != 0 || soup.exitCode != 0) {
      stderr.writeln(
        'Linux build dependencies are missing. Install WebKitGTK 4.1, libsoup 3 and their development packages.',
      );
      exit(69);
    }
  }
  if (target == 'macos') {
    final pods = await Process.run('pod', ['--version']);
    if (pods.exitCode != 0) {
      stderr.writeln('CocoaPods is required for the macOS build.');
      exit(69);
    }
  }
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  stdout.writeln('> $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    mode: ProcessStartMode.inheritStdio,
  );
  final result = await process.exitCode;
  if (result != 0) exit(result);
}
