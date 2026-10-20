import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app/desktop_tray.dart';
import 'app/pixora_app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (runWebViewTitleBarWidget(args)) return;
  final preferences = await SharedPreferences.getInstance();

  if (!Platform.isWindows && (Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      minimumSize: Size(560, 520),
      size: Size(1280, 820),
      center: true,
      title: 'Pixora',
    );
    await windowManager.waitUntilReadyToShow(options, windowManager.show);
  }

  runApp(PixoraApp(preferences: preferences));

  if (Platform.isWindows) {
    doWhenWindowReady(() {
      const initialSize = Size(1280, 820);
      appWindow
        ..minSize = const Size(560, 520)
        ..size = initialSize
        ..alignment = Alignment.center
        ..title = 'Pixora'
        ..show();
      unawaited(DesktopTray.instance.initialize());
    });
  }
}
