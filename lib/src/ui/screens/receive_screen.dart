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
import 'package:ark_flutter/src/ui/utility/amount_widget.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';

enum AddressType { bip21, btc, ark }

class ReceiveScreen extends StatefulWidget {
  final String aspId;
  final int amount; // Amount in sats, 0 means any amount

  const ReceiveScreen({
    super.key,
    required this.aspId,
    required this.amount,
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

  // Current amount in sats (null means no amount set)
  int? _currentAmount;

  // Current address type for display
  AddressType _currentAddressType = AddressType.bip21;

  // Amount widget controllers
  final TextEditingController _btcController = TextEditingController();
  final TextEditingController _satController = TextEditingController();
  final TextEditingController _currController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  // Payment monitoring state
  bool _waitingForPayment = false;
  PaymentReceived? _paymentReceived;

  @override
  void initState() {
    super.initState();
    // Initialize amount from widget (0 means no amount)
    _currentAmount = widget.amount > 0 ? widget.amount : null;
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      // Use current amount (null means any amount)
      final BigInt? amountSats =
          _currentAmount != null ? BigInt.from(_currentAmount!) : null;

      final addresses = await address(amount: amountSats);
      setState(() {
        _bip21Address = addresses.bip21;
        _arkAddress = addresses.offchain;
        _btcAddress = addresses.boarding;
        _lightningInvoice = addresses.lightning?.invoice ?? "";
        _boltzSwapId = addresses.lightning?.swapId;
      });

      // Start monitoring for payments
      _startPaymentMonitoring();
    } catch (e) {
      logger.e("Error fetching addresses: $e");
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _startPaymentMonitoring() async {
    if (_waitingForPayment) {
      logger.i("Already waiting for payment, skipping duplicate call");
      return;
    }

    setState(() {
      _waitingForPayment = true;
    });

    try {
      logger.i("Started waiting for payment...");
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

      if (!mounted) return;

      setState(() {
        _paymentReceived = payment;
        _waitingForPayment = false;
      });

      logger.i(
          "Payment received! TXID: ${payment.txid}, Amount: ${payment.amountSats} sats");

      // Show success dialog
      _showPaymentReceivedDialog(payment);
    } catch (e) {
      logger.e("Error waiting for payment: $e");
      if (!mounted) return;

      setState(() {
        _waitingForPayment = false;
      });

      // Don't show error if it's just a timeout - that's expected
      if (!e.toString().contains('timeout') &&
          !e.toString().contains('Timeout')) {
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
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Text('Payment Received!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${payment.amountSats} sats',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
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
                // Close dialog
                Navigator.of(context).pop();

                // Navigate back to dashboard (pop until we reach it)
                Navigator.of(context).popUntil((route) => route.isFirst);
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
    _btcController.dispose();
    _satController.dispose();
    _currController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _copyCurrentAddress() {
    String address = _getCurrentAddressData();
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
    logger.i("Copied address: $address");
  }

  void _cycleAddressType() {
    setState(() {
      switch (_currentAddressType) {
        case AddressType.bip21:
          _currentAddressType = AddressType.btc;
          break;
        case AddressType.btc:
          _currentAddressType = AddressType.ark;
          break;
        case AddressType.ark:
          _currentAddressType = AddressType.bip21;
          break;
      }
    });
  }

  String _getCurrentAddressData() {
    switch (_currentAddressType) {
      case AddressType.bip21:
        return _bip21Address;
      case AddressType.btc:
        return _btcAddress;
      case AddressType.ark:
        return _arkAddress;
    }
  }

  String _getAddressTypeLabel() {
    switch (_currentAddressType) {
      case AddressType.bip21:
        return 'BIP21';
      case AddressType.btc:
        return 'BTC Address';
      case AddressType.ark:
        return 'Ark Address';
    }
  }

  IconData _getAddressTypeIcon() {
    switch (_currentAddressType) {
      case AddressType.bip21:
        return Icons.qr_code_2;
      case AddressType.btc:
        return Icons.currency_bitcoin;
      case AddressType.ark:
        return Icons.water_drop;
    }
  }

  void _showAmountBottomSheet() {
    // Initialize controllers with current amount if set
    _satController.text = _currentAmount?.toString() ?? '';
    _btcController.text = '';
    _currController.text = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set Amount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentAmount != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentAmount = null;
                        _satController.clear();
                        _btcController.clear();
                        _currController.clear();
                      });
                      _fetchAddresses();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            AmountWidget(
              enabled: () => true,
              btcController: _btcController,
              satController: _satController,
              currController: _currController,
              focusNode: _amountFocusNode,
              bitcoinUnit: CurrencyType.sats,
              swapped: false,
              autoConvert: false,
              bitcoinPrice: 60000.0,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset controllers on cancel
                      _satController.text = _currentAmount?.toString() ?? '';
                      _btcController.clear();
                      _currController.clear();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final amountText = _satController.text.trim();
                      if (amountText.isEmpty) {
                        // Clear amount
                        setState(() {
                          _currentAmount = null;
                        });
                        _fetchAddresses();
                      } else {
                        final amount = int.tryParse(amountText);
                        if (amount != null && amount > 0) {
                          setState(() {
                            _currentAmount = amount;
                          });
                          _fetchAddresses(); // Refetch with new amount
                        }
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).then((_) {
      // Clean up controllers when bottom sheet closes
      _satController.text = '';
      _btcController.clear();
      _currController.clear();
    });
  }

  final GlobalKey _qrKey = GlobalKey();

  Future<void> _handleShare() async {
    try {
      logger.i("Share button pressed");

      String addressToShare = _getCurrentAddressData();
      String addressType = _getAddressTypeLabel();

      // Share the text address
      await Share.share(
        addressToShare,
        subject: 'My $addressType',
      );

      logger.i("Shared $addressType: $addressToShare");
    } catch (e) {
      logger.e("Error sharing address: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: ${e.toString()}')),
      );
    }
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
      if (!mounted) return;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Payment monitoring status
            if (_waitingForPayment)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
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
                  data: _getCurrentAddressData(),
                  version: QrVersions.auto,
                  size: 280.0,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Share buttons (centered)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Share text button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: ElevatedButton(
                    onPressed: _handleShare,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Share QR code image button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: OutlinedButton.icon(
                    onPressed: _shareQrCodeImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: BorderSide(color: Colors.grey[700]!),
                    ),
                    icon: const Icon(Icons.qr_code, size: 20),
                    label: const Text(
                      'QR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Three tiles with borders
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Address tile
                  _buildTile(
                    label: 'Address',
                    value: _trimAddress(_getCurrentAddressData()),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, color: Colors.grey),
                      onPressed: _copyCurrentAddress,
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[800]),

                  // Amount tile
                  _buildTile(
                    label: 'Amount',
                    value: _currentAmount != null
                        ? '$_currentAmount sats'
                        : 'Change Amount',
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: _showAmountBottomSheet,
                    ),
                    onTap: _showAmountBottomSheet,
                  ),
                  Divider(height: 1, color: Colors.grey[800]),

                  // Type tile
                  _buildTile(
                    label: 'Type',
                    value: _getAddressTypeLabel(),
                    leading: Icon(_getAddressTypeIcon(), color: Colors.grey),
                    onTap: _cycleAddressType,
                  ),
                ],
              ),
            ),

            if (_error != null)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Error loading addresses',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _trimAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 10)}';
  }

  Widget _buildTile({
    required String label,
    required String value,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 12),
            ],
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
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
