import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trata_app/app/app_settings.dart';
import 'package:trata_app/l10n/app_localizations.dart';
import 'package:trata_app/theme/app_theme.dart';
import 'package:trata_app/views/home_view.dart';
import 'package:trata_app/views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await _configureFirebaseAuthForAndroid();
    await _activateAppCheck();
  } catch (error) {
    debugPrint('Firebase init skipped: $error');
  }
  runApp(const MyApp());
}

Future<void> _configureFirebaseAuthForAndroid() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  try {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: false,
      forceRecaptchaFlow: kDebugMode,
    );
  } catch (error) {
    debugPrint('Firebase Auth Android settings skipped: $error');
  }
}

Future<void> _activateAppCheck() async {
  if (kIsWeb || Firebase.apps.isEmpty) {
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );

    if (kDebugMode) {
      final String? debugToken = await FirebaseAppCheck.instance.getToken(true);
      if (debugToken != null && debugToken.isNotEmpty) {
        debugPrint('App Check debug token: $debugToken');
      }
    }
  } catch (error) {
    debugPrint('App Check activation skipped: $error');
  }
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
