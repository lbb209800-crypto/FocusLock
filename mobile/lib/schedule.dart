import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusSchedule {
  const FocusSchedule(
      {required this.id,
      required this.title,
      required this.at,
      required this.minutes});
  final String id;
  final String title;
  final DateTime at;
  final int minutes;
  DateTime get endsAt => at.add(Duration(minutes: minutes));
  bool activeAt(DateTime now) => !now.isBefore(at) && now.isBefore(endsAt);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'at': at.millisecondsSinceEpoch,
        'minutes': minutes
      };
  factory FocusSchedule.fromJson(Map<String, dynamic> json) => FocusSchedule(
        id: json['id'] as String,
        title: json['title'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
        minutes: json['minutes'] as int,
      );
}

class ScheduleStore {
  Future<List<FocusSchedule>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('focus_schedules_v1');
    return raw == null
        ? []
        : (jsonDecode(raw) as List)
            .map((item) =>
                FocusSchedule.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
  }

  Future<void> save(List<FocusSchedule> items) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('focus_schedules_v1',
        jsonEncode(items.map((item) => item.toJson()).toList()))) {
      throw StateError('Could not save schedules');
    }
  }
}

class PhoneLock {
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static const channel = MethodChannel('focuslock/phone_lock');
  static const requiredPermissions = [
    'overlay',
    'exact',
    'phone',
    'dnd',
    'accessibility',
    'notifications'
  ];
  static bool ready(Map<String, dynamic> permissions) =>
      requiredPermissions.every((key) => permissions[key] == true);
  static Future<Map<String, dynamic>> permissions() async => supported
      ? Map<String, dynamic>.from(
          await channel.invokeMethod('permissions') as Map)
      : {};
  static Future<void> request(String permission) =>
      channel.invokeMethod('request', permission);
  static Future<void> schedule(FocusSchedule item, String language) async {
    if (supported) {
      await channel
          .invokeMethod('schedule', {...item.toJson(), 'language': language});
    }
  }

  static Future<void> cancel(String id) async {
    if (supported) await channel.invokeMethod('cancel', id);
  }
}
