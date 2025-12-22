import 'package:flutter/material.dart';

/// Supported tokens for LendaSwap
///
/// Polygon tokens support Gelato gasless claiming.
/// Ethereum tokens require WalletConnect for users to pay gas fees when claiming.
enum SwapToken {
  // Bitcoin (uses Arkade under the hood)
  bitcoin,
  // Polygon (supports Gelato gasless swaps)
  usdcPolygon,
  usdtPolygon,
  // Ethereum (requires WalletConnect for gas fees when claiming)
  usdcEthereum,
  usdtEthereum,
  xautEthereum;

  // --- Static Methods & Getters ---

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

  /// Get all Polygon stablecoins (gasless claiming supported)
  static List<SwapToken> get polygonTokens => [
        SwapToken.usdcPolygon,
        SwapToken.usdtPolygon,
      ];

  /// Get all EVM tokens
  static List<SwapToken> get evmTokens => [
        SwapToken.usdcPolygon,
        SwapToken.usdtPolygon,
        SwapToken.usdcEthereum,
        SwapToken.usdtEthereum,
        SwapToken.xautEthereum,
      ];

  /// Get all tokens available for swapping
  static List<SwapToken> get allTokens => [
        SwapToken.bitcoin,
        ...evmTokens,
      ];

  /// Get valid target tokens for a given source token
  static List<SwapToken> getValidTargets(SwapToken source) {
    if (source.isBtc) {
      // For first release, only support Polygon stablecoins (gasless claiming)
      return polygonTokens;
    } else {
      // EVM -> BTC disabled for first release
      return [];
    }
  }

  // --- Instance Methods & Getters ---

  /// Get the API token ID string
  String get tokenId {
    switch (this) {
      case SwapToken.bitcoin:
        return 'btc_arkade';
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
        return 'USDT0';
      case SwapToken.usdtEthereum:
        return 'USDT';
      case SwapToken.xautEthereum:
        return 'XAUt';
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
        return 'USDT0 (Polygon)';
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
        return 8;
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
        return const Color(0xFFF7931A);
      case SwapToken.usdcPolygon:
      case SwapToken.usdcEthereum:
        return const Color(0xFF2775CA);
      case SwapToken.usdtPolygon:
      case SwapToken.usdtEthereum:
        return const Color(0xFF26A17B);
      case SwapToken.xautEthereum:
        return const Color(0xFFD4AF37);
    }
  }

  /// Get network color
  Color get networkColor {
    switch (this) {
      case SwapToken.bitcoin:
        return const Color(0xFFF7931A);
      case SwapToken.usdcPolygon:
      case SwapToken.usdtPolygon:
        return const Color(0xFF8247E5);
      case SwapToken.usdcEthereum:
      case SwapToken.usdtEthereum:
      case SwapToken.xautEthereum:
        return const Color(0xFF627EEA);
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
}
