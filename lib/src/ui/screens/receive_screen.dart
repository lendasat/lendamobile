import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

class ReceiveScreen extends StatefulWidget {
  final String aspId;

  const ReceiveScreen({
    super.key,
    required this.aspId,
  });

  @override
  ReceiveScreenState createState() => ReceiveScreenState();
}

class ReceiveScreenState extends State<ReceiveScreen> {
  String? _error;

  String _bip21Address = "";
  String _btcAddress = "";
  String _arkAddress = "";
  String _lightningInvoice = "";
  String? _boltzSwapId;

  bool _showCopyMenu = false;

  final TextEditingController _amountController = TextEditingController();

  // Track which addresses have been copied (for showing checkmarks)
  final Map<String, bool> _copiedAddresses = {
    'BIP21': false,
    'BTC': false,
    'Ark': false,
    'Lightning': false,
  };

  // Timers for resetting the checkmarks
  final Map<String, Timer?> _checkmarkTimers = {
    'BIP21': null,
    'BTC': null,
    'Ark': null,
    'Lightning': null,
  };

  // Payment monitoring state
  bool _waitingForPayment = false;
  PaymentReceived? _paymentReceived;
  int _monitoringSessionId = 0; // Track current monitoring session

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      // Parse amount from controller (in sats)
      BigInt? amountSats;
      if (_amountController.text.isNotEmpty) {
        final parsedAmount = int.tryParse(_amountController.text);
        if (parsedAmount != null && parsedAmount > 0) {
          amountSats = BigInt.from(parsedAmount);
        }
      }

      final addresses = await address(amount: amountSats);
      setState(() {
        _bip21Address = addresses.bip21;
        _arkAddress = addresses.offchain;
        _btcAddress = addresses.boarding;
        _lightningInvoice = addresses.lightning?.invoice ?? "";
        _boltzSwapId = addresses.lightning?.swapId;
        _paymentReceived = null; // Reset payment state
        _monitoringSessionId++; // Increment session to invalidate old monitoring
        _waitingForPayment = false; // Reset flag for new monitoring
      });

      // Start monitoring for payments with new session
      _startPaymentMonitoring();
    } catch (e) {
      logger.e("Error fetching addresses: $e");
      setState(() {
        _error = e.toString();
      });
    } finally {}
  }

  Future<void> _startPaymentMonitoring() async {
    if (_waitingForPayment) {
      logger.i("Already waiting for payment, skipping duplicate call");
      return;
    }

    // Capture the current session ID to check later if this monitoring is still valid
    final sessionId = _monitoringSessionId;

    setState(() {
      _waitingForPayment = true;
    });

    try {
      logger.i("Started waiting for payment (session $sessionId)...");
      logger.i("Ark address: $_arkAddress");
      logger.i("Boarding address: $_btcAddress");
      logger.i("Boltz swap ID: $_boltzSwapId");

      // Wait for payment with 5 minute timeout
      final payment = await waitForPayment(
        arkAddress: _arkAddress.isNotEmpty ? _arkAddress : null,
        boardingAddress: _btcAddress.isNotEmpty ? _btcAddress : null,
        boltzSwapId: _boltzSwapId,
        timeoutSeconds: BigInt.from(300), // 5 minutes
      );

      // Check if this monitoring session is still current
      if (!mounted || _monitoringSessionId != sessionId) {
        logger.i("Monitoring session $sessionId is outdated, ignoring result");
        return;
      }

      setState(() {
        _paymentReceived = payment;
        _waitingForPayment = false;
      });

      logger.i("Payment received! TXID: ${payment.txid}, Amount: ${payment.amountSats} sats");

      // Show success dialog
      _showPaymentReceivedDialog(payment);
    } catch (e) {
      logger.e("Error waiting for payment (session $sessionId): $e");

      // Check if this monitoring session is still current
      if (!mounted || _monitoringSessionId != sessionId) {
        logger.i("Monitoring session $sessionId is outdated, ignoring error");
        return;
      }

      setState(() {
        _waitingForPayment = false;
      });

      // Don't show error if it's just a timeout - that's expected
      if (!e.toString().contains('timeout') && !e.toString().contains('Timeout')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment monitoring error: ${e.toString()}')),
        );
      }
    }
  }

  void _showPaymentReceivedDialog(PaymentReceived payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.amber, size: 32),
              const SizedBox(width: 12),
              const Text('Payment Received!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${payment.amountSats} sats',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'TXID: ${payment.txid}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text('OK', style: TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Cancel any active timers
    _checkmarkTimers.forEach((key, timer) {
      if (timer != null) {
        timer.cancel();
      }
    });
    _amountController.dispose();
    super.dispose();
  }

  void _toggleCopyMenu() {
    setState(() {
      _showCopyMenu = !_showCopyMenu;
    });
  }

  void _copyAddress(String address, String type) {
    Clipboard.setData(ClipboardData(text: address));

    // Cancel existing timer if there is one
    if (_checkmarkTimers[type] != null) {
      _checkmarkTimers[type]!.cancel();
    }

    // Show checkmark
    setState(() {
      _copiedAddresses[type] = true;
    });

    // Set timer to hide checkmark after 2 seconds
    _checkmarkTimers[type] = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedAddresses[type] = false;
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type address copied to clipboard')),
    );
    logger.i("Copied $type address: $address");
  }

  final GlobalKey _qrKey = GlobalKey();

  Future<void> _handleShare() async {
    try {
      logger.i("Share button pressed");

      // Determine which address to share
      String addressToShare = _bip21Address;
      String addressType = "BIP21";

      // Show sharing options dialog
      final String? selectedType = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[850],
            title: const Text('Share Which Address?',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShareOption('BIP21 Address', 'BIP21'),
                _buildShareOption('BTC Address', 'BTC'),
                _buildShareOption('Ark Address', 'Ark'),
                if (_lightningInvoice.isNotEmpty)
                  _buildShareOption('Lightning Invoice', 'Lightning'),
                _buildShareOption('QR Code Image', 'QR'),
              ],
            ),
          );
        },
      );

      if (selectedType == null) {
        // User cancelled the dialog
        return;
      }

      switch (selectedType) {
        case 'BIP21':
          addressToShare = _bip21Address;
          addressType = "BIP21";
          break;
        case 'BTC':
          addressToShare = _btcAddress;
          addressType = "BTC";
          break;
        case 'Ark':
          addressToShare = _arkAddress;
          addressType = "Ark";
          break;
        case 'Lightning':
          addressToShare = _lightningInvoice;
          addressType = "Lightning";
          break;
        case 'QR':
          // Share the QR code as an image
          await _shareQrCodeImage();
          return;
      }

      // Share the text address
      await Share.share(
        addressToShare,
        subject: 'My $addressType Address',
      );

      logger.i("Shared $addressType address: $addressToShare");
    } catch (e) {
      logger.e("Error sharing address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: ${e.toString()}')),
      );
    }
  }

  Widget _buildShareOption(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.of(context).pop(value);
      },
    );
  }

  Future<void> _shareQrCodeImage() async {
    try {
      // Capture the QR code as an image
      RenderRepaintBoundary? boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Could not find QR code widget");
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Could not convert QR code to image");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save image to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/qr_code.png').create();
      await file.writeAsBytes(pngBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Bitcoin Address QR Code',
      );

      logger.i("Shared QR code image");
    } catch (e) {
      logger.e("Error sharing QR code image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing QR code: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Receive',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[800],
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Amount input field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Amount (sats)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        // TODO: This minimum amount requirement is not true and will be removed
                        helperText: 'Lightning invoice requires amount ≥ 500 sats',
                        helperStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.amber),
                          onPressed: _fetchAddresses,
                          tooltip: 'Generate addresses',
                        ),
                      ),
                      onSubmitted: (_) => _fetchAddresses(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment monitoring status
                  if (_waitingForPayment)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Monitoring for incoming payment...',
                              style: TextStyle(
                                color: Colors.amber[300],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Payment received status
                  if (_paymentReceived != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Received!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_paymentReceived!.amountSats} sats',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // QR Code
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: QrImageView(
                        data: _bip21Address,
                        version: QrVersions.auto,
                        size: 280.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Copy address dropdown button
                  InkWell(
                    onTap: _toggleCopyMenu,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(8),
                          bottom: _showCopyMenu
                              ? const Radius.circular(0)
                              : const Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Copy address',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _showCopyMenu
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Address options
                  if (_showCopyMenu) _buildAddressOptions(),

                  const SizedBox(height: 16),

                  if (_error != null)
                    const Text(
                      'Error loading addresses',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                ],
              ),
            ),
          ),

          // Share button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[500],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'SHARE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          const Divider(height: 1, color: Colors.grey),

          // BIP21 Address
          _buildAddressOption(
            label: 'BIP21',
            address: _bip21Address,
            onTap: () => _copyAddress(_bip21Address, 'BIP21'),
            isCopied: _copiedAddresses['BIP21']!,
          ),

          const Divider(
              height: 1, indent: 16, endIndent: 16, color: Colors.grey),

          // BTC Address
          _buildAddressOption(
            label: 'BTC address',
            address: _btcAddress,
            onTap: () => _copyAddress(_btcAddress, 'BTC'),
            isCopied: _copiedAddresses['BTC']!,
          ),

          const Divider(
              height: 1, indent: 16, endIndent: 16, color: Colors.grey),

          // Ark Address
          _buildAddressOption(
            label: 'Ark address',
            address: _arkAddress,
            onTap: () => _copyAddress(_arkAddress, 'Ark'),
            isCopied: _copiedAddresses['Ark']!,
          ),

          // Lightning Invoice (only show if available)
          if (_lightningInvoice.isNotEmpty) ...[
            const Divider(
                height: 1, indent: 16, endIndent: 16, color: Colors.grey),
            _buildAddressOption(
              label: 'Lightning invoice',
              address: _lightningInvoice,
              onTap: () => _copyAddress(_lightningInvoice, 'Lightning'),
              isCopied: _copiedAddresses['Lightning']!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressOption({
    required String label,
    required String address,
    required VoidCallback onTap,
    required bool isCopied,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isCopied
                ? const Icon(Icons.check_circle, color: Colors.amber, size: 24)
                : Icon(Icons.copy, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }
}
