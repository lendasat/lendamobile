import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/utils/address_validator.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';

/// Result of parsing a payment address/URI
class ParsedAddress {
  /// The cleaned address to use for payment
  final String address;

  /// Amount in satoshis (if specified in the address/invoice)
  final int? amountSats;

  /// Available networks extracted from BIP21 URI
  final Map<String, String> availableNetworks;

  /// The best network to use (selected automatically)
  final String? selectedNetwork;

  /// Whether the amount is locked (from Lightning invoice)
  final bool isAmountLocked;

  /// Whether this is a zero-amount Lightning invoice (not supported)
  final bool isZeroAmountInvoice;

  /// Description/note from LNURL metadata
  final String? description;

  const ParsedAddress({
    required this.address,
    this.amountSats,
    this.availableNetworks = const {},
    this.selectedNetwork,
    this.isAmountLocked = false,
    this.isZeroAmountInvoice = false,
    this.description,
  });
}

/// Service for parsing various Bitcoin payment address formats
class AddressParserService {
  /// Parse a payment address/URI and extract all relevant information
  ///
  /// Supports:
  /// - BIP21 URIs (bitcoin:address?amount=X&lightning=invoice&ark=address)
  /// - Lightning invoices (lnbc...)
  /// - Lightning URIs (lightning:lnbc...)
  /// - Arkade addresses with query params (ark1...?amount=X)
  /// - Plain addresses (bitcoin, lightning, arkade)
  static ParsedAddress parse(String input) {
    final text = input.trim();

    // Handle Lightning URI (lightning:lnbc...)
    if (text.toLowerCase().startsWith('lightning:')) {
      return _parseLightningUri(text);
    }

    // Handle Arkade address with amount query param
    if (_isArkadeAddressWithAmount(text)) {
      return _parseArkadeWithAmount(text);
    }

    // Handle BIP21 URI
    if (text.toLowerCase().startsWith('bitcoin:')) {
      return _parseBip21Uri(text);
    }

    // Handle plain Lightning invoice
    if (isLightningInvoice(text)) {
      return _parseLightningInvoice(text);
    }

    // Plain address - no parsing needed
    return ParsedAddress(address: text);
  }

  /// Parse lightning: URI
  static ParsedAddress _parseLightningUri(String text) {
    final invoice = text.substring(10); // Remove 'lightning:'
    final invoiceResult = _parseLightningInvoice(invoice);

    return ParsedAddress(
      address: invoice,
      amountSats: invoiceResult.amountSats,
      availableNetworks: {'Lightning': invoice},
      selectedNetwork: 'Lightning',
      isAmountLocked: invoiceResult.isAmountLocked,
      isZeroAmountInvoice: invoiceResult.isZeroAmountInvoice,
    );
  }

  /// Parse Arkade address with query params (ark1...?amount=0.0001)
  static ParsedAddress _parseArkadeWithAmount(String text) {
    final parts = text.split('?');
    final address = parts[0];
    int? amountSats;

    if (parts.length > 1) {
      final params = Uri.splitQueryString(parts[1]);
      if (params.containsKey('amount')) {
        final btcAmount = double.tryParse(params['amount'] ?? '');
        if (btcAmount != null) {
          amountSats = (btcAmount * BitcoinConstants.satsPerBtc).round();
          logger.i('Extracted amount from Arkade address: $amountSats sats');
        }
      }
    }

    return ParsedAddress(
      address: address,
      amountSats: amountSats,
      availableNetworks: {'Arkade': address},
      selectedNetwork: 'Arkade',
    );
  }

  /// Parse BIP21 URI and extract all available networks
  static ParsedAddress _parseBip21Uri(String text) {
    final uri = Uri.tryParse(text);
    if (uri == null) {
      return ParsedAddress(address: text);
    }

    final networks = <String, String>{};
    int? amountSats;
    String? selectedAddress;
    String? selectedNetwork;

    // Extract all available addresses
    if (uri.path.isNotEmpty) {
      networks['Onchain'] = uri.path;
    }
    if (uri.queryParameters.containsKey('lightning')) {
      networks['Lightning'] = uri.queryParameters['lightning']!;
    }
    if (uri.queryParameters.containsKey('ark')) {
      networks['Arkade'] = uri.queryParameters['ark']!;
    } else if (uri.queryParameters.containsKey('arkade')) {
      networks['Arkade'] = uri.queryParameters['arkade']!;
    }

    // Priority order for address selection (lower fees first):
    // 1. Ark address (lowest fees)
    // 2. Lightning invoice
    // 3. Bitcoin address (highest fees)
    if (networks.containsKey('Arkade')) {
      selectedAddress = networks['Arkade']!;
      selectedNetwork = 'Arkade';
      logger.i('Using Ark address from BIP21 for lower fees');
    } else if (networks.containsKey('Lightning')) {
      selectedAddress = networks['Lightning']!;
      selectedNetwork = 'Lightning';
      logger.i('Using Lightning address from BIP21');
    } else if (networks.containsKey('Onchain')) {
      selectedAddress = networks['Onchain']!;
      selectedNetwork = 'Onchain';
    }

    // Parse amount from query parameters
    if (uri.queryParameters.containsKey('amount')) {
      final btcAmount = double.tryParse(uri.queryParameters['amount'] ?? '');
      if (btcAmount != null) {
        amountSats = (btcAmount * BitcoinConstants.satsPerBtc).round();
      }
    }

    // Check if Lightning invoice has amount (would override BIP21 amount)
    bool isAmountLocked = false;
    bool isZeroAmountInvoice = false;
    if (selectedNetwork == 'Lightning' && selectedAddress != null) {
      final invoiceResult = _parseLightningInvoice(selectedAddress);
      if (invoiceResult.amountSats != null) {
        amountSats = invoiceResult.amountSats;
        isAmountLocked = true;
      }
      isZeroAmountInvoice = invoiceResult.isZeroAmountInvoice;
    }

    return ParsedAddress(
      address: selectedAddress ?? text,
      amountSats: amountSats,
      availableNetworks: networks,
      selectedNetwork: selectedNetwork,
      isAmountLocked: isAmountLocked,
      isZeroAmountInvoice: isZeroAmountInvoice,
    );
  }

  /// Parse Lightning invoice amount
  static ParsedAddress _parseLightningInvoice(String invoice) {
    try {
      final decoded = Bolt11PaymentRequest(invoice);
      final btcAmount = decoded.amount.toDouble();

      if (btcAmount > 0) {
        final amountSats = (btcAmount * BitcoinConstants.satsPerBtc).round();
        logger.i('Extracted amount from Lightning invoice: $amountSats sats');
        return ParsedAddress(
          address: invoice,
          amountSats: amountSats,
          isAmountLocked: true,
        );
      } else {
        // Zero-amount invoice - NOT SUPPORTED by SDK
        logger.w('Zero-amount Lightning invoice detected - NOT SUPPORTED');
        return ParsedAddress(
          address: invoice,
          isZeroAmountInvoice: true,
        );
      }
    } catch (e) {
      // Parse error - return as-is
      return ParsedAddress(address: invoice);
    }
  }

  /// Check if address is a Lightning invoice (BOLT11)
  static bool isLightningInvoice(String address) {
    final result = AddressValidator.validate(address);
    return result.isValid && result.type == PaymentAddressType.lightningInvoice;
  }

  /// Check if address is an LNURL or Lightning Address
  static bool isLnurlOrLightningAddress(String address) {
    final result = AddressValidator.validate(address);
    return result.isValid &&
        (result.type == PaymentAddressType.lnurl ||
            result.type == PaymentAddressType.lightningAddress);
  }

  /// Check if address is an on-chain Bitcoin address
  static bool isOnChainBitcoinAddress(String address) {
    return AddressValidator.isOnChainBitcoin(address);
  }

  /// Check if text is an Arkade address with amount query param
  static bool _isArkadeAddressWithAmount(String text) {
    return (text.startsWith('ark1') || text.startsWith('tark1')) &&
        text.contains('?amount=');
  }

  /// Get the network name for a given address
  static String getNetworkName(String address) {
    if (isLightningInvoice(address) || isLnurlOrLightningAddress(address)) {
      return 'Lightning';
    } else if (isOnChainBitcoinAddress(address)) {
      return 'Onchain';
    } else if (AddressValidator.isValid(address)) {
      return 'Arkade';
    }
    return 'Unknown';
  }
}
