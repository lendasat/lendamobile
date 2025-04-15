import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/frb_generated.dart';
import 'package:ark_flutter/src/ui/screens/onboarding_screen.dart';
import 'package:ark_flutter/src/ui/screens/dashboard_screen.dart';
import 'package:path_provider/path_provider.dart';

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

    if (exists) {
      logger.i("Wallet found, setting up client");
      // Setup ARK client with existing wallet
      final aspId = await loadExistingWallet(
          dataDir: dataDir,
          esplora: esploraUrl,
          server: arkServerUrl,
          network: network);
      logger.i("Wallet setup complete, ID: $aspId");

      // Return the dashboard screen with the ASP ID
      return DashboardScreen(aspId: aspId);
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
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await setupLogger();

  // Determine which screen to show first
  final startScreen = await determineStartScreen();

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ark - Flutter - Sample',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: startScreen,
    );
  }
}
