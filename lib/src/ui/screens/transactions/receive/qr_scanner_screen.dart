import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/qr_scanner_overlay.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/qr_scanner/camera_permission_sheet.dart';
import 'package:ark_flutter/src/utils/app_settings_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  // EXACT same as original - simple controller
  final MobileScannerController cameraController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessingQR = false;
  bool _torchEnabled = false;

  // Only additions for permission handling
  bool _hasShownPermissionSheet = false;
  bool _wentToSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check for permission errors after camera initializes
    cameraController.addListener(_checkPermission);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.removeListener(_checkPermission);
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wentToSettings) {
      _wentToSettings = false;
      _hasShownPermissionSheet = false;
      cameraController.start();
    }
  }

  void _checkPermission() {
    final state = cameraController.value;
    if (state.error != null &&
        state.error!.errorCode == MobileScannerErrorCode.permissionDenied &&
        !_hasShownPermissionSheet) {
      _hasShownPermissionSheet = true;
      cameraController.removeListener(_checkPermission);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showCameraPermissionSheet(
            context: context,
            onGrantAccess: () {
              _wentToSettings = true;
              AppSettingsLauncher.openAppSettings(context);
            },
          );
        }
      });
    }
  }

  void _onQRCodeScanned(String data) {
    // Prevent duplicate processing
    if (_isProcessingQR) {
      return;
    }
    _isProcessingQR = true;

    // Return the scanned data and close the scanner
    Navigator.of(context).pop(data);
  }

  Future<void> _toggleTorch() async {
    await cameraController.toggleTorch();
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  Future<void> _pickImageAndScan() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        final BarcodeCapture? result = await cameraController.analyzeImage(
          image.path,
        );

        if (result != null && result.barcodes.isNotEmpty) {
          final String? code = result.barcodes.first.rawValue;
          if (code != null && mounted) {
            _onQRCodeScanned(code);
          }
        } else {
          if (mounted) {
            OverlayService().showError(
              AppLocalizations.of(context)?.error ??
                  'No QR code found in image',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        OverlayService().showError('Error scanning image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: BitNetAppBar(
        context: context,
        text: l10n?.scanQrCode ?? 'Scan QR Code',
        hasBackButton: true,
        buttonType: ButtonType.transparent,
      ),
      body: Stack(
        children: [
          // Camera preview - EXACT same as original, NO errorBuilder
          MobileScanner(
            controller: cameraController,
            onDetect: (barcode) {
              if (barcode.barcodes.isNotEmpty &&
                  barcode.barcodes.first.rawValue != null) {
                _onQRCodeScanned(barcode.barcodes.first.rawValue!);
              }
            },
          ),

          // QR Scanner Overlay with cutout and corners
          const QRScannerOverlay(),

          // Bottom controls - EXACT same as original
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: AppTheme.cardPadding * 8,
              ),
              child: GlassContainer(
                width: AppTheme.cardPadding * 6.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.elementSpacing * 1.5,
                    vertical: AppTheme.elementSpacing / 1.25,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Switch camera button
                      GestureDetector(
                        onTap: () => cameraController.switchCamera(),
                        child: const Icon(CupertinoIcons.switch_camera),
                      ),

                      // Torch toggle button
                      GestureDetector(
                        onTap: _toggleTorch,
                        child: Icon(
                          _torchEnabled
                              ? CupertinoIcons.bolt_fill
                              : CupertinoIcons.bolt_slash_fill,
                          color: _torchEnabled
                              ? AppTheme.colorBitcoin
                              : AppTheme.white90,
                        ),
                      ),

                      // Pick from gallery button
                      GestureDetector(
                        onTap: _pickImageAndScan,
                        child: const Icon(CupertinoIcons.photo_fill),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
