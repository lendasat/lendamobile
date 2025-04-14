import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/frb_generated.dart';

// Import the onboarding screen
import 'package:ark_flutter/src/ui/screens/onboarding_screen.dart';

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

Future<void> main() async {
  await RustLib.init();
  await setupLogger();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WTF Bitcoin Wallet',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
