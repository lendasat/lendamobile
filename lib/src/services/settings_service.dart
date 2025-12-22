import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // Keys for SharedPreferences
  static const String _esploraUrlKey = 'esplora_url';
  static const String _arkServerUrlKey = 'ark_server_url';
  static const String _arkNetworkKey = 'ark_network';
  static const String _boltzUrlKey = 'boltz_url';
  static const String _wordRecoverySetKey = 'word_recovery_set';
  static const String _userEmailKey = 'user_email';

  // Default values from environment variables
  static String get defaultEsploraUrl =>
      dotenv.env['ESPLORA_URL'] ?? 'http://localhost:30000';
  static String get defaultArkServerUrl =>
      dotenv.env['ARK_SERVER_URL'] ?? 'http://localhost:7070';
  static String get defaultArkNetwork => dotenv.env['ARK_NETWORK'] ?? 'regtest';
  static String get defaultBoltzUrl =>
      dotenv.env['BOLTZ_URL'] ?? 'http://localhost:9001';
  static String get defaultBackendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:7337';
  static String get defaultWebsiteUrl =>
      dotenv.env['WEBSITE_URL'] ?? 'http://localhost:3000';

  // Singleton instance
  static final SettingsService _instance = SettingsService._internal();

  // Factory constructor
  factory SettingsService() => _instance;

  // Private constructor
  SettingsService._internal();

  // Get Esplora URL
  Future<String> getEsploraUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_esploraUrlKey) ?? defaultEsploraUrl;
  }

  // Save Esplora URL
  Future<bool> saveEsploraUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_esploraUrlKey, url);
  }

  // Get Ark Server URL
  Future<String> getArkServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_arkServerUrlKey) ?? defaultArkServerUrl;
  }

  // Save Ark Server URL
  Future<bool> saveArkServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_arkServerUrlKey, url);
  }

  // Get Ark Network
  Future<String> getNetwork() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_arkNetworkKey) ?? defaultArkNetwork;
  }

  // Save Network
  Future<bool> saveNetwork(String network) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_arkNetworkKey, network);
  }

  // Get Boltz URL
  Future<String> getBoltzUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_boltzUrlKey) ?? defaultBoltzUrl;
  }

  // Save Boltz URL
  Future<bool> saveBoltzUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_boltzUrlKey, url);
  }

  // Get Backend URL
  Future<String> getBackendUrl() async {
    // Return the default from .env
    // This could be extended to support user customization if needed
    return defaultBackendUrl;
  }

  // Get Website URL
  Future<String> getWebsiteUrl() async {
    // Return the default from .env
    // This could be extended to support user customization if needed
    return defaultWebsiteUrl;
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_esploraUrlKey);
    await prefs.remove(_arkServerUrlKey);
    await prefs.remove(_arkNetworkKey);
    await prefs.remove(_boltzUrlKey);
    await prefs.remove(_wordRecoverySetKey);
  }

  // Check if word recovery has been viewed/backed up
  Future<bool> isWordRecoverySet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wordRecoverySetKey) ?? false;
  }

  // Mark word recovery as viewed/backed up
  Future<bool> setWordRecoveryComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_wordRecoverySetKey, true);
  }

  // Clear word recovery status
  Future<bool> clearWordRecoveryStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_wordRecoverySetKey);
  }

  // Get Lendasat API URL (same as Backend URL)
  Future<String> getLendasatApiUrl() async {
    return defaultBackendUrl;
  }

  // Get user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Set user email
  Future<bool> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userEmailKey, email);
  }

  // Clear user email
  Future<bool> clearUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_userEmailKey);
  }
}
