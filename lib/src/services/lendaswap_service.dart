import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/lendaswap_api.dart' as lendaswap_api;
import 'package:ark_flutter/src/rust/lendaswap.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for LendaSwap atomic swaps (BTC <-> Stablecoins).
class LendaSwapService extends ChangeNotifier {
  static final LendaSwapService _instance = LendaSwapService._internal();

  factory LendaSwapService() => _instance;

  LendaSwapService._internal();

  bool _isInitialized = false;
  bool _isInitializing = false;
  List<lendaswap_api.TradingPair> _tradingPairs = [];
  List<SwapInfo> _swaps = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  List<lendaswap_api.TradingPair> get tradingPairs => _tradingPairs;
  List<SwapInfo> get swaps => _swaps;

  /// Reset the service state. Call this when wallet is reset.
  void reset() {
    _isInitialized = false;
    _isInitializing = false;
    _tradingPairs = [];
    _swaps = [];
    notifyListeners();
    logger.i('LendaSwapService reset');
  }

  /// Initialize LendaSwap client.
  /// Should be called after wallet is initialized and mnemonic exists.
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      // IMPORTANT: Use same directory as Ark wallet (ApplicationSupportDirectory)
      // NOT ApplicationDocumentsDirectory - they are different paths!
      final dataDir = await getApplicationSupportDirectory();
      final settingsService = SettingsService();
      final network = await settingsService.getNetwork();

      // Map network to LendaSwap network string
      final networkStr = _mapNetwork(network);

      // Get API URLs based on network
      final apiUrl = _getApiUrl(networkStr);
      final arkadeUrl = _getArkadeUrl(networkStr);

      await lendaswap_api.lendaswapInit(
        dataDir: dataDir.path,
        network: networkStr,
        apiUrl: apiUrl,
        arkadeUrl: arkadeUrl,
      );

      _isInitialized = true;
      logger.i('LendaSwap initialized on network: $networkStr');

      // Load trading pairs
      await refreshTradingPairs();

      // Load existing swaps from local storage
      await refreshSwaps();

      // If no local swaps, try to recover from server
      // This handles wallet restore scenarios where local storage is empty
      // but the user has previous swaps associated with their mnemonic
      if (_swaps.isEmpty) {
        try {
          logger
              .i('No local swaps found, attempting to recover from server...');
          final recoveredSwaps = await lendaswap_api.lendaswapRecoverSwaps();
          if (recoveredSwaps.isNotEmpty) {
            _swaps = recoveredSwaps;
            logger.i('Recovered ${recoveredSwaps.length} swaps from server');
            notifyListeners();
          }
        } catch (e) {
          // Check if this is a parsing error
          final errorStr = e.toString();
          if (_isParsingError(errorStr)) {
            logger.w('[LendaSwap Dart] Parsing error during recovery: $e');
            logger.w(
                '[LendaSwap Dart] Will continue without swaps - they can be recovered later');
            _swaps = [];
          } else {
            // Recovery is best-effort, don't fail initialization
            logger.w('Could not recover swaps from server: $e');
          }
        }
      }
    } catch (e) {
      logger.e('Error initializing LendaSwap: $e');
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Refresh available trading pairs.
  Future<void> refreshTradingPairs() async {
    try {
      _tradingPairs = await lendaswap_api.lendaswapGetAssetPairs();
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching trading pairs: $e');
      rethrow;
    }
  }

  /// Refresh all swaps from storage.
  Future<void> refreshSwaps() async {
    logger.d('[LendaSwap Dart] refreshSwaps called');
    try {
      _swaps = await lendaswap_api.lendaswapListSwaps();
      logger.i(
          '[LendaSwap Dart] refreshSwaps SUCCESS - found ${_swaps.length} swaps');
      for (final swap in _swaps) {
        logger.d(
            '[LendaSwap Dart] - swap ${swap.id}: status=${swap.status}, detailed=${swap.detailedStatus}');
      }
      notifyListeners();
    } catch (e) {
      // Check if this is a serialization/parsing error (RangeError with timestamp-like values)
      final errorStr = e.toString();
      if (_isParsingError(errorStr)) {
        logger.w('[LendaSwap Dart] Swap parsing error detected: $e');
        logger.w(
            '[LendaSwap Dart] This may be caused by serialization mismatch. Attempting recovery...');
        await _handleParsingError();
        return;
      }
      logger.e('[LendaSwap Dart] refreshSwaps FAILED: $e');
      rethrow;
    }
  }

  /// Check if an error is a parsing/serialization error.
  bool _isParsingError(String errorStr) {
    // RangeError with large values typically indicates serialization mismatch
    // where a timestamp or other large value is being used as an enum index
    if (errorStr.contains('RangeError')) {
      // Extract the value if present
      final match = RegExp(r'Value not in range: (\d+)').firstMatch(errorStr);
      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '0') ?? 0;
        // Unix timestamps are typically > 1000000000 (Sep 2001)
        // Enum indices should be < 100
        if (value > 1000) {
          logger.w(
              '[LendaSwap Dart] Detected likely timestamp value used as index: $value');
          return true;
        }
      }
      return true;
    }
    return false;
  }

  /// Handle parsing errors by recovering swaps from server.
  Future<void> _handleParsingError() async {
    try {
      logger.i('[LendaSwap Dart] Recovering swaps from server...');
      final recovered = await lendaswap_api.lendaswapRecoverSwaps();
      _swaps = recovered;
      logger
          .i('[LendaSwap Dart] Successfully recovered ${_swaps.length} swaps');
      notifyListeners();
    } catch (recoveryError) {
      logger.e('[LendaSwap Dart] Recovery also failed: $recoveryError');
      // Keep empty swaps list rather than crashing
      _swaps = [];
      notifyListeners();
    }
  }

  /// Get a quote for a swap.
  Future<lendaswap_api.SwapQuote> getQuote({
    required String fromToken,
    required String toToken,
    required int amountSats,
  }) async {
    try {
      return await lendaswap_api.lendaswapGetQuote(
        fromToken: fromToken,
        toToken: toToken,
        amountSats: BigInt.from(amountSats),
      );
    } catch (e) {
      logger.e('Error getting quote: $e');
      rethrow;
    }
  }

  /// Create a BTC to EVM swap (sell BTC for EVM tokens).
  /// [targetAmount] is the amount in target token units (e.g., 50 for USDC, 0.02 for XAUt)
  Future<lendaswap_api.BtcToEvmSwapResult> createSellBtcSwap({
    required String targetEvmAddress,
    required double targetAmount,
    required String targetToken,
    required String targetChain,
    String? referralCode,
  }) async {
    logger.i('[LendaSwap Dart] createSellBtcSwap called');
    logger.d('[LendaSwap Dart] targetEvmAddress: $targetEvmAddress');
    logger.d('[LendaSwap Dart] targetAmount: $targetAmount');
    logger.d('[LendaSwap Dart] targetToken: $targetToken');
    logger.d('[LendaSwap Dart] targetChain: $targetChain');
    logger.d('[LendaSwap Dart] referralCode: $referralCode');

    try {
      logger.i('[LendaSwap Dart] calling lendaswapCreateBtcToEvmSwap...');
      final result = await lendaswap_api.lendaswapCreateBtcToEvmSwap(
        targetEvmAddress: targetEvmAddress,
        targetAmountUsd:
            targetAmount, // API still uses this name but it's actually token amount
        targetToken: targetToken,
        targetChain: targetChain,
        referralCode: referralCode,
      );

      logger.i('[LendaSwap Dart] createSellBtcSwap SUCCESS');
      logger.i('[LendaSwap Dart] swap_id: ${result.swapId}');
      logger.i(
          '[LendaSwap Dart] ln_invoice: ${result.lnInvoice.substring(0, 50.clamp(0, result.lnInvoice.length))}...');
      logger.i(
          '[LendaSwap Dart] arkade_htlc_address: ${result.arkadeHtlcAddress}');
      logger.i('[LendaSwap Dart] sats_to_send: ${result.satsToSend}');
      logger.i('[LendaSwap Dart] target_amount_usd: ${result.targetAmountUsd}');
      logger.i('[LendaSwap Dart] fee_sats: ${result.feeSats}');

      // Refresh swaps list
      logger.d('[LendaSwap Dart] refreshing swaps list...');
      await refreshSwaps();
      logger.d('[LendaSwap Dart] swaps list refreshed');

      return result;
    } catch (e) {
      logger.e('[LendaSwap Dart] createSellBtcSwap FAILED: $e');
      rethrow;
    }
  }

  /// Create an EVM to BTC swap (buy BTC with EVM tokens).
  /// [sourceAmount] is the amount in source token units (e.g., 50 for USDC, 0.02 for XAUt)
  /// [userEvmAddress] is the user's WalletConnect-connected address (required for createSwap calldata)
  ///
  /// After calling this, the user MUST:
  /// 1. Call approve() on the ERC20 token (using result.approveTx or WalletConnectService.approveToken)
  /// 2. Call createSwap() on the HTLC contract (using result.createSwapTx)
  /// Both transactions are signed via WalletConnect.
  Future<lendaswap_api.EvmToBtcSwapResult> createBuyBtcSwap({
    required String targetArkAddress,
    required String userEvmAddress,
    required double sourceAmount,
    required String sourceToken,
    required String sourceChain,
    String? referralCode,
  }) async {
    try {
      final result = await lendaswap_api.lendaswapCreateEvmToBtcSwap(
        targetArkAddress: targetArkAddress,
        userEvmAddress: userEvmAddress,
        sourceAmountUsd:
            sourceAmount, // API still uses this name but it's actually token amount
        sourceToken: sourceToken,
        sourceChain: sourceChain,
        referralCode: referralCode,
      );

      // Refresh swaps list
      await refreshSwaps();

      return result;
    } catch (e) {
      logger.e('Error creating EVM to BTC swap: $e');
      rethrow;
    }
  }

  /// Create an EVM to Lightning swap.
  Future<lendaswap_api.EvmToBtcSwapResult> createEvmToLightningSwap({
    required String bolt11Invoice,
    required String userEvmAddress,
    required String sourceToken,
    required String sourceChain,
    String? referralCode,
  }) async {
    try {
      final result = await lendaswap_api.lendaswapCreateEvmToLightningSwap(
        bolt11Invoice: bolt11Invoice,
        userEvmAddress: userEvmAddress,
        sourceToken: sourceToken,
        sourceChain: sourceChain,
        referralCode: referralCode,
      );

      // Refresh swaps list
      await refreshSwaps();

      return result;
    } catch (e) {
      logger.e('Error creating EVM to Lightning swap: $e');
      rethrow;
    }
  }

  /// Get swap details by ID.
  Future<SwapInfo> getSwap(String swapId) async {
    logger.i('[LendaSwap Dart] getSwap called - swapId: $swapId');
    try {
      final swap = await lendaswap_api.lendaswapGetSwap(swapId: swapId);
      logger.i('[LendaSwap Dart] getSwap SUCCESS');
      logger.i('[LendaSwap Dart] swap.id: ${swap.id}');
      logger.i('[LendaSwap Dart] swap.status: ${swap.status}');
      logger.i('[LendaSwap Dart] swap.detailedStatus: ${swap.detailedStatus}');
      logger.i('[LendaSwap Dart] swap.canClaimGelato: ${swap.canClaimGelato}');
      logger.i('[LendaSwap Dart] swap.canClaimVhtlc: ${swap.canClaimVhtlc}');
      logger.i('[LendaSwap Dart] swap.canRefund: ${swap.canRefund}');
      logger.d('[LendaSwap Dart] refreshing swaps...');
      await refreshSwaps();
      return swap;
    } catch (e) {
      logger.e('[LendaSwap Dart] getSwap FAILED: $e');
      rethrow;
    }
  }

  /// Claim a completed swap via Gelato (gasless).
  Future<void> claimGelato(String swapId) async {
    logger.i('[LendaSwap Dart] claimGelato called - swapId: $swapId');
    try {
      logger.i('[LendaSwap Dart] calling lendaswapClaimGelato...');
      await lendaswap_api.lendaswapClaimGelato(swapId: swapId);
      logger.i('[LendaSwap Dart] claimGelato SUCCESS');
      logger.d('[LendaSwap Dart] refreshing swaps...');
      await refreshSwaps();
    } catch (e) {
      logger.e('[LendaSwap Dart] claimGelato FAILED: $e');
      rethrow;
    }
  }

  /// Claim VHTLC for an EVM to BTC swap.
  Future<String> claimVhtlc(String swapId) async {
    logger.i('[LendaSwap Dart] claimVhtlc called - swapId: $swapId');
    try {
      logger.i('[LendaSwap Dart] calling lendaswapClaimVhtlc...');
      final txid = await lendaswap_api.lendaswapClaimVhtlc(swapId: swapId);
      logger.i('[LendaSwap Dart] claimVhtlc SUCCESS - txid: $txid');
      logger.d('[LendaSwap Dart] refreshing swaps...');
      await refreshSwaps();
      return txid;
    } catch (e) {
      logger.e('[LendaSwap Dart] claimVhtlc FAILED: $e');
      rethrow;
    }
  }

  /// Refund a failed swap.
  Future<String> refundVhtlc(String swapId, String refundAddress) async {
    try {
      final txid = await lendaswap_api.lendaswapRefundVhtlc(
        swapId: swapId,
        refundAddress: refundAddress,
      );
      await refreshSwaps();
      return txid;
    } catch (e) {
      logger.e('Error refunding VHTLC: $e');
      rethrow;
    }
  }

  /// Recover swaps from server (after mnemonic restore).
  Future<List<SwapInfo>> recoverSwaps() async {
    logger.i('[LendaSwap Dart] recoverSwaps called');
    try {
      final swaps = await lendaswap_api.lendaswapRecoverSwaps();
      logger.i(
          '[LendaSwap Dart] recoverSwaps SUCCESS - recovered ${swaps.length} swaps');
      _swaps = swaps;
      notifyListeners();
      return swaps;
    } catch (e) {
      final errorStr = e.toString();
      if (_isParsingError(errorStr)) {
        logger.w('[LendaSwap Dart] Parsing error during recovery: $e');
        logger.w('[LendaSwap Dart] Attempting clear and recover...');
        await _handleParsingError();
        return _swaps;
      }
      logger.e('Error recovering swaps: $e');
      rethrow;
    }
  }

  /// Delete a swap from local storage.
  Future<void> deleteSwap(String swapId) async {
    try {
      await lendaswap_api.lendaswapDeleteSwap(swapId: swapId);
      await refreshSwaps();
    } catch (e) {
      logger.e('Error deleting swap: $e');
      rethrow;
    }
  }

  // Helper methods

  String _mapNetwork(String network) {
    switch (network.toLowerCase()) {
      case 'mainnet':
      case 'bitcoin':
        return 'bitcoin';
      case 'testnet':
      case 'testnet3':
        return 'testnet';
      case 'regtest':
        return 'regtest';
      default:
        return 'bitcoin';
    }
  }

  String _getApiUrl(String network) {
    // LendaSwap API is hosted at lendasat.com
    switch (network) {
      case 'bitcoin':
        return 'https://apilendaswap.lendasat.com';
      case 'testnet':
        return 'https://apilendaswap.lendasat.com'; // TODO: update when testnet available
      default:
        return 'https://apilendaswap.lendasat.com';
    }
  }

  String _getArkadeUrl(String network) {
    // TODO: Make these configurable
    switch (network) {
      case 'bitcoin':
        return 'https://arkade.computer';
      case 'testnet':
        return 'https://testnet.arkade.computer';
      default:
        return 'https://arkade.computer';
    }
  }
}

/// Extension for SwapInfo to provide convenient helper methods.
extension SwapInfoExtension on SwapInfo {
  /// Check if swap is BTC to EVM direction.
  bool get isBtcToEvm => direction == 'btc_to_evm';

  /// Check if swap is EVM to BTC direction.
  bool get isEvmToBtc => direction == 'evm_to_btc';

  /// Get the deposit address to show the user.
  String? get depositAddress {
    if (isBtcToEvm) {
      // For BTC->EVM, user needs to pay Lightning invoice or send to Arkade HTLC
      return lnInvoice ?? arkadeHtlcAddress;
    } else {
      // For EVM->BTC, user needs to deposit to EVM HTLC
      return evmHtlcAddress;
    }
  }

  /// Check if swap can be claimed (using model fields from Rust).
  /// For BTC→EVM: canClaimGelato
  /// For EVM→BTC: canClaimVhtlc
  bool get canClaim => canClaimGelato || canClaimVhtlc;

  /// Check if swap is completed.
  bool get isCompleted {
    return status == SwapStatusSimple.completed;
  }

  /// Check if swap is pending/waiting.
  bool get isPending {
    return status == SwapStatusSimple.waitingForDeposit;
  }

  /// Get status display text.
  String get statusText {
    switch (status) {
      case SwapStatusSimple.waitingForDeposit:
        return 'Waiting for deposit';
      case SwapStatusSimple.processing:
        return 'Processing';
      case SwapStatusSimple.completed:
        return 'Completed';
      case SwapStatusSimple.expired:
        return 'Expired';
      case SwapStatusSimple.refundable:
        return 'Refundable';
      case SwapStatusSimple.refunded:
        return 'Refunded';
      case SwapStatusSimple.failed:
        return 'Failed';
    }
  }

  /// Get BTC amount in standard units (not sats).
  double get btcAmount =>
      sourceAmountSats.toInt() / BitcoinConstants.satsPerBtc;
}

/// Extension for TradingPair to provide convenient helper methods.
extension TradingPairExtension on lendaswap_api.TradingPair {
  /// Get display name for the trading pair.
  String get displayName => '${source.symbol}/${target.symbol}';

  /// Check if this is a BTC source pair.
  bool get isBtcSource =>
      source.tokenId == 'btc_arkade' || source.tokenId == 'btc_lightning';

  /// Check if this is a stablecoin source pair.
  bool get isStablecoinSource => !isBtcSource;
}
