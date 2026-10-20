import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:system_tray/system_tray.dart' as tray;
import 'package:window_manager/window_manager.dart';

/// Keeps Pixora alive in the Windows notification area when its window is
/// closed. Only Windows hosts the UI inside the Flutter window, so the tray is
/// not used on macOS or Linux.
class DesktopTray with WindowListener {
  DesktopTray._();

  static final DesktopTray instance = DesktopTray._();

  final tray.SystemTray _tray = tray.SystemTray();
  bool _enabled = false;

  static bool get isSupported =>
      Platform.isWindows && !Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> initialize() async {
    if (!isSupported || _enabled) return;
    await _tray.initSystemTray(
      iconPath: 'assets/tray/app_icon.ico',
      toolTip: 'Pixora',
    );
    final menu = tray.Menu();
    await menu.buildFrom([
      tray.MenuItemLabel(label: 'Open Pixora', onClicked: (_) => show()),
      tray.MenuSeparator(),
      tray.MenuItemLabel(label: 'Quit', onClicked: (_) => unawaited(quit())),
    ]);
    await _tray.setContextMenu(menu);
    _tray.registerSystemTrayEventHandler((event) {
      if (event == tray.kSystemTrayEventClick ||
          event == tray.kSystemTrayEventDoubleClick) {
        show();
      } else if (event == tray.kSystemTrayEventRightClick) {
        unawaited(_tray.popUpContextMenu());
      }
    });
    // Alt+F4 and the taskbar "Close window" also hide instead of quitting.
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    _enabled = true;
  }

  /// Hides the window to the tray, or closes it when the tray is unavailable.
  void hideToTray() {
    if (_enabled) {
      appWindow.hide();
    } else {
      appWindow.close();
    }
  }

  void show() {
    appWindow
      ..show()
      ..restore();
  }

  Future<void> quit() async {
    windowManager.removeListener(this);
    await _tray.destroy();
    exit(0);
  }

  @override
  void onWindowClose() => hideToTray();
}
