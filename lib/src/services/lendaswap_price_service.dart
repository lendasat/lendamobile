import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ark_flutter/src/logger/logger.dart';

/// Price tiers for different swap amounts.
/// Higher amounts get better rates (lower spread).
class PriceTiers {
  final double tier1;
  final double tier100;
  final double tier1000;
  final double tier5000;

  const PriceTiers({
    required this.tier1,
    required this.tier100,
    required this.tier1000,
    required this.tier5000,
  });

  factory PriceTiers.fromJson(Map<String, dynamic> json) {
    return PriceTiers(
      tier1: (json['tier_1'] as num).toDouble(),
      tier100: (json['tier_100'] as num).toDouble(),
      tier1000: (json['tier_1000'] as num).toDouble(),
      tier5000: (json['tier_5000'] as num).toDouble(),
    );
  }

  /// Select the appropriate tier rate based on the asset amount.
  double selectTier(double assetAmount) {
    if (assetAmount >= 5000) return tier5000;
    if (assetAmount >= 1000) return tier1000;
    if (assetAmount >= 100) return tier100;
    return tier1;
  }
}

/// Trading pair prices with volume-based tiers.
class TradingPairPrices {
  final String pair;
  final String source;
  final String target;
  final PriceTiers tiers;

  const TradingPairPrices({
    required this.pair,
    required this.source,
    required this.target,
    required this.tiers,
  });

  factory TradingPairPrices.fromJson(Map<String, dynamic> json) {
    return TradingPairPrices(
      pair: json['pair'] as String,
      source: json['source'] as String,
      target: json['target'] as String,
      tiers: PriceTiers.fromJson(json['tiers'] as Map<String, dynamic>),
    );
  }
}

/// Price update message from WebSocket.
class PriceUpdateMessage {
  final int timestamp;
  final List<TradingPairPrices> pairs;

  const PriceUpdateMessage({
    required this.timestamp,
    required this.pairs,
  });

  factory PriceUpdateMessage.fromJson(Map<String, dynamic> json) {
    return PriceUpdateMessage(
      timestamp: json['timestamp'] as int,
      pairs: (json['pairs'] as List)
          .map((p) => TradingPairPrices.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Find a trading pair by source and target token IDs.
  TradingPairPrices? findPair(String sourceToken, String targetToken) {
    for (final pair in pairs) {
      if (pair.source == sourceToken && pair.target == targetToken) {
        return pair;
      }
    }
    return null;
  }
}

/// WebSocket price feed service for real-time price updates.
///
/// Connects to the LendaSwap API's `/ws/prices` endpoint and provides
/// real-time price updates with automatic reconnection.
class LendaswapPriceFeedService {
  static final LendaswapPriceFeedService _instance =
      LendaswapPriceFeedService._internal();
  factory LendaswapPriceFeedService() => _instance;
  LendaswapPriceFeedService._internal();

  static const String _wsUrl = 'wss://lendaswap.lendasat.com/ws/prices';

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final _priceController = StreamController<PriceUpdateMessage>.broadcast();

  PriceUpdateMessage? _latestPrices;
  bool _isConnected = false;
  bool _isManualClose = false;
  int _reconnectDelay = 1000; // Start with 1 second
  static const int _maxReconnectDelay = 30000; // Max 30 seconds

  /// Stream of price updates.
  Stream<PriceUpdateMessage> get priceUpdates => _priceController.stream;

  /// Latest cached prices.
  PriceUpdateMessage? get latestPrices => _latestPrices;

  /// Whether the WebSocket is connected.
  bool get isConnected => _isConnected;

  /// Connect to the price feed.
  void connect() {
    if (_isConnected) return;

    _isManualClose = false;
    _connectWebSocket();
  }

  /// Disconnect from the price feed.
  void disconnect() {
    _isManualClose = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void _connectWebSocket() {
    try {
      logger.i('[PriceFeed] Connecting to $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _reconnectDelay = 1000; // Reset on successful connection
      logger.i('[PriceFeed] Connected');
    } catch (e) {
      logger.e('[PriceFeed] Failed to connect: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final update = PriceUpdateMessage.fromJson(json);
      _latestPrices = update;
      _priceController.add(update);
      logger.d(
          '[PriceFeed] Received price update with ${update.pairs.length} pairs');
    } catch (e) {
      logger.e('[PriceFeed] Failed to parse message: $e');
    }
  }

  void _onError(Object error) {
    logger.e('[PriceFeed] WebSocket error: $error');
  }

  void _onDone() {
    logger.w('[PriceFeed] WebSocket closed');
    _isConnected = false;
    _channel = null;

    if (!_isManualClose) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelay), () {
      logger.i('[PriceFeed] Attempting reconnection...');
      _connectWebSocket();
    });

    // Exponential backoff
    _reconnectDelay = (_reconnectDelay * 2).clamp(1000, _maxReconnectDelay);
  }

  /// Get the exchange rate for a token pair.
  ///
  /// Returns the rate as "1 source = X target".
  /// For BTC -> EVM swaps, this is the USD/token amount per BTC.
  /// For EVM -> BTC swaps, this is the BTC amount per USD/token.
  double? getExchangeRate({
    required String sourceToken,
    required String targetToken,
    double amount = 100,
  }) {
    if (_latestPrices == null) return null;

    final pair = _latestPrices!.findPair(sourceToken, targetToken);
    if (pair == null) {
      logger.w('[PriceFeed] No price found for $sourceToken -> $targetToken');
      return null;
    }

    final rate = pair.tiers.selectTier(amount);

    // Backend sends rates as "BTC per 1 token" for ALL pairs.
    // When source is BTC, we need to invert to get "token per 1 BTC".
    final isSourceBtc = sourceToken.contains('btc');
    final isTargetEvm = !targetToken.contains('btc');

    if (isSourceBtc && isTargetEvm) {
      return 1 / rate;
    }
    return rate;
  }

  /// Get the USD price for a token.
  ///
  /// For stablecoins, returns ~1.0.
  /// For XAUT, returns the gold price in USD.
  double? getTokenUsdPrice(String tokenId) {
    if (_latestPrices == null) {
      logger.w('[PriceFeed] No prices available yet');
      return null;
    }

    // For stablecoins, they're ~1:1 with USD
    if (tokenId.contains('usdc') || tokenId.contains('usdt')) {
      return 1.0;
    }

    // For XAUT, we need to calculate from BTC rate
    // Get XAUT/BTC rate and multiply by BTC/USD
    if (tokenId.contains('xaut')) {
      // Find XAUT -> BTC rate (BTC per 1 XAUT)
      final pair = _latestPrices!.findPair(tokenId, 'btc_arkade');
      if (pair == null) {
        logger.w('[PriceFeed] No XAUT -> BTC pair found for $tokenId');
        // Log available pairs for debugging
        final pairNames = _latestPrices!.pairs
            .map((p) => '${p.source}->${p.target}')
            .join(', ');
        logger.d('[PriceFeed] Available pairs: $pairNames');
        return null;
      }

      final btcPerXaut = pair.tiers.tier1;

      // We also need BTC/USD - get from USDC pair
      final usdcPair = _latestPrices!.findPair('btc_arkade', 'usdc_pol');
      if (usdcPair == null) {
        logger.w('[PriceFeed] No BTC -> USDC pair found');
        return null;
      }

      // This gives us BTC per 1 USDC, so invert to get USDC per BTC
      final usdPerBtc = 1 / usdcPair.tiers.tier1;

      // XAUT price = BTC per XAUT * USD per BTC
      final xautPrice = btcPerXaut * usdPerBtc;
      logger.d(
          '[PriceFeed] Calculated XAUT price: \$$xautPrice (btcPerXaut=$btcPerXaut, usdPerBtc=$usdPerBtc)');
      return xautPrice;
    }

    return null;
  }

  /// Dispose resources.
  void dispose() {
    disconnect();
    _priceController.close();
  }
}
