import 'package:flutter/material.dart';
import 'language.dart';
import 'schedule_screen.dart';

void main() => launchLocalizedApp(const FocusApp());

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FocusLock',
        theme: ThemeData.dark(useMaterial3: true)
            .copyWith(scaffoldBackgroundColor: const Color(0xFF0F172A)),
        home: const ScheduleScreen(),
      );
}
