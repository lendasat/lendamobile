import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/screens/loans/loan_filter_screen.dart';
import 'loans_config.dart';
import 'loans_state.dart';

/// Controller for loans screen business logic.
class LoansController extends ChangeNotifier {
  final LendasatService _lendasatService;
  final SettingsService _settingsService;

  LoansState _state = LoansState.initial();
  Timer? _autoRefreshTimer;

  LoansController({
    LendasatService? lendasatService,
    SettingsService? settingsService,
  })  : _lendasatService = lendasatService ?? LendasatService(),
        _settingsService = settingsService ?? SettingsService();

  /// Current state.
  LoansState get state => _state;

  /// Access to lendasat service for direct queries.
  LendasatService get lendasatService => _lendasatService;

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// Start auto-refresh timer for active contracts.
  void startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: LoansConfig.autoRefreshIntervalSeconds),
      (_) {
        if (_lendasatService.activeContracts.isNotEmpty) {
          refresh();
        }
      },
    );
  }

  /// Stop auto-refresh timer.
  void stopAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Initialize Lendasat service and load data.
  Future<void> initialize() async {
    _updateState(_state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      await _lendasatService.initialize();

      // Fetch debug info
      try {
        final debugPubkey = await _lendasatService.getPublicKey();
        final debugDerivationPath = await _lendasatService.getDerivationPath();
        _updateState(_state.copyWith(
          debugPubkey: debugPubkey,
          debugDerivationPath: debugDerivationPath,
        ));
        logger.i('Lendasat pubkey: $debugPubkey');
        logger.i('Lendasat derivation path: $debugDerivationPath');
      } catch (e) {
        logger.w('Could not get debug info: $e');
      }

      // Try to authenticate
      if (!_lendasatService.isAuthenticated) {
        await autoAuthenticate();
      }

      // Try to load data
      await _loadData();

      // If data is empty after initial load, retry after a short delay
      if ((_lendasatService.offers.isEmpty ||
          (_lendasatService.isAuthenticated &&
              _lendasatService.contracts.isEmpty))) {
        logger.i('Lendasat: Initial data empty, retrying after delay...');
        await Future.delayed(
            const Duration(milliseconds: LoansConfig.retryDelayMs));
        await _loadData();

        // If contracts are still empty after retry, try one more time
        if (_lendasatService.isAuthenticated &&
            _lendasatService.contracts.isEmpty) {
          logger.i('Lendasat: Contracts still empty, retrying once more...');
          await Future.delayed(
              const Duration(milliseconds: LoansConfig.retryDelayMs));
          try {
            await _lendasatService.refreshContracts();
          } catch (e) {
            logger.w('Could not load contracts on retry: $e');
          }
        }
      }

      _syncFromService();
    } catch (e) {
      logger.e('Error initializing Lendasat: $e');
      _updateState(_state.copyWith(errorMessage: e.toString()));
    } finally {
      _updateState(_state.copyWith(isLoading: false));
    }
  }

  /// Load offers and contracts data.
  Future<void> _loadData() async {
    try {
      if (_lendasatService.isAuthenticated) {
        await Future.wait([
          _lendasatService.refreshOffers(),
          _lendasatService.refreshContracts(),
        ]);
      } else {
        await _lendasatService.refreshOffers();
      }
      _syncFromService();
    } catch (e) {
      if (_isUnauthorizedError(e)) {
        logger.i('Token expired, re-authenticating...');
        await autoAuthenticate();
        if (_lendasatService.isAuthenticated) {
          try {
            await Future.wait([
              _lendasatService.refreshOffers(),
              _lendasatService.refreshContracts(),
            ]);
            _syncFromService();
          } catch (retryError) {
            logger.w('Could not load data after re-auth: $retryError');
          }
        }
      } else {
        logger.w('Could not load data: $e');
      }
    }
  }

  /// Auto-authenticate with Lendasat using the wallet keypair.
  Future<void> autoAuthenticate() async {
    try {
      final result = await _lendasatService.authenticate();

      if (result is AuthResult_NeedsRegistration) {
        logger.w('Lendasat: Pubkey not registered, user needs to sign up');
      } else if (result is AuthResult_Success) {
        logger.i('Lendasat: Auto-authentication successful');
        try {
          await _lendasatService.refreshContracts();
          logger.i('Lendasat: Contracts loaded after auth');
        } catch (e) {
          logger.w('Could not load contracts after auth: $e');
        }
      }
      _syncFromService();
    } catch (e) {
      logger.e('Lendasat auto-auth error: $e');
    }
  }

  /// Register a new user with Lendasat.
  Future<void> register({required String email}) async {
    _updateState(_state.copyWith(isRegistering: true));

    try {
      logger.i('[SIGNUP] Registering with Lendasat...');
      await _lendasatService.register(
        email: email,
        name: 'Lendasat User',
        inviteCode: LoansConfig.defaultInviteCode,
      );

      await _settingsService.setUserEmail(email);
      logger.i('[SIGNUP] Registration successful');

      await autoAuthenticate();
      await _loadData();

      OverlayService().showSuccess('Registration successful!');
    } catch (e) {
      logger.e('[SIGNUP] Registration failed: $e');

      // Check if already registered
      if (e.toString().toLowerCase().contains('already') ||
          e.toString().toLowerCase().contains('exists')) {
        await autoAuthenticate();
        if (_lendasatService.isAuthenticated) {
          await _loadData();
          return;
        }
      }
      rethrow;
    } finally {
      _updateState(_state.copyWith(isRegistering: false));
    }
  }

  /// Refresh offers and contracts.
  Future<void> refresh() async {
    try {
      await Future.wait([
        _lendasatService.refreshOffers(),
        if (_lendasatService.isAuthenticated)
          _lendasatService.refreshContracts(),
      ]);
      _syncFromService();
    } catch (e) {
      if (_isUnauthorizedError(e)) {
        logger.i('Token expired during refresh, re-authenticating...');
        await autoAuthenticate();
        if (_lendasatService.isAuthenticated) {
          try {
            await Future.wait([
              _lendasatService.refreshOffers(),
              _lendasatService.refreshContracts(),
            ]);
            _syncFromService();
          } catch (retryError) {
            logger.e('Error refreshing after re-auth: $retryError');
          }
        }
      } else {
        logger.e('Error refreshing: $e');
      }
    }
  }

  /// Update search query.
  void setSearchQuery(String query) {
    _updateState(_state.copyWith(searchQuery: query.toLowerCase()));
  }

  /// Update filter options.
  void setFilterOptions(LoanFilterOptions options) {
    _updateState(_state.copyWith(filterOptions: options));
  }

  /// Toggle debug info visibility.
  void toggleDebugInfo() {
    _updateState(_state.copyWith(showDebugInfo: !_state.showDebugInfo));
  }

  /// Hide debug info.
  void hideDebugInfo() {
    _updateState(_state.copyWith(showDebugInfo: false));
  }

  /// Check if error is a 401 Unauthorized error.
  bool _isUnauthorizedError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('401') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('invalid token');
  }

  /// Sync state from service.
  void _syncFromService() {
    _updateState(_state.copyWith(
      offers: List.from(_lendasatService.offers),
      contracts: List.from(_lendasatService.contracts),
      isAuthenticated: _lendasatService.isAuthenticated,
    ));
  }

  void _updateState(LoansState newState) {
    _state = newState;
    notifyListeners();
  }
}
