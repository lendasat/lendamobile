import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/moonpay_service.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/utility/amount_widget.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as rust_api;
import 'package:ark_flutter/src/rust/models/moonpay.dart';
import 'payment_methods_screen.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final TextEditingController _btcController = TextEditingController();
  final TextEditingController _satController = TextEditingController();
  final TextEditingController _currController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = true;
  String? _error;

  MoonPayQuote? _currentQuote;
  int _quoteTimer = 20;
  Timer? _timer;

  String _paymentMethodName = 'Credit or Debit Card';
  String _paymentMethodId = 'credit_debit_card';

  MoonPayCurrencyLimits? _limits;

  String? _walletAddress;

  bool _isProcessing = false;

  String _inputState = 'under';

  // Use fake price for now (matching dashboard_screen.dart pattern)
  final double _btcToUsdRate = 65000.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final addresses = await rust_api.address();
      _walletAddress = addresses.boarding;

      await Future.wait([_fetchLimits(), _fetchQuote()]);

      _startQuoteTimer();

      setState(() => _isLoading = false);
    } catch (e) {
      logger.e('Error initializing buy screen: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLimits() async {
    try {
      final limits = await MoonPayService().getCurrencyLimits(
        baseCurrencyCode: 'usd',
        paymentMethod: _paymentMethodId,
      );

      setState(() {
        _limits = limits;
      });
    } catch (e) {
      logger.e('Error fetching limits: $e');
      rethrow;
    }
  }

  Future<void> _fetchQuote() async {
    try {
      final quote = await MoonPayService().getQuote();

      setState(() {
        _currentQuote = quote;
      });
    } catch (e) {
      logger.e('Error fetching quote: $e');
      rethrow;
    }
  }

  void _startQuoteTimer() {
    _timer?.cancel();
    _quoteTimer = 20;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_quoteTimer > 0) {
        setState(() => _quoteTimer--);
      } else {
        _fetchQuote();
        _quoteTimer = 20;
      }
    });
  }

  Future<void> _refreshQuote() async {
    await _fetchQuote();
    _startQuoteTimer();
  }

  bool _isValidAmount() {
    return _inputState == 'in' &&
        (_btcController.text.isNotEmpty || _satController.text.isNotEmpty);
  }

  Future<void> _processPurchase() async {
    if (!_isValidAmount() || _walletAddress == null) return;

    try {
      setState(() => _isProcessing = true);

      final sats = int.parse(_satController.text);
      final btcAmount = sats / 100000000.0;

      final queryParams = {
        'quoteCurrencyAmount': btcAmount.toString(),
        'baseCurrencyCode': 'usd',
        'walletAddress': _walletAddress!,
        'paymentMethod': _paymentMethodId,
      };

      final encryptedData = await MoonPayService().encryptData(queryParams);

      final settingsService = SettingsService();
      final websiteUrl = await settingsService.getWebsiteUrl();

      final websiteUri = Uri.parse(websiteUrl);
      final moonpayUrl = Uri(
        scheme: websiteUri.scheme,
        host: websiteUri.host,
        port: websiteUri.port,
        path: '/moonpay_onramp',
        queryParameters: {
          'data': encryptedData.ciphertext,
          'value': encryptedData.iv,
        },
      );

      logger.i('Launching MoonPay: $moonpayUrl');

      try {
        await launchUrl(
          moonpayUrl,
          customTabsOptions: CustomTabsOptions(
            colorSchemes: CustomTabsColorSchemes.defaults(
              toolbarColor: const Color(0xFF121212),
            ),
            shareState: CustomTabsShareState.on,
            urlBarHidingEnabled: true,
            showTitle: false,
          ),
          safariVCOptions: const SafariViewControllerOptions(
            preferredBarTintColor: Color(0xFF121212),
            preferredControlTintColor: Color(0xFFFFFFFF),
            barCollapsingEnabled: true,
            dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
            entersReaderIfAvailable: false,
          ),
        );
      } catch (e) {
        throw Exception('Could not launch MoonPay: $e');
      }
    } catch (e) {
      logger.e('Error processing purchase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch MoonPay: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _btcController.dispose();
    _satController.dispose();
    _currController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Buy Bitcoin',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton(
              onPressed: _refreshQuote,
              child: Text(
                '0:${_quoteTimer.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading buy screen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initialize,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAmountInput(),
                          const SizedBox(height: 24),
                          _buildPaymentMethodTile(),
                          const SizedBox(height: 16),
                          _buildProviderTile(),
                          const SizedBox(height: 24),
                          if (_limits != null) _buildLimitsInfo(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          border: Border(
                            top: BorderSide(
                              color: const Color(0xFFFFFFFF).withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isValidAmount() && !_isProcessing
                                ? Colors.blue
                                : Colors.grey[800],
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: _isValidAmount() && !_isProcessing
                              ? _processPurchase
                              : null,
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Buy Bitcoin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAmountInput() {
    if (_limits == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFFFFFFFF).withOpacity(0.1),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final minSats = (_limits!.quoteCurrency.minBuyAmount * 100000000).toInt();
    final maxSats = (_limits!.quoteCurrency.maxBuyAmount * 100000000).toInt();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16.0),
          AmountWidget(
            enabled: () => true,
            btcController: _btcController,
            satController: _satController,
            currController: _currController,
            focusNode: _focusNode,
            bitcoinUnit: CurrencyType.bitcoin,
            swapped: false,
            autoConvert: true,
            lowerBound: minSats,
            upperBound: maxSats,
            boundType: CurrencyType.sats,
            bitcoinPrice: _btcToUsdRate,
            underBoundFunc: (val) {
              setState(() {
                _inputState = 'under';
              });
            },
            inBoundFunc: (val) {
              setState(() {
                _inputState = 'in';
              });
            },
            overBoundFunc: (val) {
              setState(() {
                _inputState = 'over';
              });
            },
            onInputStateChange: (state) {},
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.credit_card, color: Colors.white),
        title: Text(
          _paymentMethodName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[600],
          size: 16,
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentMethodsScreen(),
            ),
          );
          if (result != null && result is Map<String, String>) {
            setState(() {
              _paymentMethodName = result['name']!;
              _paymentMethodId = result['id']!;
            });
            await _fetchLimits();
          }
        },
      ),
    );
  }

  Widget _buildProviderTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withOpacity(0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Center(
            child: Text(
              'M',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: const Text(
          'MoonPay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: _currentQuote != null
            ? Text(
                _currentQuote!.pricePerBtc,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              )
            : const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
      ),
    );
  }

  Widget _buildLimitsInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buy Limits',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Min: ${_limits!.quoteCurrency.minBuyAmount.toStringAsFixed(8)} BTC',
            style: TextStyle(
              color: const Color(0xFFFFFFFF).withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          Text(
            'Max: ${_limits!.quoteCurrency.maxBuyAmount.toStringAsFixed(8)} BTC',
            style: TextStyle(
              color: const Color(0xFFFFFFFF).withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
