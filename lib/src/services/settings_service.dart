import 'package:shared_preferences/shared_preferences.dart';


// const ESPLORA_URL: &str = "https://mutinynet.com/api";
// const ARK_SERVER: &'static str = "https://mutinynet.arkade.sh";

// pub const ESPLORA_URL: &str = "http://localhost:30000";
// pub const ARK_SERVER: &str = "http://localhost:7070";


class SettingsService {
  // Keys for SharedPreferences
  static const String _esploraUrlKey = 'esplora_url';
  static const String _arkServerUrlKey = 'ark_server_url';
  static const String _arkNetworkKey = 'ark_network';

  // Default values
  static const String defaultEsploraUrl = 'http://localhost:30000';
  static const String defaultArkServerUrl = 'http://localhost:7070';
  static const String defaultArkNetwork = 'regtest';

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


  // Reset to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_esploraUrlKey);
    await prefs.remove(_arkServerUrlKey);
    await prefs.remove(_arkNetworkKey);
  }
}
