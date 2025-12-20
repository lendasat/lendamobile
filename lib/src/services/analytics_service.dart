import 'package:path_provider/path_provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark;

/// Centralized analytics service for tracking user events.
/// Tracks transaction events for monthly active user (MAU) calculation.
///
/// A user is considered active in a month if they have at least 1 transaction:
/// - loan_transaction
/// - bitcoin_transaction (buy or sell)
/// - send_transaction
/// - receive_transaction
/// - swap_transaction
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  String? _userPubkey;

  /// Identify the user by their Nostr public key (npub).
  ///
  /// The Nostr pubkey is the CANONICAL USER IDENTIFIER across all services.
  /// It's derived from the wallet mnemonic at path m/44'/1237'/0'/0/0 (NIP-06).
  ///
  /// This ensures consistent user identification regardless of which
  /// service-specific keys (Arkade, Lendasat, LendaSwap) are being used.
  ///
  /// Should be called after wallet is created/restored.
  Future<void> identifyUser() async {
    try {
      // Get data directory for Rust API call
      final dataDir = await getApplicationSupportDirectory();

      // Get the user's Nostr public key (npub) as the canonical identifier
      // This is consistent across all services derived from the same mnemonic
      final npub = await ark.npub(dataDir: dataDir.path);
      _userPubkey = npub;

      await Posthog().identify(
        userId: npub,
        userProperties: {
          'npub': npub,
          'identified_at': DateTime.now().toIso8601String(),
        },
      );
      logger.i('[Analytics] User identified with npub: ${npub.substring(0, 20)}...');
    } catch (e) {
      logger.w('[Analytics] Failed to identify user: $e');
    }
  }

  /// Get current user pubkey (if identified)
  String? get userPubkey => _userPubkey;

  /// Track a send transaction (on-chain or off-chain)
  Future<void> trackSendTransaction({
    required int amountSats,
    required String transactionType, // 'onchain' or 'offchain'
    String? txId,
  }) async {
    try {
      await Posthog().capture(
        eventName: 'send_transaction',
        properties: {
          'amount_sats': amountSats,
          'transaction_type': transactionType,
          if (txId != null) 'tx_id': txId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      logger.i('[Analytics] Tracked send_transaction: $amountSats sats ($transactionType)');
    } catch (e) {
      logger.w('[Analytics] Failed to track send_transaction: $e');
    }
  }

  /// Track a receive transaction (on-chain or off-chain)
  Future<void> trackReceiveTransaction({
    required int amountSats,
    required String transactionType, // 'onchain' or 'offchain'
    String? txId,
  }) async {
    try {
      await Posthog().capture(
        eventName: 'receive_transaction',
        properties: {
          'amount_sats': amountSats,
          'transaction_type': transactionType,
          if (txId != null) 'tx_id': txId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      logger.i('[Analytics] Tracked receive_transaction: $amountSats sats ($transactionType)');
    } catch (e) {
      logger.w('[Analytics] Failed to track receive_transaction: $e');
    }
  }

  /// Track a swap transaction (BTC <-> other assets)
  Future<void> trackSwapTransaction({
    required int amountSats,
    required String fromAsset,
    required String toAsset,
    String? swapId,
  }) async {
    try {
      await Posthog().capture(
        eventName: 'swap_transaction',
        properties: {
          'amount_sats': amountSats,
          'from_asset': fromAsset,
          'to_asset': toAsset,
          if (swapId != null) 'swap_id': swapId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      logger.i('[Analytics] Tracked swap_transaction: $amountSats sats ($fromAsset -> $toAsset)');
    } catch (e) {
      logger.w('[Analytics] Failed to track swap_transaction: $e');
    }
  }

  /// Track a bitcoin buy/sell transaction (fiat <-> BTC)
  Future<void> trackBitcoinTransaction({
    required int amountSats,
    required String type, // 'buy' or 'sell'
    required String fiatCurrency,
    double? fiatAmount,
    String? provider,
  }) async {
    try {
      await Posthog().capture(
        eventName: 'bitcoin_transaction',
        properties: {
          'amount_sats': amountSats,
          'type': type,
          'fiat_currency': fiatCurrency,
          if (fiatAmount != null) 'fiat_amount': fiatAmount,
          if (provider != null) 'provider': provider,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      logger.i('[Analytics] Tracked bitcoin_transaction: $type $amountSats sats');
    } catch (e) {
      logger.w('[Analytics] Failed to track bitcoin_transaction: $e');
    }
  }

  /// Track a loan transaction (borrow or repay)
  Future<void> trackLoanTransaction({
    required int amountSats,
    required String type, // 'borrow' or 'repay'
    String? loanId,
    double? interestRate,
    int? durationDays,
  }) async {
    try {
      await Posthog().capture(
        eventName: 'loan_transaction',
        properties: {
          'amount_sats': amountSats,
          'type': type,
          if (loanId != null) 'loan_id': loanId,
          if (interestRate != null) 'interest_rate': interestRate,
          if (durationDays != null) 'duration_days': durationDays,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      logger.i('[Analytics] Tracked loan_transaction: $type $amountSats sats');
    } catch (e) {
      logger.w('[Analytics] Failed to track loan_transaction: $e');
    }
  }

  /// Track wallet creation
  Future<void> trackWalletCreated({bool isRestore = false}) async {
    try {
      await Posthog().capture(
        eventName: 'wallet_created',
        properties: {
          'is_restore': isRestore,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      logger.i('[Analytics] Tracked wallet_created (isRestore: $isRestore)');
    } catch (e) {
      logger.w('[Analytics] Failed to track wallet_created: $e');
    }
  }
}
