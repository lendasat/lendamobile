import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling biometric authentication (fingerprint, Face ID, etc.)
class BiometricService extends ChangeNotifier {
  static const String _biometricEnabledKey = 'biometric_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  bool _isEnabled = false;
  bool _isAvailable = false;
  bool _isAuthenticated = false;
  List<BiometricType> _availableBiometrics = [];

  // Getters
  bool get isEnabled => _isEnabled;
  bool get isAvailable => _isAvailable;
  bool get isAuthenticated => _isAuthenticated;
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  /// Whether biometrics should be shown on app start
  bool get shouldShowLockScreen =>
      _isEnabled && _isAvailable && !_isAuthenticated;

  /// Initialize the service - call this on app start
  Future<void> initialize() async {
    await _loadEnabledState();
    await _checkAvailability();
  }

  /// Load the enabled state from SharedPreferences
  Future<void> _loadEnabledState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading biometric enabled state: $e');
      _isEnabled = false;
    }
  }

  /// Check if device supports biometrics and what types are available
  Future<void> _checkAvailability() async {
    try {
      // Check if device can check biometrics
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (canCheckBiometrics && isDeviceSupported) {
        _availableBiometrics = await _auth.getAvailableBiometrics();
        _isAvailable = _availableBiometrics.isNotEmpty;
      } else {
        _isAvailable = false;
        _availableBiometrics = [];
      }
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric availability: $e');
      _isAvailable = false;
      _availableBiometrics = [];
    }
    notifyListeners();
  }

  /// Enable or disable biometric authentication
  Future<bool> setEnabled(bool enabled) async {
    // If enabling, first verify biometrics work
    if (enabled) {
      if (!_isAvailable) {
        debugPrint('Cannot enable biometrics - not available on device');
        return false;
      }

      // Require authentication to enable (security measure)
      final authenticated = await authenticate(
        reason: 'Authenticate to enable biometric login',
      );
      if (!authenticated) {
        return false;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      _isEnabled = enabled;

      // If disabling, clear authenticated state
      if (!enabled) {
        _isAuthenticated = false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving biometric enabled state: $e');
      return false;
    }
  }

  /// Toggle biometric enabled state
  Future<bool> toggleEnabled() async {
    return setEnabled(!_isEnabled);
  }

  /// Authenticate the user with biometrics
  /// Returns true if authentication was successful
  Future<bool> authenticate({
    String reason = 'Please authenticate to access your wallet',
  }) async {
    if (!_isAvailable) {
      debugPrint('Biometrics not available');
      // If not available, allow access (fallback)
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );

      _isAuthenticated = authenticated;
      notifyListeners();
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Error during biometric authentication: $e');

      // Handle specific error codes
      if (e.code == 'NotAvailable' ||
          e.code == 'NotEnrolled' ||
          e.code == 'PasscodeNotSet') {
        // Biometrics not set up - allow access as fallback
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }

      // For other errors (like user cancelled), don't authenticate
      return false;
    }
  }

  /// Reset authenticated state (e.g., when app goes to background)
  void resetAuthentication() {
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Mark as authenticated (for cases where we want to skip lock screen)
  void markAuthenticated() {
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Get a human-readable name for the available biometric type
  String getBiometricTypeName() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (_availableBiometrics.contains(BiometricType.strong)) {
      return 'Biometrics';
    } else if (_availableBiometrics.contains(BiometricType.weak)) {
      return 'Biometrics';
    }
    return 'Biometrics';
  }
}
