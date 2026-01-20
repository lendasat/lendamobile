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
///
/// Features:
/// - Live camera preview with QR code detection
/// - Gallery image scanning
/// - Torch/flashlight toggle
/// - Front/back camera switching
/// - Graceful permission denial handling
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _cameraController;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isProcessingQR = false;
  bool _torchEnabled = false;
  bool _permissionDenied = false;
  bool _hasHandledPermissionError = false;
  bool _isShowingPermissionSheet = false;
  bool _wentToSettings = false; // Track if user actually went to settings

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.removeListener(_handleCameraStateChange);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only retry if user actually went to settings, not just dismissed the sheet
    if (state == AppLifecycleState.resumed &&
        _permissionDenied &&
        _wentToSettings) {
      _wentToSettings = false; // Reset flag
      _retryCamera();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Camera Initialization & Permission Handling
  // ─────────────────────────────────────────────────────────────────────────

  void _initializeCamera() {
    // Create controller without autoStart - we'll start manually after widget is built
    // This ensures the native permission dialog has time to show
    _cameraController = MobileScannerController(autoStart: false);

    // Start camera after the first frame to ensure widget is mounted
    // The native permission dialog will show automatically if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startCameraWithPermissionHandling();
      }
    });
  }

  Future<void> _startCameraWithPermissionHandling() async {
    try {
      // This will trigger the native permission dialog if not yet granted
      await _cameraController.start();

      // If we get here, permission was granted
      if (mounted) {
        setState(() => _permissionDenied = false);
      }
    } catch (e) {
      // Permission denied or other error - add listener to track state
      _cameraController.addListener(_handleCameraStateChange);

      // Check if it's a permission error
      final state = _cameraController.value;
      if (state.error != null &&
          state.error!.errorCode == MobileScannerErrorCode.permissionDenied) {
        _onPermissionDenied();
      }
    }
  }

  void _handleCameraStateChange() {
    if (_hasHandledPermissionError || _isShowingPermissionSheet) return;

    final state = _cameraController.value;

    // Check for permission denied error
    if (state.error != null &&
        state.error!.errorCode == MobileScannerErrorCode.permissionDenied) {
      _onPermissionDenied();
      return;
    }

    // Camera started successfully - remove listener
    if (state.isRunning && state.error == null) {
      _cameraController.removeListener(_handleCameraStateChange);
    }
  }

  void _onPermissionDenied() {
    _hasHandledPermissionError = true;
    _cameraController.removeListener(_handleCameraStateChange);
    _cameraController.stop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isShowingPermissionSheet) {
        setState(() => _permissionDenied = true);
        _showPermissionSheet();
      }
    });
  }

  Future<void> _retryCamera() async {
    _hasHandledPermissionError = false;

    try {
      await _cameraController.start();
      if (mounted && _cameraController.value.error == null) {
        setState(() => _permissionDenied = false);
      }
    } catch (e) {
      // Permission still denied - check and show bottom sheet again
      final state = _cameraController.value;
      if (state.error != null &&
          state.error!.errorCode == MobileScannerErrorCode.permissionDenied) {
        _onPermissionDenied();
      }
    }
  }

  Future<void> _showPermissionSheet() async {
    if (_isShowingPermissionSheet) return;
    _isShowingPermissionSheet = true;

    await showCameraPermissionSheet(
      context: context,
      onGrantAccess: () {
        _wentToSettings = true; // Mark that user is going to settings
        AppSettingsLauncher.openAppSettings(context);
      },
    );

    _isShowingPermissionSheet = false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // QR Code Scanning
  // ─────────────────────────────────────────────────────────────────────────

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;

    final code = capture.barcodes.first.rawValue;
    if (code != null) {
      _handleScannedCode(code);
    }
  }

  void _handleScannedCode(String code) {
    if (_isProcessingQR) return;
    _isProcessingQR = true;

    Navigator.of(context).pop(code);
  }

  Future<void> _pickImageAndScan() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final result = await _cameraController.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        final code = result.barcodes.first.rawValue;
        if (code != null && mounted) {
          _handleScannedCode(code);
        }
      } else {
        _showNoQrCodeFoundError();
      }
    } catch (e) {
      _showScanError(e);
    }
  }

  void _showNoQrCodeFoundError() {
    if (!mounted) return;
    OverlayService().showError(
      AppLocalizations.of(context)?.error ?? 'No QR code found in image',
    );
  }

  void _showScanError(Object error) {
    if (!mounted) return;
    OverlayService().showError('Error scanning image: $error');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Camera Controls
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _toggleTorch() async {
    await _cameraController.toggleTorch();
    setState(() => _torchEnabled = !_torchEnabled);
  }

  void _switchCamera() => _cameraController.switchCamera();

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

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
          MobileScanner(
            controller: _cameraController,
            onDetect: _onBarcodeDetected,
          ),
          const QRScannerOverlay(),
          QrScannerControls(
            onSwitchCamera: _switchCamera,
            onToggleTorch: _toggleTorch,
            onPickImage: _pickImageAndScan,
            isTorchEnabled: _torchEnabled,
          ),
        ],
      ),
    );
  }
}
