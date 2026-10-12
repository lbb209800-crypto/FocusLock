import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslock/focus_app.dart';
import 'package:focuslock/language.dart';
import 'package:focuslock/schedule.dart';
import 'package:focuslock/schedule_screen.dart';

void main() {
  test('schedule activates at its start and expires at original deadline', () {
    final start = DateTime(2026, 10, 13, 20);
    final item = FocusSchedule(id: '1', title: 'Work', at: start, minutes: 5);
    expect(item.activeAt(start.subtract(const Duration(milliseconds: 1))),
        isFalse);
    expect(item.activeAt(start), isTrue);
    expect(item.activeAt(start.add(const Duration(minutes: 4))), isTrue);
    expect(item.activeAt(start.add(const Duration(minutes: 5))), isFalse);
    expect(FocusSchedule.fromJson(item.toJson()).at, start);
  });

  test('schedules survive reload and deletion', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ScheduleStore();
    final item = FocusSchedule(
        id: '2',
        title: '회사에서 받은 작업 시작',
        at: DateTime(2026, 10, 13, 20),
        minutes: 10);
    await store.save([item]);
    expect((await store.load()).single.title, item.title);
    await store.save([]);
    expect(await store.load(), isEmpty);
  });

  testWidgets(
      'register timed lock, preview title, switch language',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final language = AppLanguage(prefs);
    await tester
        .pumpWidget(LanguageScope(language: language, child: const FocusApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('일정 제목'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '회사에서 받은 작업 시작');
    final testButton = find.text('테스트: 15초 뒤 일정 시작');
    await tester.ensureVisible(testButton);
    await tester.tap(testButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect((await ScheduleStore().load()).single.title, '회사에서 받은 작업 시작');
    // Short preview can be exercised without waiting for the production lock.
    final preview = find.text('잠금 화면만 15초 미리보기');
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await tester.pump();
    expect(find.text('일정 잠금'), findsOneWidget);
    expect(find.text('회사에서 받은 작업 시작'), findsOneWidget);
    expect(find.text('일정 등록'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    language.select('en');
    expect(prefs.getString('language'), 'en');
    await tester
        .pumpWidget(LanguageScope(language: language, child: const FocusApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Schedule title'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('automatic schedule lock ends at the deadline after reload', (tester) async {
    final start = DateTime(2026, 10, 13, 20);
    var now = start.subtract(const Duration(seconds: 1));
    SharedPreferences.setMockInitialValues({});
    await ScheduleStore().save([FocusSchedule(id: 'timed', title: 'Company task', at: start, minutes: 5)]);
    final language = AppLanguage(await SharedPreferences.getInstance());
    Widget app() => LanguageScope(language: language, child: MaterialApp(home: ScheduleScreen(now: () => now)));
    await tester.pumpWidget(app());
    await tester.pump(); await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('일정 잠금'), findsNothing);
    now = start;
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('일정 잠금'), findsOneWidget);
    expect(find.text('Company task'), findsOneWidget);
    now = start.add(const Duration(minutes: 4));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pump(); await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('일정 잠금'), findsOneWidget);
    now = start.add(const Duration(minutes: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('일정 잠금'), findsNothing);
    expect(find.text('일정 등록'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
