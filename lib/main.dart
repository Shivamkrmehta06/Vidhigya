import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trata_app/app/app_settings.dart';
import 'package:trata_app/l10n/app_localizations.dart';
import 'package:trata_app/theme/app_theme.dart';
import 'package:trata_app/views/home_view.dart';
import 'package:trata_app/views/login_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static const bool startOnHome = false;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _localePreferenceKey = 'app_locale_code';
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final SharedPreferences? prefs = await _loadPrefsSafely();
    if (prefs == null) return;
    final String? savedLanguageCode = prefs.getString(_localePreferenceKey);
    if (savedLanguageCode == null ||
        savedLanguageCode == _locale.languageCode) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _locale = Locale(savedLanguageCode);
    });
  }

  void _setLocale(Locale locale) {
    if (_locale.languageCode == locale.languageCode) return;
    setState(() {
      _locale = Locale(locale.languageCode);
    });
    _persistLocaleSafely(locale.languageCode);
  }

  Future<SharedPreferences?> _loadPrefsSafely() async {
    try {
      return await SharedPreferences.getInstance();
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> _persistLocaleSafely(String languageCode) async {
    final SharedPreferences? prefs = await _loadPrefsSafely();
    if (prefs == null) return;
    await prefs.setString(_localePreferenceKey, languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return AppSettings(
      locale: _locale,
      setLocale: _setLocale,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryNavy,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.outfitTextTheme(),
          scaffoldBackgroundColor: AppTheme.cloud,
        ),
        home: MyApp.startOnHome ? const HomeView() : const LoginScreen(),
      ),
    );
  }
}
