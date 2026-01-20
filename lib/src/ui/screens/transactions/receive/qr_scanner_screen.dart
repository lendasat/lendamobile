import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/utility/qr_scanner_overlay.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/qr_scanner/camera_permission_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/qr_scanner/qr_scanner_controls.dart';
import 'package:ark_flutter/src/utils/app_settings_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR code scanner screen with camera permission handling.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  // Simple controller - no autoStart parameter, uses default behavior
  // This automatically triggers native permission dialog
  final MobileScannerController _cameraController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isProcessingQR = false;
  bool _torchEnabled = false;
  bool _hasShownPermissionSheet = false;
  bool _wentToSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from settings, try to restart camera
    if (state == AppLifecycleState.resumed && _wentToSettings) {
      _wentToSettings = false;
      _hasShownPermissionSheet = false; // Allow showing sheet again if still denied
      _cameraController.start();
    }
  }

  void _onQRCodeScanned(String data) {
    if (_isProcessingQR) return;
    _isProcessingQR = true;
    Navigator.of(context).pop(data);
  }

  Future<void> _toggleTorch() async {
    await _cameraController.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  Future<void> _pickImageAndScan() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final result = await _cameraController.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        final code = result.barcodes.first.rawValue;
        if (code != null && mounted) {
          _onQRCodeScanned(code);
        }
      } else if (mounted) {
        OverlayService().showError(
          AppLocalizations.of(context)?.error ?? 'No QR code found in image',
        );
      }
    } catch (e) {
      if (mounted) {
        OverlayService().showError('Error scanning image: $e');
      }
    }
  }

  void _showPermissionSheet() {
    if (_hasShownPermissionSheet) return;
    _hasShownPermissionSheet = true;

    // Show after current frame to avoid build issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showCameraPermissionSheet(
        context: context,
        onGrantAccess: () {
          _wentToSettings = true;
          AppSettingsLauncher.openAppSettings(context);
        },
      );
    });
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
          // Camera preview with error handling
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                final code = capture.barcodes.first.rawValue;
                if (code != null) {
                  _onQRCodeScanned(code);
                }
              }
            },
            // Handle permission errors via errorBuilder
            errorBuilder: (context, error) {
              // Show permission sheet if permission denied
              if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                _showPermissionSheet();
              }
              // Return empty container - camera preview area stays black
              return const SizedBox.expand();
            },
          ),

          // QR Scanner Overlay
          const QRScannerOverlay(),

          // Bottom controls
          QrScannerControls(
            onSwitchCamera: () => _cameraController.switchCamera(),
            onToggleTorch: _toggleTorch,
            onPickImage: _pickImageAndScan,
            isTorchEnabled: _torchEnabled,
          ),
        ],
      ),
    );
  }
}
