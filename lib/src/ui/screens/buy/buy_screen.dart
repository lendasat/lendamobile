import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as rust_api;
import 'package:ark_flutter/src/rust/models/moonpay.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/src/services/moonpay_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/amount_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  // Provider state
  final String _providerName = 'MoonPay';
  final String _providerId = 'moonpay';

  MoonPayCurrencyLimits? _limits;

  String? _walletAddress;

  bool _isProcessing = false;

  String _inputState = 'under';
  int _allowedAmountDifference = 0;

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
            content: Text(
                '${AppLocalizations.of(context)!.failedToLaunchMoonpay}: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _getPaymentMethodIcon(String methodId) {
    switch (methodId) {
      case "credit_debit_card":
        return const Icon(Icons.wallet_rounded);
      case "google_pay":
        return const Icon(FontAwesomeIcons.google);
      case "apple_pay":
        return const Icon(FontAwesomeIcons.applePay, size: 32);
      case "paypal":
        return const Icon(FontAwesomeIcons.paypal, size: 32);
      case "stripe":
        return const Icon(FontAwesomeIcons.stripe, size: 32);
      case "sepa_bank_transfer":
        return const Icon(Icons.account_balance);
      default:
        return const Icon(Icons.payment);
    }
  }

  Widget _getProviderIcon(String providerId) {
    switch (providerId) {
      case "stripe":
        return Image.asset('assets/images/stripe.png', width: 32, height: 32);
      case "moonpay":
        return Image.asset('assets/images/moonpay.png', width: 32, height: 32);
      case "bringin":
        return Image.asset('assets/images/bringinxyz_logo.webp',
            width: 32, height: 32);
      default:
        return const Icon(Icons.account_balance);
    }
  }

  Widget _buildProviderTrailing() {
    // Check for MoonPay quotes
    if (_providerId == "moonpay" && _currentQuote != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1 BTC',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Text(
            '= \$${(_currentQuote!.exchangeRate).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    // Default arrow icon
    return const Icon(Icons.arrow_forward_ios, size: 16);
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
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffold(
      context: context,
      appBar: ArkAppBar(
        context: context,
        hasBackButton: true,
        text: l10n.buyBitcoin,
        onTap: () => Navigator.of(context).pop(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.cardPadding),
            child: LongButtonWidget(
              buttonType: ButtonType.transparent,
              customHeight: AppTheme.cardPadding * 1.5,
              customWidth: AppTheme.cardPadding * 4,
              leadingIcon: Icon(
                FontAwesomeIcons.clockRotateLeft,
                size: AppTheme.cardPadding * 0.75,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              title: "0:${_quoteTimer.toString().padLeft(2, '0')}",
              onTap: _refreshQuote,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(l10n)
              : Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const SizedBox(height: AppTheme.cardPadding * 2.5),
                          // Amount Widget
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.cardPadding,
                            ),
                            child: _buildAmountWidget(),
                          ),
                          const SizedBox(height: 15),
                          // Limit warning message
                          if (_allowedAmountDifference != 0 &&
                              _limits != null &&
                              _limits!.quoteCurrency.maxBuyAmount > 0)
                            _buildLimitWarning(),
                          const SizedBox(height: 15),
                          // Payment Method Selection
                          _buildPaymentMethodSection(l10n),
                          // Provider Selection
                          _buildProviderSection(l10n),
                          const SizedBox(height: 100), // Space for button
                        ],
                      ),
                    ),
                    // Bottom Buy Button
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: LongButtonWidget(
                          customWidth: MediaQuery.of(context).size.width * 0.9,
                          title: l10n.buyBitcoin,
                          isLoading: _isProcessing,
                          enabled: _isValidAmount() &&
                              !_isProcessing &&
                              _allowedAmountDifference == 0,
                          onTap: _processPurchase,
                          buttonType: ButtonType.solid,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.errorLoadingBuyScreen,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          LongButtonWidget(
            title: l10n.retry,
            onTap: _initialize,
            buttonType: ButtonType.solid,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountWidget() {
    final minSats = _limits != null
        ? (_limits!.quoteCurrency.minBuyAmount * 100000000).toInt()
        : 0;
    final maxSats = _limits != null
        ? (_limits!.quoteCurrency.maxBuyAmount * 100000000).toInt()
        : 0;

    return AmountWidget(
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
      boundType: _limits != null && _limits!.quoteCurrency.maxBuyAmount > 0
          ? CurrencyType.sats
          : null,
      bitcoinPrice: _btcToUsdRate,
      underBoundFunc: (currentVal) {
        if (_limits == null ||
            (_limits!.quoteCurrency.minBuyAmount == 0 &&
                _limits!.quoteCurrency.maxBuyAmount == 0)) {
          if (_allowedAmountDifference != 0) {
            _allowedAmountDifference = 0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }
          return;
        }
        _allowedAmountDifference =
            (_limits!.quoteCurrency.minBuyAmount * 100000000).toInt() -
                currentVal.toInt();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      },
      overBoundFunc: (currentVal) {
        if (_limits == null ||
            (_limits!.quoteCurrency.minBuyAmount == 0 &&
                _limits!.quoteCurrency.maxBuyAmount == 0)) {
          if (_allowedAmountDifference != 0) {
            _allowedAmountDifference = 0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }
          return;
        }
        _allowedAmountDifference =
            (_limits!.quoteCurrency.maxBuyAmount * 100000000).toInt() -
                currentVal.toInt();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      },
      inBoundFunc: (currentVal) {
        if (_allowedAmountDifference != 0) {
          _allowedAmountDifference = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
      },
      onInputStateChange: (state) {
        _inputState = state;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      },
    );
  }

  Widget _buildLimitWarning() {
    final minBtc = _limits!.quoteCurrency.minBuyAmount;
    final maxBtc = _limits!.quoteCurrency.maxBuyAmount;

    String message;
    if (_allowedAmountDifference < 0) {
      message = 'You are over the limit of ${maxBtc.toStringAsFixed(8)} BTC';
    } else {
      message = 'You are under the limit of ${minBtc.toStringAsFixed(8)} BTC';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.errorColor,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.elementSpacing * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentMethods,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          GlassContainer(
            opacity: 0.05,
            child: ArkListTile(
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
                top: 16.0,
              ),
              text: _paymentMethodName,
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PaymentMethodsScreen(
                      initialMethodId: _paymentMethodId,
                    ),
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
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _getPaymentMethodIcon(_paymentMethodId),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.elementSpacing * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Provider",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          GlassContainer(
            opacity: 0.05,
            child: ArkListTile(
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
                top: 16.0,
              ),
              text: _providerName,
              onTap: () {
                // TODO: Navigate to providers screen when implemented
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _getProviderIcon(_providerId),
              ),
              trailing: _buildProviderTrailing(),
            ),
          ),
        ],
      ),
    );
  }
}
