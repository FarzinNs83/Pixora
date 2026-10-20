import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import '../../../../app/desktop_tray.dart';
import '../../../../app/theme/app_theme.dart';

class PixoraTitleBar extends StatelessWidget {
  const PixoraTitleBar({super.key, required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF1D1D21) : const Color(0xFFFFFFFF);
    final foreground = dark ? const Color(0xFFEDEDF2) : const Color(0xFF35353D);
    final hover = dark ? const Color(0xFF303036) : const Color(0xFFF0F0F3);
    final pressed = dark ? const Color(0xFF3A3A42) : const Color(0xFFE2E2E8);
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Container(
        key: const ValueKey('pixora-test-titlebar'),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            bottom: BorderSide(
              color: dark ? const Color(0xFF35353C) : const Color(0xFFE5E5EC),
            ),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: _TitleBarBrand(foreground: foreground),
      );
    }
    final buttonColors = WindowButtonColors(
      normal: background,
      mouseOver: hover,
      mouseDown: pressed,
      iconNormal: foreground,
      iconMouseOver: foreground,
      iconMouseDown: foreground,
    );
    final closeColors = WindowButtonColors(
      normal: background,
      mouseOver: const Color(0xFFC42B3A),
      mouseDown: const Color(0xFFA91F2D),
      iconNormal: foreground,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    return Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              bottom: BorderSide(
                color: dark ? const Color(0xFF35353C) : const Color(0xFFE5E5EC),
              ),
            ),
          ),
          child: WindowTitleBarBox(
            child: Row(
              children: [
                Expanded(
                  child: MoveWindow(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _TitleBarBrand(foreground: foreground),
                    ),
                  ),
                ),
                MinimizeWindowButton(colors: buttonColors, animate: true),
                MaximizeWindowButton(colors: buttonColors, animate: true),
                CloseWindowButton(
                  colors: closeColors,
                  animate: true,
                  onPressed: DesktopTray.instance.hideToTray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBarBrand extends StatelessWidget {
  const _TitleBarBrand({required this.foreground});

  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.asset(
            'website/dist/pixora-mark-32.png',
            key: const ValueKey('pixora-titlebar-logo'),
            width: 18,
            height: 18,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(
              Icons.auto_awesome_rounded,
              size: 17,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Pixora',
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
