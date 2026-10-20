import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixora/app/pixora_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> emptyPreferences() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  testWidgets('opens the first-run port form with a concrete example', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PixoraApp(preferences: await emptyPreferences()));
    await tester.pumpAndSettle();

    expect(find.text('Choose a local port'), findsOneWidget);
    expect(
      find.text('Example: 47832 (allowed range: 1024-65535)'),
      findsOneWidget,
    );
    expect(find.text('Check port and open Pixora'), findsOneWidget);
    expect(find.byKey(const ValueKey('pixora-titlebar-logo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('defaults to the dark surface for the custom title bar', (
    tester,
  ) async {
    await tester.pumpWidget(PixoraApp(preferences: await emptyPreferences()));
    await tester.pumpAndSettle();

    final titleBar = tester.widget<Container>(
      find.byKey(const ValueKey('pixora-test-titlebar')),
    );
    final decoration = titleBar.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFF1D1D21));
  });

  testWidgets('keeps the port screen usable at the minimum window size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(560, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PixoraApp(preferences: await emptyPreferences()));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Suggest an available port'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the startup flow in Persian RTL', (tester) async {
    await tester.pumpWidget(
      PixoraApp(
        preferences: await emptyPreferences(),
        locale: const Locale('fa'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('یک پورت محلی انتخاب کنید'), findsOneWidget);
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });
}
