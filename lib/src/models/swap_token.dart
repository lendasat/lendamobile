import 'package:flutter/material.dart';

/// Supported tokens for LendaSwap
enum SwapToken {
  // Bitcoin (uses Arkade under the hood)
  bitcoin,
  // Polygon
  usdcPolygon,
  usdtPolygon,
  // Ethereum
  usdcEthereum,
  usdtEthereum,
  xautEthereum,
}

extension SwapTokenExtension on SwapToken {
  /// Get the API token ID string
  String get tokenId {
    switch (this) {
      case SwapToken.bitcoin:
        return 'btc_arkade'; // Always use Arkade for BTC swaps
      case SwapToken.usdcPolygon:
        return 'usdc_pol';
      case SwapToken.usdtPolygon:
        return 'usdt0_pol';
      case SwapToken.usdcEthereum:
        return 'usdc_eth';
      case SwapToken.usdtEthereum:
        return 'usdt_eth';
      case SwapToken.xautEthereum:
        return 'xaut_eth';
    }
  }

  /// Get display symbol
  String get symbol {
    switch (this) {
      case SwapToken.bitcoin:
        return 'BTC';
      case SwapToken.usdcPolygon:
      case SwapToken.usdcEthereum:
        return 'USDC';
      case SwapToken.usdtPolygon:
      case SwapToken.usdtEthereum:
        return 'USDT';
      case SwapToken.xautEthereum:
        return 'XAUt'; // Official Tether Gold symbol
    }
  }

  /// Get full display name
  String get displayName {
    switch (this) {
      case SwapToken.bitcoin:
        return 'Bitcoin';
      case SwapToken.usdcPolygon:
        return 'USDC (Polygon)';
      case SwapToken.usdtPolygon:
        return 'USDT (Polygon)';
      case SwapToken.usdcEthereum:
        return 'USDC (Ethereum)';
      case SwapToken.usdtEthereum:
        return 'USDT (Ethereum)';
      case SwapToken.xautEthereum:
        return 'XAUt (Ethereum)';
    }
  }

  /// Get network name
  String get network {
    switch (this) {
      case SwapToken.bitcoin:
        return 'Bitcoin';
      case SwapToken.usdcPolygon:
      case SwapToken.usdtPolygon:
        return 'Polygon';
      case SwapToken.usdcEthereum:
      case SwapToken.usdtEthereum:
      case SwapToken.xautEthereum:
        return 'Ethereum';
    }
  }

  /// Get chain ID for API calls
  String get chainId {
    switch (this) {
      case SwapToken.bitcoin:
        return 'bitcoin';
      case SwapToken.usdcPolygon:
      case SwapToken.usdtPolygon:
        return 'polygon';
      case SwapToken.usdcEthereum:
      case SwapToken.usdtEthereum:
      case SwapToken.xautEthereum:
        return 'ethereum';
    }
  }

  /// Check if this is a BTC token
  bool get isBtc => this == SwapToken.bitcoin;

  /// Check if this is an EVM token
  bool get isEvm => !isBtc;

  /// Check if this is a stablecoin (USD-pegged)
  bool get isStablecoin {
    switch (this) {
      case SwapToken.bitcoin:
      case SwapToken.xautEthereum:
        return false;
      case SwapToken.usdcPolygon:
      case SwapToken.usdtPolygon:
      case SwapToken.usdcEthereum:
      case SwapToken.usdtEthereum:
        return true;
    }
  }

  /// Get token decimals
  int get decimals {
    switch (this) {
      case SwapToken.bitcoin:
        return 8; // satoshis
      case SwapToken.usdcPolygon:
      case SwapToken.usdcEthereum:
        return 6;
      case SwapToken.usdtPolygon:
      case SwapToken.usdtEthereum:
        return 6;
      case SwapToken.xautEthereum:
        return 6;
    }
  }

  /// Get primary color for the token
  Color get color {
    switch (this) {
      case SwapToken.bitcoin:
        return const Color(0xFFF7931A); // Bitcoin orange
      case SwapToken.usdcPolygon:
      case SwapToken.usdcEthereum:
        return const Color(0xFF2775CA); // USDC blue
      case SwapToken.usdtPolygon:
      case SwapToken.usdtEthereum:
        return const Color(0xFF26A17B); // USDT green
      case SwapToken.xautEthereum:
        return const Color(0xFFD4AF37); // Gold
    }
  }

  /// Get network color
  Color get networkColor {
    switch (this) {
      case SwapToken.bitcoin:
        return const Color(0xFFF7931A); // Bitcoin orange
      case SwapToken.usdcPolygon:
      case SwapToken.usdtPolygon:
        return const Color(0xFF8247E5); // Polygon purple
      case SwapToken.usdcEthereum:
      case SwapToken.usdtEthereum:
      case SwapToken.xautEthereum:
        return const Color(0xFF627EEA); // Ethereum blue
    }
  }

  /// Get the icon for the token
  IconData get icon {
    switch (this) {
      case SwapToken.bitcoin:
        return Icons.currency_bitcoin;
      case SwapToken.usdcPolygon:
      case SwapToken.usdcEthereum:
        return Icons.attach_money;
      case SwapToken.usdtPolygon:
      case SwapToken.usdtEthereum:
        return Icons.attach_money;
      case SwapToken.xautEthereum:
        return Icons.diamond;
    }
  }

  /// Get network icon
  IconData get networkIcon {
    switch (this) {
      case SwapToken.bitcoin:
        return Icons.currency_bitcoin;
      case SwapToken.usdcPolygon:
      case SwapToken.usdtPolygon:
        return Icons.hexagon;
      case SwapToken.usdcEthereum:
      case SwapToken.usdtEthereum:
      case SwapToken.xautEthereum:
        return Icons.diamond_outlined;
    }
  }

  /// Parse from token ID string
  static SwapToken? fromTokenId(String tokenId) {
    switch (tokenId.toLowerCase()) {
      case 'btc_arkade':
      case 'btc_lightning':
        return SwapToken.bitcoin;
      case 'usdc_pol':
        return SwapToken.usdcPolygon;
      case 'usdt0_pol':
      case 'usdt_pol':
        return SwapToken.usdtPolygon;
      case 'usdc_eth':
        return SwapToken.usdcEthereum;
      case 'usdt_eth':
        return SwapToken.usdtEthereum;
      case 'xaut_eth':
        return SwapToken.xautEthereum;
      default:
        return null;
    }
  }

  /// Get all BTC tokens (just Bitcoin now)
  static List<SwapToken> get btcTokens => [SwapToken.bitcoin];

  /// Get all EVM tokens
  static List<SwapToken> get evmTokens => [
        SwapToken.usdcPolygon,
        SwapToken.usdtPolygon,
        SwapToken.usdcEthereum,
        SwapToken.usdtEthereum,
        SwapToken.xautEthereum,
      ];

  /// Get all tokens
  static List<SwapToken> get allTokens => SwapToken.values;

  /// Get valid target tokens for a given source token
  static List<SwapToken> getValidTargets(SwapToken source) {
    if (source.isBtc) {
      // BTC can only swap to EVM tokens
      return evmTokens;
    } else {
      // EVM tokens can only swap to BTC
      return btcTokens;
    }
  }
}
