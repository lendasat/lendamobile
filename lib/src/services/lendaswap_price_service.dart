import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  // CoinGecko API for USD prices (same as web frontend)
  static const String _coingeckoUrl =
      'https://api.coingecko.com/api/v3/simple/price';
  static const Map<String, String> _tokenToCoinGecko = {
    'xaut_eth': 'tether-gold',
  };

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _coinGeckoTimer;
  final _priceController = StreamController<PriceUpdateMessage>.broadcast();

  PriceUpdateMessage? _latestPrices;
  bool _isConnected = false;
  bool _isManualClose = false;
  int _reconnectDelay = 1000; // Start with 1 second
  static const int _maxReconnectDelay = 30000; // Max 30 seconds

  // Cached CoinGecko prices
  final Map<String, double> _coinGeckoPrices = {};
  DateTime? _lastCoinGeckoFetch;

  // Stream for CoinGecko price updates (separate from WebSocket)
  final _coinGeckoController = StreamController<Map<String, double>>.broadcast();

  /// Stream of CoinGecko price updates.
  Stream<Map<String, double>> get coinGeckoPriceUpdates =>
      _coinGeckoController.stream;

  /// Stream of price updates.
  Stream<PriceUpdateMessage> get priceUpdates => _priceController.stream;

  /// Latest cached prices.
  PriceUpdateMessage? get latestPrices => _latestPrices;

  /// Whether the WebSocket is connected.
  bool get isConnected => _isConnected;

  /// Get cached XAUT USD price (from CoinGecko).
  double? get xautUsdPrice => _coinGeckoPrices['xaut_eth'];

  /// Connect to the price feed.
  void connect() {
    if (_isConnected) return;

    _isManualClose = false;
    _connectWebSocket();
    _startCoinGeckoPolling();
  }

  /// Disconnect from the price feed.
  void disconnect() {
    _isManualClose = true;
    _reconnectTimer?.cancel();
    _coinGeckoTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Start polling CoinGecko for USD prices.
  void _startCoinGeckoPolling() {
    // Fetch immediately
    _fetchCoinGeckoPrices();

    // Then poll every 60 seconds (same as web frontend)
    _coinGeckoTimer?.cancel();
    _coinGeckoTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchCoinGeckoPrices();
    });
  }

  /// Fetch USD prices from CoinGecko API.
  Future<void> _fetchCoinGeckoPrices() async {
    try {
      final coinGeckoIds = _tokenToCoinGecko.values.join(',');
      final url = '$_coingeckoUrl?ids=$coinGeckoIds&vs_currencies=usd';

      logger.d('[PriceFeed] Fetching CoinGecko prices: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Map CoinGecko IDs back to token IDs
        for (final entry in _tokenToCoinGecko.entries) {
          final tokenId = entry.key;
          final coinGeckoId = entry.value;
          final priceData = data[coinGeckoId] as Map<String, dynamic>?;
          if (priceData != null && priceData['usd'] != null) {
            final price = (priceData['usd'] as num).toDouble();
            _coinGeckoPrices[tokenId] = price;
            logger.i(
                '[PriceFeed] CoinGecko price for $tokenId: \$${price.toStringAsFixed(2)}');
          }
        }

        _lastCoinGeckoFetch = DateTime.now();

        // Emit CoinGecko price update to notify listeners
        _coinGeckoController.add(Map.from(_coinGeckoPrices));
      } else {
        logger.w(
            '[PriceFeed] CoinGecko API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      logger.e('[PriceFeed] Failed to fetch CoinGecko prices: $e');
    }
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
  /// For XAUT, returns the gold price from CoinGecko.
  double? getTokenUsdPrice(String tokenId) {
    // For stablecoins, they're ~1:1 with USD
    if (tokenId.contains('usdc') || tokenId.contains('usdt')) {
      return 1.0;
    }

    // For XAUT, use CoinGecko price (same as web frontend)
    if (tokenId.contains('xaut')) {
      final price = _coinGeckoPrices[tokenId];
      if (price == null) {
        logger.w('[PriceFeed] No CoinGecko price for $tokenId yet');
      }
      return price;
    }

    return null;
  }

  /// Dispose resources.
  void dispose() {
    disconnect();
    _priceController.close();
    _coinGeckoController.close();
  }
}
