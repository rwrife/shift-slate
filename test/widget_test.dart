import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_slate/main.dart';

void main() {
  testWidgets('renders Android Material 3 shell', (tester) async {
    await tester.pumpWidget(
      const ShiftSlateApp(platform: TargetPlatform.android),
    );
    await tester.pumpAndSettle();

    expect(find.byType(material.MaterialApp), findsOneWidget);
    expect(find.byType(material.Scaffold), findsOneWidget);
    expect(find.text('Shift Slate'), findsOneWidget);
    expect(
      find.text('Plan volunteer shifts offline. Event setup is coming soon.'),
      findsOneWidget,
    );
  });

  testWidgets('renders iOS Cupertino shell', (tester) async {
    await tester.pumpWidget(const ShiftSlateApp(platform: TargetPlatform.iOS));
    await tester.pumpAndSettle();

    expect(find.byType(cupertino.CupertinoApp), findsOneWidget);
    expect(find.byType(cupertino.CupertinoPageScaffold), findsOneWidget);
    expect(find.text('Shift Slate'), findsOneWidget);
  });

  testWidgets('renders Windows Fluent shell', (tester) async {
    await tester.pumpWidget(
      const ShiftSlateApp(platform: TargetPlatform.windows),
    );
    await tester.pumpAndSettle();

    expect(find.byType(fluent.FluentApp), findsOneWidget);
    expect(find.byType(fluent.NavigationView), findsOneWidget);
    expect(find.text('Shift Slate'), findsOneWidget);
  });
}
