import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/providers/theme_provider.dart';
import 'package:ark_flutter/src/rust/api.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/language_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/services/settings_controller.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/services/transaction_filter_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/screens/walletscreen.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/frb_generated.dart';
import 'package:ark_flutter/src/ui/screens/onboarding_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';

Future setupLogger() async {
  buildLogger(false);

  initLogging().listen((event) {
    var message = event.target != ""
        ? 'r: ${event.target}: ${event.msg} ${event.data}'
        : 'r: ${event.msg} ${event.data}';
    switch (event.level) {
      case "INFO":
        logger.i(message);
      case "DEBUG":
        logger.d(message);
      case "ERROR":
        logger.e(message);
      case "WARN":
        logger.w(message);
      case "TRACE":
        logger.t(message);
      default:
        logger.d(message);
    }
  });
  logger.d("Logger is working!");
}

final SettingsService _settingsService = SettingsService();

Future<Widget> determineStartScreen() async {
  try {
    // Get application support directory
    final applicationSupportDirectory = await getApplicationSupportDirectory();
    final dataDir = applicationSupportDirectory.path;
    logger.i("Checking for wallet in directory: $dataDir");

    // Check if wallet exists
    final exists = await walletExists(dataDir: dataDir);

    final esploraUrl = await _settingsService.getEsploraUrl();
    final arkServerUrl = await _settingsService.getArkServerUrl();
    final network = await _settingsService.getNetwork();
    final boltzUrl = await _settingsService.getBoltzUrl();

    logger.i(
        "Running on $network against ark server $arkServerUrl, esplora $esploraUrl, and boltz $boltzUrl");

    if (exists) {
      logger.i("Wallet found, setting up client");
      // Setup ARK client with existing wallet
      final aspId = await loadExistingWallet(
          dataDir: dataDir,
          esplora: esploraUrl,
          server: arkServerUrl,
          network: network,
          boltzUrl: boltzUrl);
      logger.i("Wallet setup complete, ID: $aspId");

      // Return the dashboard screen with the ASP ID
      return WalletScreen(aspId: aspId);
    } else {
      logger.i("No wallet found, showing onboarding screen");
      // Return the onboarding screen
      return const OnboardingScreen();
    }
  } catch (e) {
    logger.e("Error while checking wallet existence: $e");
    // In case of error, show the onboarding screen
    return const OnboardingScreen();
  }
}

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await setupLogger();

  // Initialize timezone database
  tz.initializeTimeZones();

  // Determine which screen to show first
  final startScreen = await determineStartScreen();

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider()..loadSavedTheme(),
        ),
        ChangeNotifierProvider(
          create: (context) => LanguageService()..loadSavedLanguage(),
        ),
        ChangeNotifierProvider(
          create: (context) => TimezoneService()..loadSavedTimezone(),
        ),
        ChangeNotifierProvider(
          create: (context) => CurrencyPreferenceService()..loadSavedCurrency(),
        ),
        ChangeNotifierProvider(
          create: (context) => TransactionFilterService(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsController(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserPreferencesService()..loadPreferences(),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageService>(
        builder: (context, themeProvider, languageService, _) => MaterialApp(
          title: 'Ark - Flutter - Sample',
          theme: themeProvider.getMaterialTheme(),
          locale: languageService.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LanguageService.supportedLocales,
          home: startScreen,
        ),
      ),
    );
  }
}
