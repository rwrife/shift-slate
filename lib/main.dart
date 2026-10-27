import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';

void main() => runApp(const ShiftSlateApp());

/// First-run shell only; event editing and persistence arrive in later issues.
class ShiftSlateApp extends StatelessWidget {
  const ShiftSlateApp({super.key, this.platform});

  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final target = platform ?? defaultTargetPlatform;
    switch (target) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return cupertino.CupertinoApp(
          title: 'Shift Slate',
          home: cupertino.CupertinoPageScaffold(
            navigationBar: const cupertino.CupertinoNavigationBar(
              middle: cupertino.Text('Shift Slate'),
            ),
            child: cupertino.SafeArea(child: _welcome(target)),
          ),
        );
      case TargetPlatform.windows:
        return fluent.FluentApp(
          title: 'Shift Slate',
          home: fluent.NavigationView(
            content: fluent.ScaffoldPage(
              header: const fluent.PageHeader(
                title: fluent.Text('Shift Slate'),
              ),
              content: _welcome(target),
            ),
          ),
        );
      case TargetPlatform.android:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return material.MaterialApp(
          title: 'Shift Slate',
          theme: material.ThemeData(useMaterial3: true),
          home: material.Scaffold(
            appBar: material.AppBar(title: const material.Text('Shift Slate')),
            body: _welcome(target),
          ),
        );
    }
  }

  Widget _welcome(TargetPlatform target) {
    final message =
        'Plan volunteer shifts offline. Event setup is coming soon.';
    final text = switch (target) {
      TargetPlatform.windows => fluent.Text(message),
      TargetPlatform.iOS || TargetPlatform.macOS => cupertino.Text(message),
      _ => material.Text(message),
    };
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: text),
    );
  }
}
