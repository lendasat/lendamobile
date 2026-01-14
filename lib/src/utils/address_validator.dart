import 'package:ark_flutter/src/services/lnurl_service.dart';

/// Result of address validation
class AddressValidationResult {
  final bool isValid;
  final String? error;
  final PaymentAddressType? type;

  const AddressValidationResult._({
    required this.isValid,
    this.error,
    this.type,
  });

  factory AddressValidationResult.valid(PaymentAddressType type) {
    return AddressValidationResult._(isValid: true, type: type);
  }

  factory AddressValidationResult.invalid(String error) {
    return AddressValidationResult._(isValid: false, error: error);
  }

  factory AddressValidationResult.empty() {
    return const AddressValidationResult._(isValid: false);
  }
}

/// Types of supported payment addresses
enum PaymentAddressType {
  bitcoinMainnet,
  bitcoinTestnet,
  bech32,
  bech32Testnet,
  ark,
  arkTestnet,
  lightningInvoice,
  lightningAddress,
  lnurl,
  bip21,
  bip21WithLightning,
}

/// Validates Bitcoin, Lightning, and Ark addresses
class AddressValidator {
  // Base58 character set (excludes 0, O, I, l - easily confused)
  static const _base58Chars = r'[1-9A-HJ-NP-Za-km-z]';

  // Regex patterns
  static final _p2pkhPattern = RegExp('^1$_base58Chars{25,34}\$');
  static final _p2shPattern = RegExp('^3$_base58Chars{25,34}\$');
  static final _bech32Pattern = RegExp(r'^bc1[a-z0-9]{39,59}$');
  static final _bech32TestnetPattern = RegExp(r'^tb1[a-z0-9]{39,59}$');
  static final _testnetP2pkhPattern = RegExp('^[mn]$_base58Chars{25,34}\$');
  static final _testnetP2shPattern = RegExp('^2$_base58Chars{25,34}\$');
  static final _lightningInvoicePattern = RegExp(
    r'^ln(bc|tb|tbs)[a-z0-9]+[0-9]{1,}[a-z0-9]*$',
    caseSensitive: false,
  );
  static final _lightningAddressPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final _arkMainnetPattern = RegExp(r'^ark1[a-z0-9]{20,}$');
  static final _arkTestnetPattern = RegExp(r'^tark1[a-z0-9]{20,}$');

  /// Validate an address and return detailed result
  static AddressValidationResult validate(String address) {
    if (address.isEmpty) {
      return AddressValidationResult.empty();
    }

    final trimmed = address.trim();
    final lower = trimmed.toLowerCase();

    // BIP21 URI (bitcoin:address?params)
    if (lower.startsWith('bitcoin:')) {
      return _validateBip21(trimmed);
    }

    // Lightning URI (lightning:invoice)
    if (lower.startsWith('lightning:')) {
      final invoice = trimmed.substring(10);
      if (invoice.length < 15) {
        return AddressValidationResult.invalid('Invalid Lightning URI');
      }
      return validate(invoice); // Recursively validate the invoice part
    }

    // BOLT11 Lightning invoices
    if (_isLightningInvoice(lower)) {
      if (trimmed.length >= 50) {
        return AddressValidationResult.valid(
            PaymentAddressType.lightningInvoice);
      }
      return AddressValidationResult.invalid('Lightning invoice too short');
    }

    // LNURL
    if (LnurlService.isLnurl(trimmed)) {
      if (trimmed.length >= 20) {
        return AddressValidationResult.valid(PaymentAddressType.lnurl);
      }
      return AddressValidationResult.invalid('Invalid LNURL');
    }

    // Lightning Address (user@domain.com)
    if (LnurlService.isLightningAddress(trimmed) ||
        _lightningAddressPattern.hasMatch(trimmed)) {
      return AddressValidationResult.valid(PaymentAddressType.lightningAddress);
    }

    // Ark mainnet (ark1...) - may have query params like ?amount=
    if (lower.startsWith('ark1')) {
      final addressPart = lower.contains('?') ? lower.split('?').first : lower;
      if (_arkMainnetPattern.hasMatch(addressPart)) {
        return AddressValidationResult.valid(PaymentAddressType.ark);
      }
      return AddressValidationResult.invalid('Invalid Ark address');
    }

    // Ark testnet (tark1...) - may have query params like ?amount=
    if (lower.startsWith('tark1')) {
      final addressPart = lower.contains('?') ? lower.split('?').first : lower;
      if (_arkTestnetPattern.hasMatch(addressPart)) {
        return AddressValidationResult.valid(PaymentAddressType.arkTestnet);
      }
      return AddressValidationResult.invalid('Invalid Ark testnet address');
    }

    // Bitcoin mainnet P2PKH (starts with 1)
    if (trimmed.startsWith('1')) {
      if (_p2pkhPattern.hasMatch(trimmed)) {
        return AddressValidationResult.valid(PaymentAddressType.bitcoinMainnet);
      }
      return AddressValidationResult.invalid('Invalid P2PKH address');
    }

    // Bitcoin mainnet P2SH (starts with 3)
    if (trimmed.startsWith('3')) {
      if (_p2shPattern.hasMatch(trimmed)) {
        return AddressValidationResult.valid(PaymentAddressType.bitcoinMainnet);
      }
      return AddressValidationResult.invalid('Invalid P2SH address');
    }

    // Bitcoin mainnet Bech32 (starts with bc1)
    if (lower.startsWith('bc1')) {
      if (_bech32Pattern.hasMatch(lower)) {
        return AddressValidationResult.valid(PaymentAddressType.bech32);
      }
      return AddressValidationResult.invalid('Invalid Bech32 address');
    }

    // Bitcoin testnet Bech32 (starts with tb1)
    if (lower.startsWith('tb1')) {
      if (_bech32TestnetPattern.hasMatch(lower)) {
        return AddressValidationResult.valid(PaymentAddressType.bech32Testnet);
      }
      return AddressValidationResult.invalid('Invalid testnet Bech32 address');
    }

    // Bitcoin testnet P2PKH (starts with m or n)
    if (trimmed.startsWith('m') || trimmed.startsWith('n')) {
      if (_testnetP2pkhPattern.hasMatch(trimmed)) {
        return AddressValidationResult.valid(PaymentAddressType.bitcoinTestnet);
      }
      return AddressValidationResult.invalid('Invalid testnet P2PKH address');
    }

    // Bitcoin testnet P2SH (starts with 2)
    if (trimmed.startsWith('2')) {
      if (_testnetP2shPattern.hasMatch(trimmed)) {
        return AddressValidationResult.valid(PaymentAddressType.bitcoinTestnet);
      }
      return AddressValidationResult.invalid('Invalid testnet P2SH address');
    }

    // Unrecognized format
    return AddressValidationResult.invalid('Unsupported address format');
  }

  /// Validate BIP21 URI
  static AddressValidationResult _validateBip21(String uri) {
    try {
      final parsed = Uri.tryParse(uri);
      if (parsed == null) {
        return AddressValidationResult.invalid('Invalid Bitcoin URI');
      }

      // Check for lightning parameter (BIP21 with BOLT11)
      final lightningParam = parsed.queryParameters['lightning'];
      if (lightningParam != null) {
        if (_isLightningInvoice(lightningParam.toLowerCase())) {
          return AddressValidationResult.valid(
              PaymentAddressType.bip21WithLightning);
        }
      }

      // Check for ark/arkade parameter
      final arkParam =
          parsed.queryParameters['ark'] ?? parsed.queryParameters['arkade'];
      if (arkParam != null) {
        final arkResult = validate(arkParam);
        if (arkResult.isValid) {
          return AddressValidationResult.valid(PaymentAddressType.bip21);
        }
      }

      // Validate the bitcoin address in the path
      final bitcoinAddress = parsed.path;
      if (bitcoinAddress.isNotEmpty) {
        final addressResult = validate(bitcoinAddress);
        if (addressResult.isValid) {
          return AddressValidationResult.valid(PaymentAddressType.bip21);
        }
        return AddressValidationResult.invalid(
            'Invalid address in Bitcoin URI');
      }

      return AddressValidationResult.invalid('Bitcoin URI missing address');
    } catch (e) {
      return AddressValidationResult.invalid('Invalid Bitcoin URI format');
    }
  }

  /// Check if string is a Lightning invoice (BOLT11)
  static bool _isLightningInvoice(String lower) {
    return lower.startsWith('lnbc') ||
        lower.startsWith('lntb') ||
        lower.startsWith('lntbs') ||
        lower.startsWith('lnbcrt');
  }

  /// Quick check if address is valid (convenience method)
  static bool isValid(String address) => validate(address).isValid;

  /// Check if address is on-chain Bitcoin (not Lightning, not Ark)
  static bool isOnChainBitcoin(String address) {
    final result = validate(address);
    if (!result.isValid) return false;

    switch (result.type) {
      case PaymentAddressType.bitcoinMainnet:
      case PaymentAddressType.bitcoinTestnet:
      case PaymentAddressType.bech32:
      case PaymentAddressType.bech32Testnet:
        return true;
      case PaymentAddressType.bip21:
        // BIP21 could be on-chain, need to check the actual address
        final uri = Uri.tryParse(address);
        if (uri != null) {
          // If it has ark or lightning param, it's not purely on-chain
          if (uri.queryParameters.containsKey('ark') ||
              uri.queryParameters.containsKey('arkade') ||
              uri.queryParameters.containsKey('lightning')) {
            return false;
          }
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  /// Check if address is a Lightning payment (invoice, LNURL, or Lightning Address)
  static bool isLightning(String address) {
    final result = validate(address);
    if (!result.isValid) return false;

    return result.type == PaymentAddressType.lightningInvoice ||
        result.type == PaymentAddressType.lightningAddress ||
        result.type == PaymentAddressType.lnurl ||
        result.type == PaymentAddressType.bip21WithLightning;
  }

  /// Check if address is an Ark address
  static bool isArk(String address) {
    final result = validate(address);
    return result.isValid &&
        (result.type == PaymentAddressType.ark ||
            result.type == PaymentAddressType.arkTestnet);
  }
}
