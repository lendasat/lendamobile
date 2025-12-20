# PostHog Session Recording Implementation Guide

This document outlines how to enable PostHog session recording in the Lenda mobile app.

## Current State

The project has `posthog_flutter: ^5.6.0` installed with session replay now enabled:
- API Key and Host are read from `.env` file
- Lifecycle events: Enabled
- Session Replay: **Enabled**

## Environment Variables

Add these to your `.env` file:

```bash
# PostHog Analytics
POSTHOG_API_KEY=phc_your_api_key_here
POSTHOG_HOST=https://eu.i.posthog.com
```

See `.env_sample` for reference.

## What Was Changed

To enable session replay, we need to:
1. Disable `AUTO_INIT` mode (required for session replay)
2. Manually initialize PostHog with session replay configuration
3. Wrap the app with `PostHogWidget` (required for screen capture)
4. Add `PosthogObserver` to track screen navigation

---

## Step 1: Update Android Configuration

**File: `android/app/src/main/AndroidManifest.xml`**

Add the `AUTO_INIT` disable flag:

```xml
<!-- PostHog Configuration -->
<meta-data android:name="com.posthog.posthog.API_KEY" android:value="phc_3MrZhmMPhgvjtBN54e9aDhV2iVAom8t3ocDizQxofyw" />
<meta-data android:name="com.posthog.posthog.POSTHOG_HOST" android:value="https://eu.i.posthog.com" />
<meta-data android:name="com.posthog.posthog.TRACK_APPLICATION_LIFECYCLE_EVENTS" android:value="true" />
<meta-data android:name="com.posthog.posthog.DEBUG" android:value="false" />
<!-- ADD THIS LINE - Required for Session Replay -->
<meta-data android:name="com.posthog.posthog.AUTO_INIT" android:value="false" />
```

**Requirement:** `minSdkVersion` must be at least 21 (currently set to 23, so this is fine).

---

## Step 2: Update iOS Configuration

**File: `ios/Runner/Info.plist`**

Add the `AUTO_INIT` disable flag:

```xml
<!-- PostHog Configuration -->
<key>com.posthog.posthog.API_KEY</key>
<string>phc_3MrZhmMPhgvjtBN54e9aDhV2iVAom8t3ocDizQxofyw</string>
<key>com.posthog.posthog.POSTHOG_HOST</key>
<string>https://eu.i.posthog.com</string>
<key>com.posthog.posthog.CAPTURE_APPLICATION_LIFECYCLE_EVENTS</key>
<true/>
<key>com.posthog.posthog.DEBUG</key>
<false/>
<!-- ADD THIS LINE - Required for Session Replay -->
<key>com.posthog.posthog.AUTO_INIT</key>
<false/>
```

**Requirement:** iOS platform must be 13.0+ (currently set correctly in Podfile).

---

## Step 3: Update `main.dart`

Replace the current main.dart with manual PostHog initialization and wrap the app with `PostHogWidget`.

```dart
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
import 'package:ark_flutter/src/ui/screens/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/rust/frb_generated.dart';
import 'package:ark_flutter/src/ui/screens/onboarding_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:posthog_flutter/posthog_flutter.dart'; // ADD THIS IMPORT

// ... (keep existing setupLogger and determineStartScreen functions)

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize PostHog with session replay
  await _initPostHog();

  await RustLib.init();
  await setupLogger();

  // Initialize timezone database
  tz.initializeTimeZones();

  // Determine which screen to show first
  final startScreen = await determineStartScreen();

  runApp(MyApp(startScreen: startScreen));
}

Future<void> _initPostHog() async {
  final apiKey = dotenv.env['POSTHOG_API_KEY'];
  final host = dotenv.env['POSTHOG_HOST'];

  if (apiKey == null || apiKey.isEmpty) {
    logger.w('PostHog API key not found in .env, skipping initialization');
    return;
  }

  final config = PostHogConfig(apiKey);

  // Basic configuration
  if (host != null && host.isNotEmpty) {
    config.host = host;
  }
  config.captureApplicationLifecycleEvents = true;
  config.debug = false; // Set to true for development

  // Enable session replay
  config.sessionReplay = true;
  // Don't mask all text/images globally - use PostHogMaskWidget for specific sensitive areas
  config.sessionReplayConfig.maskAllTexts = false;
  config.sessionReplayConfig.maskAllImages = false;
  // config.sessionReplayConfig.screenshot = true;  // Optional: Use screenshots instead of wireframes

  await Posthog().setup(config);
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return PostHogWidget(  // WRAP WITH PostHogWidget - REQUIRED FOR SESSION REPLAY
      child: MultiProvider(
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
            navigatorObservers: [PosthogObserver()], // ADD THIS FOR SCREEN TRACKING
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
      ),
    );
  }
}
```

---

## Session Replay Configuration Options

| Option | Default | Our Setting | Description |
|--------|---------|-------------|-------------|
| `sessionReplay` | `false` | `true` | Enable/disable session replay |
| `maskAllTexts` | `true` | `false` | Masks all text elements - we use `PostHogMaskWidget` instead for targeted masking |
| `maskAllImages` | `true` | `false` | Masks all images - we use `PostHogMaskWidget` instead for targeted masking |
| `screenshot` | `false` | `false` | Use screenshots instead of wireframes (more detail but less privacy) |
| `throttleDelay` | `Duration(milliseconds: 1000)` | default | Minimum time between replay snapshots |

---

## Recording Modes

### Wireframe Mode (Default)
- Uses native APIs to capture view hierarchy
- Renders as HTML wireframe representation
- More privacy-conscious
- Lower performance impact
- UI won't look exactly like the app but shows user behavior

### Screenshot Mode
- Takes actual screenshots of the screen
- More accurate visual representation
- May contain sensitive information if not properly masked
- Enable with: `config.sessionReplayConfig.screenshot = true`

---

## Privacy Controls

### Currently Masked Widgets

The following sensitive data is masked in session recordings using `PostHogMaskWidget`:

| Screen | Masked Content |
|--------|---------------|
| `mnemonic_input_screen.dart` | All 12 mnemonic word input fields |
| `recovery_key_view.dart` | Mnemonic phrase display grid |
| `recovery_key_view.dart` | Verification word input fields |
| `receivescreen.dart` | QR code (contains address) |
| `receivescreen.dart` | Address/invoice display |
| `walletscreen.dart` | Balance display (sats and fiat) |
| `send_screen.dart` | Recipient address input field |
| `send_screen.dart` | Recipient address display |

### Adding New Masked Views

For specific widgets that should always be masked:

```dart
// Use PostHogMaskWidget to mask specific sensitive content
PostHogMaskWidget(
  child: Text('Sensitive content like wallet balance'),
)
```

### Network Recording Privacy

When `captureNetworkTelemetry` is enabled:
- Only captures metrics (speed, size, response codes)
- Does NOT capture request/response body data
- Automatically scrubs sensitive headers (`authorization`, `cookie`, etc.)

---

## PostHog Dashboard Setup

1. Go to your PostHog project settings
2. Navigate to **Session Replay** settings
3. Enable **"Record user sessions"**
4. For Flutter Web: Also enable **"Canvas capture"** (Flutter renders to canvas on web)

---

## Testing Session Replay

1. Set `config.debug = true` in development
2. Run the app and navigate through several screens
3. Wait a few minutes for data to sync
4. Check PostHog dashboard under **Session Replay** section

---

## Tracking Custom Events

You can still track custom events alongside session replay:

```dart
import 'package:posthog_flutter/posthog_flutter.dart';

// Track an event
await Posthog().capture(
  eventName: 'button_clicked',
  properties: {'button_name': 'send_payment'},
);

// Identify a user
await Posthog().identify(
  userId: 'user_123',
  userProperties: {'plan': 'premium'},
);

// Track screen views manually (if not using PosthogObserver)
await Posthog().screen(
  screenName: 'Wallet Screen',
  properties: {'has_balance': true},
);
```

---

## Controlling Session Recording

```dart
// Start recording (if not auto-started)
await Posthog().startSessionRecording();

// Stop recording
await Posthog().stopSessionRecording();

// Check if recording is active
final isRecording = await Posthog().isSessionReplayActive();
```

---

## Troubleshooting

### Session recordings not appearing
1. Ensure `AUTO_INIT` is set to `false` in both platforms
2. Verify `PostHogWidget` wraps the entire app (must be root)
3. Check that `MaterialApp` is a child of `PostHogWidget`
4. Confirm session replay is enabled in PostHog dashboard
5. Wait 2-5 minutes for recordings to appear

### Blank or missing screens
1. Check if `PosthogObserver` is added to `navigatorObservers`
2. Ensure masked content isn't hiding everything

### Performance issues
1. Increase `throttleDelay` to reduce snapshot frequency
2. Use wireframe mode instead of screenshot mode
3. Consider disabling session replay for performance-critical screens

---

## Sources

- [PostHog Flutter Documentation](https://posthog.com/docs/libraries/flutter)
- [PostHog Mobile Session Replay](https://posthog.com/docs/session-replay/mobile)
- [posthog_flutter on pub.dev](https://pub.dev/packages/posthog_flutter)
- [PostHog Flutter GitHub](https://github.com/PostHog/posthog-flutter)
- [How to Control Which Sessions You Record](https://posthog.com/docs/session-replay/how-to-control-which-sessions-you-record)
