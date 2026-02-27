import 'package:flutter/material.dart';

class AppSettings extends InheritedWidget {
  final Locale locale;
  final ValueChanged<Locale> setLocale;

  const AppSettings({
    super.key,
    required this.locale,
    required this.setLocale,
    required super.child,
  });

  static AppSettings of(BuildContext context) {
    final AppSettings? settings = context
        .dependOnInheritedWidgetOfExactType<AppSettings>();
    assert(settings != null, 'AppSettings not found in widget tree.');
    return settings!;
  }

  @override
  bool updateShouldNotify(AppSettings oldWidget) {
    return locale.languageCode != oldWidget.locale.languageCode;
  }
}
