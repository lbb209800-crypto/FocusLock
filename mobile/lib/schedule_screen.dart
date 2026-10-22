import 'dart:async';
import 'package:flutter/material.dart';
import 'language.dart';
import 'schedule.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.now});
  final DateTime Function()? now;
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  DateTime get _now => widget.now?.call() ?? DateTime.now();
  final _title = TextEditingController();
  final _store = ScheduleStore();
  List<FocusSchedule> _items = [];
  Map<String, dynamic> _permissions = {};
  late final Timer _timer;
  DateTime _date = DateTime.now();
  TimeOfDay _time =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 1)));
  static const _minutes = 10;
  bool _loading = true;
  bool _saving = false;
  DateTime? _demoEnd;
  String _demoTitle = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    try {
      final items = await _store.load();
      final permissions = await PhoneLock.permissions();
      if (mounted) {
        setState(() {
          _items = items;
          _permissions = permissions;
        });
      }
    } catch (_) {
      if (mounted) {
        _message(context.tr('Could not load schedules.', '저장된 일정을 불러오지 못했어요.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    try {
      final permissions = await PhoneLock.permissions();
      if (mounted) setState(() => _permissions = permissions);
    } catch (_) {
      if (mounted) {
        _message(
            context.tr('Could not check permissions.', '권한 상태를 확인하지 못했어요.'));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _title.dispose();
    super.dispose();
  }

  void _message(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
  String _clock(DateTime date) => TimeOfDay.fromDateTime(date).format(context);
  String _day(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  Future<void> _add({bool test = false}) async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _message(context.tr('Enter a schedule title.', '일정 제목을 입력해주세요.'));
      return;
    }
    final now = _now;
    final at = test
        ? now.add(const Duration(seconds: 15))
        : DateTime(
            _date.year, _date.month, _date.day, _time.hour, _time.minute);
    if (!at.isAfter(now)) {
      _message(context.tr(
          'Choose a future date and time.', '현재보다 이후의 날짜와 시간을 선택해주세요.'));
      return;
    }
    if (_items.any((item) =>
        at.isBefore(item.endsAt) &&
        item.at.isBefore(at.add(const Duration(minutes: _minutes))))) {
      _message(context.tr(
          'This lock overlaps another schedule.', '다른 일정의 잠금 시간과 겹쳐요.'));
      return;
    }
    final item = FocusSchedule(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        at: at,
        minutes: _minutes);
    final language = LanguageScope.of(context).code;
    setState(() => _saving = true);
    try {
      if (PhoneLock.supported) {
        final permissions = await PhoneLock.permissions();
        if (!mounted) return;
        setState(() => _permissions = permissions);
        if (!PhoneLock.ready(permissions)) {
          _message(context.tr('Allow all lock permissions before registering.',
              '일정 등록 전에 잠금에 필요한 권한을 모두 허용해주세요.'));
          return;
        }
      }
      await PhoneLock.schedule(item, language);
      final next = [..._items, item]..sort((a, b) => a.at.compareTo(b.at));
      try {
        await _store.save(next);
      } catch (_) {
        await PhoneLock.cancel(item.id);
        rethrow;
      }
      if (!mounted) return;
      setState(() => _items = next);
      _message(context.tr('Schedule saved.', '일정을 등록했어요.'));
    } catch (_) {
      if (mounted) {
        _message(context.tr(
            'Could not register. Check lock permissions and the FocusLock Do Not Disturb rule.',
            '등록하지 못했어요. 잠금 권한과 FocusLock 방해금지 규칙을 확인해주세요.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(FocusSchedule item) async {
    setState(() => _saving = true);
    try {
      await PhoneLock.cancel(item.id);
      final next = _items.where((entry) => entry.id != item.id).toList();
      await _store.save(next);
      if (mounted) setState(() => _items = next);
    } catch (_) {
      if (mounted) {
        _message(context.tr('Could not remove schedule.', '일정을 삭제하지 못했어요.'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    final active = _items.where((item) => item.activeAt(now)).toList();
    final demo = _demoEnd != null && now.isBefore(_demoEnd!);
    if (!PhoneLock.supported && (active.isNotEmpty || demo)) {
      final item = active.isNotEmpty ? active.first : null;
      final seconds = (item?.endsAt ?? _demoEnd!).difference(now).inSeconds + 1;
      return PopScope(
          canPop: false,
          child: Scaffold(
              body: SafeArea(
                  child: Center(
                      child: Padding(
            padding: const EdgeInsets.all(28),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_rounded,
                  size: 64, color: Color(0xFFA5B4FC)),
              const SizedBox(height: 28),
              Text(context.tr('Schedule lock', '일정 잠금'),
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              Text(
                  item == null
                      ? context.tr('Preview', '미리보기')
                      : '${_clock(item.at)} ${context.tr('schedule', '일정')}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Text(item?.title ?? _demoTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Text(
                  '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Text(context.tr('Unlocks automatically when time is up.',
                  '시간이 끝나면 자동으로 해제돼요.')),
              const SizedBox(height: 28),
              Text(
                  context.tr(
                      'Browser preview only. Other apps are not blocked.',
                      '브라우저 미리보기예요. 다른 앱 사용은 차단되지 않아요.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54)),
            ]),
          )))));
    }
    return Scaffold(
      appBar: AppBar(
          title: const Text('FocusLock'), actions: const [LanguageSelector()]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(padding: const EdgeInsets.all(24), children: [
                Text(context.tr('Make time for your plans', '정한 시간엔, 하기로 한 일'),
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    context.tr('Your phone pauses when it is time.',
                        '일정을 등록하면 해당 시각에 폰 사용을 잠시 멈춰요.'),
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                if (!PhoneLock.supported)
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(context.tr(
                              'Web preview: keep this tab open. Device-wide blocking requires Android.',
                              '웹 미리보기: 이 탭을 열어두세요. 다른 앱까지 차단하려면 Android 앱이 필요해요.')))),
                if (PhoneLock.supported) ...[
                  Text(
                      PhoneLock.ready(_permissions)
                          ? context.tr('Lock permissions ready', '잠금 권한 준비 완료')
                          : context.tr('Lock setup required', '잠금 권한 설정이 필요해요'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(context.tr(
                      'Calls remain available. During calls the lock screen is hidden; the original end time stays the same.',
                      '전화가 오면 잠금 화면을 숨겨요. 통화 후에도 원래 잠금 종료 시각은 유지돼요.')),
                  if (_permissions['dndSupported'] == false)
                    Text(context.tr(
                        'Notification restriction requires Android 10 or later.',
                        '알림 제한이 포함된 예약 잠금은 Android 10 이상에서 사용할 수 있어요.')),
                  _permissionTile('overlay',
                      context.tr('Display over other apps', '다른 앱 위에 표시')),
                  _permissionTile(
                      'exact', context.tr('Alarms & reminders', '알람 및 리마인더')),
                  _permissionTile(
                      'notifications', context.tr('Notifications', '알림')),
                  _permissionTile(
                      'phone',
                      context.tr('Phone state for call exceptions',
                          '전화 예외를 위한 통화 상태')),
                  _permissionTile(
                      'dnd',
                      context.tr(
                          'Do Not Disturb access', '일반 알림 제한을 위한 방해금지 접근')),
                  _permissionTile(
                      'accessibility',
                      context.tr(
                          'App blocking (Accessibility)', '앱 이동 제한 (접근성)')),
                ],
                const SizedBox(height: 20),
                TextField(
                    controller: _title,
                    maxLength: 100,
                    decoration: InputDecoration(
                        labelText: context.tr('Schedule title', '일정 제목'),
                        hintText: context.tr(
                            'Start the assignment from work', '회사에서 받은 작업 시작'),
                        border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_day(_date)),
                      onPressed: () async {
                        final date = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: now.add(const Duration(days: 365)));
                        if (date != null && mounted) {
                          setState(() => _date = date);
                        }
                      }),
                  OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(_time.format(context)),
                      onPressed: () async {
                        final time = await showTimePicker(
                            context: context, initialTime: _time);
                        if (time != null && mounted) {
                          setState(() => _time = time);
                        }
                      }),
                ]),
                const SizedBox(height: 20),
                Text(context.tr('Lock duration', '잠금 시간')),
                const SizedBox(height: 8),
                Text(context.tr('10 minutes', '10분'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                FilledButton.icon(
                    onPressed: _saving ? null : () => _add(),
                    icon: const Icon(Icons.add_alarm),
                    label: Text(context.tr('Register schedule', '일정 등록'))),
                OutlinedButton(
                    onPressed: _saving ? null : () => _add(test: true),
                    child: Text(context.tr(
                        'Test: start in 15 seconds', '테스트: 15초 뒤 일정 시작'))),
                if (!PhoneLock.supported)
                  TextButton(
                      onPressed: () => setState(() {
                            _demoTitle = _title.text.trim().isEmpty
                                ? context.tr('Start the assignment from work',
                                    '회사에서 받은 작업 시작')
                                : _title.text.trim();
                            _demoEnd =
                                DateTime.now().add(const Duration(seconds: 15));
                          }),
                      child: Text(context.tr(
                          'Preview lock screen for 15 seconds',
                          '잠금 화면만 15초 미리보기'))),
                const SizedBox(height: 28),
                Text(context.tr('Your schedules', '등록한 일정'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  Text(context.tr('No schedules yet.', '아직 등록한 일정이 없어요.')),
                for (final item in _items)
                  Card(
                      child: ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(item.title),
                          subtitle: Text(
                              '${_day(item.at)} · ${_clock(item.at)} · ${item.minutes}${context.tr(' min', '분')}\n${now.isBefore(item.at) ? context.tr('Scheduled', '예약됨') : context.tr('Finished', '종료됨')}'),
                          trailing: IconButton(
                              tooltip: context.tr('Delete', '삭제'),
                              icon: const Icon(Icons.delete_outline),
                              onPressed:
                                  _saving ? null : () => _remove(item)))),
              ]),
            )),
    );
  }

  Widget _permissionTile(String key, String title) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
            _permissions[key] == true
                ? Icons.check_circle
                : Icons.error_outline,
            color:
                _permissions[key] == true ? Colors.greenAccent : Colors.amber),
        title: Text(title),
        trailing: _permissions[key] == true
            ? null
            : TextButton(
                onPressed: () async {
                  if (key == 'accessibility') {
                    final accepted = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                              title:
                                  Text(context.tr('App blocking', '앱 이동 제한')),
                              content: Text(context.tr(
                                  'During a scheduled lock, FocusLock detects app switches and returns to the focus screen. It does not read screen content or typed text. Calls and system settings remain available. You can turn this off in Android Accessibility Settings.',
                                  '예약 잠금 중 앱 전환을 감지해 집중 화면으로 돌아옵니다. 화면 내용이나 입력한 글자는 읽지 않습니다. 전화와 시스템 설정은 사용할 수 있으며 Android 접근성 설정에서 언제든 해제할 수 있어요.')),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: Text(context.tr('Cancel', '취소'))),
                                FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: Text(
                                        context.tr('Open settings', '설정 열기'))),
                              ],
                            ));
                    if (accepted != true || !mounted) return;
                  }
                  try {
                    await PhoneLock.request(key);
                    await _refreshPermissions();
                  } catch (_) {
                    if (mounted) {
                      _message(context.tr('Could not open permission settings.',
                          '권한 설정을 열지 못했어요.'));
                    }
                  }
                },
                child: Text(context.tr('Allow', '허용'))),
      );
}
