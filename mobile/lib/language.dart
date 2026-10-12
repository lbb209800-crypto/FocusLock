import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage(this.preferences)
      : code = preferences.getString('language') == 'en' ? 'en' : 'ko';

  final SharedPreferences preferences;
  String code;

  void select(String value) {
    if (value == code) return;
    code = value;
    notifyListeners();
    preferences.setString('language', value);
  }
}

class LanguageScope extends InheritedNotifier<AppLanguage> {
  const LanguageScope({super.key, required AppLanguage language, required super.child})
      : super(notifier: language);

  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()!.notifier!;
}

extension TranslatedText on BuildContext {
  String tr(String english, String korean) =>
      LanguageScope.of(this).code == 'ko' ? korean : english;
}

Future<void> launchLocalizedApp(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(LanguageScope(language: AppLanguage(preferences), child: app));
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 20),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: language.code,
              dropdownColor: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              hint: Text(context.tr('Language', '언어')),
              items: const [
                DropdownMenuItem(value: 'ko', child: Text('한국어')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) language.select(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
