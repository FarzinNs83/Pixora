import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixora/features/desktop_shell/application/desktop_shell_cubit.dart';
import 'package:pixora/features/desktop_shell/presentation/desktop_shell_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the port form with an example on first launch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(home: DesktopShellPage(preferences: preferences)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose a local port'), findsOneWidget);
    expect(
      find.text('Example: 47832 (allowed range: 1024-65535)'),
      findsOneWidget,
    );
    expect(find.text('Check port and open Pixora'), findsOneWidget);
    expect(find.text('Suggest an available port'), findsOneWidget);
  });

  testWidgets('asks for a replacement when the saved port is occupied', (
    tester,
  ) async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(socket.close);
    SharedPreferences.setMockInitialValues({
      DesktopShellCubit.portPreferenceKey: socket.port,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MaterialApp(home: DesktopShellPage(preferences: preferences)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your saved port is unavailable. Choose another port.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, socket.port.toString()),
      findsOneWidget,
    );
  });

  testWidgets('validates the supported port range inline', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MaterialApp(home: DesktopShellPage(preferences: preferences)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '80');
    await tester.tap(find.text('Check port and open Pixora'));
    await tester.pump();

    expect(find.text('Enter a number from 1024 to 65535.'), findsOneWidget);
  });
}
