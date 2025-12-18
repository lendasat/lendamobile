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

      // Load existing swaps
      await refreshSwaps();
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
    try {
      _swaps = await lendaswap_api.lendaswapListSwaps();
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching swaps: $e');
      rethrow;
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

  /// Create a BTC to EVM swap (sell BTC for stablecoins).
  Future<lendaswap_api.BtcToEvmSwapResult> createSellBtcSwap({
    required String targetEvmAddress,
    required double targetAmountUsd,
    required String targetToken,
    required String targetChain,
    String? referralCode,
  }) async {
    try {
      final result = await lendaswap_api.lendaswapCreateBtcToEvmSwap(
        targetEvmAddress: targetEvmAddress,
        targetAmountUsd: targetAmountUsd,
        targetToken: targetToken,
        targetChain: targetChain,
        referralCode: referralCode,
      );

      // Refresh swaps list
      await refreshSwaps();

      return result;
    } catch (e) {
      logger.e('Error creating BTC to EVM swap: $e');
      rethrow;
    }
  }

  /// Create an EVM to BTC swap (buy BTC with stablecoins).
  Future<lendaswap_api.EvmToBtcSwapResult> createBuyBtcSwap({
    required String targetArkAddress,
    required String userEvmAddress,
    required double sourceAmountUsd,
    required String sourceToken,
    required String sourceChain,
    String? referralCode,
  }) async {
    try {
      final result = await lendaswap_api.lendaswapCreateEvmToBtcSwap(
        targetArkAddress: targetArkAddress,
        userEvmAddress: userEvmAddress,
        sourceAmountUsd: sourceAmountUsd,
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
    try {
      final swap = await lendaswap_api.lendaswapGetSwap(swapId: swapId);
      await refreshSwaps();
      return swap;
    } catch (e) {
      logger.e('Error getting swap: $e');
      rethrow;
    }
  }

  /// Claim a completed swap via Gelato (gasless).
  Future<void> claimGelato(String swapId) async {
    try {
      await lendaswap_api.lendaswapClaimGelato(swapId: swapId);
      await refreshSwaps();
    } catch (e) {
      logger.e('Error claiming via Gelato: $e');
      rethrow;
    }
  }

  /// Claim VHTLC for an EVM to BTC swap.
  Future<String> claimVhtlc(String swapId) async {
    try {
      final txid = await lendaswap_api.lendaswapClaimVhtlc(swapId: swapId);
      await refreshSwaps();
      return txid;
    } catch (e) {
      logger.e('Error claiming VHTLC: $e');
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
    try {
      final swaps = await lendaswap_api.lendaswapRecoverSwaps();
      _swaps = swaps;
      notifyListeners();
      return swaps;
    } catch (e) {
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
  double get btcAmount => sourceAmountSats.toInt() / 100000000.0;
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
