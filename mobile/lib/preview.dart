import 'language.dart';
import 'package:flutter/material.dart';
import 'screens/home/lock_screen_setup.dart';
import 'screens/home/focus_mode_screen.dart';

void main() => launchLocalizedApp(const PreviewApp());

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FocusLock Preview',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
    ),
    home: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('FocusLock · Preview', 'FocusLock · 미리보기')),
          actions: const [LanguageSelector()],
          bottom: TabBar(tabs: [
            Tab(icon: Icon(Icons.lock), text: context.tr('Lock Screen', '잠금 화면')),
            Tab(icon: Icon(Icons.timer), text: context.tr('Focus Mode', '집중 모드')),
          ]),
        ),
        body: const TabBarView(children: [LockScreenSetup(), FocusModeScreen()]),
      ),
    ),
  );
}
