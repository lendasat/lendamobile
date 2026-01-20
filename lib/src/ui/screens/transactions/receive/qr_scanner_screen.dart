import 'dart:io';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/qr_scanner_overlay.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController cameraController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessingQR = false;
  bool _torchEnabled = false;
  bool _permissionDenied = false;
  bool _hasHandledError = false;
  bool _isShowingBottomSheet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  void _initializeCamera() {
    cameraController = MobileScannerController(
      autoStart: true,
    );

    // Listen to controller state for permission errors
    cameraController.addListener(_onCameraStateChanged);
  }

  void _onCameraStateChanged() {
    // Prevent handling if already processed or showing bottom sheet
    if (_hasHandledError || _isShowingBottomSheet) return;

    final state = cameraController.value;

    // Check for permission denied error
    if (state.error != null &&
        state.error!.errorCode == MobileScannerErrorCode.permissionDenied) {
      _hasHandledError = true;

      // Remove listener immediately to prevent multiple calls
      cameraController.removeListener(_onCameraStateChanged);

      // Stop the camera to prevent flickering
      cameraController.stop();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isShowingBottomSheet) {
          setState(() => _permissionDenied = true);
          _showPermissionBottomSheet();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.removeListener(_onCameraStateChanged);
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from settings, try to restart the camera
    if (state == AppLifecycleState.resumed && _permissionDenied) {
      _retryCamera();
    }
  }

  Future<void> _retryCamera() async {
    // Reset flags to allow re-detection
    _hasHandledError = false;

    // Re-add listener for error handling
    cameraController.addListener(_onCameraStateChanged);

    try {
      await cameraController.start();
      if (mounted && cameraController.value.error == null) {
        setState(() {
          _permissionDenied = false;
        });
      }
    } catch (e) {
      // Permission still denied - listener will handle the error
    }
  }

  Future<void> _showPermissionBottomSheet() async {
    // Prevent showing multiple bottom sheets
    if (_isShowingBottomSheet) return;
    _isShowingBottomSheet = true;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    await arkBottomSheet(
      context: context,
      height: 280,
      isDismissible: true,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.colorBitcoin.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.camera_fill,
                color: AppTheme.colorBitcoin,
                size: 32,
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // Title
            Text(
              "You haven't granted camera access yet",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // Description
            Text(
              'To scan QR codes, the app needs permission to use your camera. Please enable it in your device settings.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: LongButtonWidget(
                    title: 'Cancel',
                    buttonType: ButtonType.secondary,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: LongButtonWidget(
                    title: 'Grant Access',
                    buttonType: ButtonType.solid,
                    onTap: () {
                      Navigator.of(context).pop();
                      _openAppSettings();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Reset flag after bottom sheet is dismissed
    _isShowingBottomSheet = false;
  }

  Future<void> _openAppSettings() async {
    try {
      if (Platform.isIOS) {
        // iOS: Opens the app's settings page in iOS Settings app
        // This is where users can enable/disable camera permission
        final uri = Uri.parse('app-settings:');
        await launchUrl(uri);
      } else if (Platform.isAndroid) {
        // Android: Open the app's settings page in Android Settings
        // Settings > Apps > LendaMobile > Permissions > Camera
        const packageName = 'com.lendasat.lendamobile';

        // Use the Android intent URI scheme to open app details settings
        // This is the most reliable way to open app-specific settings on Android
        final uri = Uri.parse(
          'intent:#Intent;'
          'action=android.settings.APPLICATION_DETAILS_SETTINGS;'
          'data=package:$packageName;'
          'S.browser_fallback_url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3D$packageName;'
          'end',
        );

        // Launch directly without canLaunchUrl check (intent URIs may return false)
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // If intent fails, show a helpful message
      if (mounted) {
        OverlayService().showError(
          'Please open Settings > Apps > Lendasat > Permissions to enable camera access',
        );
      }
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

  Widget _buildPermissionDeniedPlaceholder(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.camera_fill,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                size: 40,
              ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            Text(
              'Camera Access Required',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            Text(
              'Enable camera access in settings to scan QR codes',
              style: TextStyle(
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.cardPadding),
            LongButtonWidget(
              title: 'Open Settings',
              buttonType: ButtonType.solid,
              onTap: _openAppSettings,
            ),
          ],
        ),
      ),
    );
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
          // Camera preview or placeholder
          if (_permissionDenied)
            _buildPermissionDeniedPlaceholder(context)
          else
            MobileScanner(
              controller: cameraController,
              onDetect: (barcode) {
                if (barcode.barcodes.isNotEmpty &&
                    barcode.barcodes.first.rawValue != null) {
                  _onQRCodeScanned(barcode.barcodes.first.rawValue!);
                }
              },
            ),

          // QR Scanner Overlay with cutout and corners (only show when camera active)
          if (!_permissionDenied) const QRScannerOverlay(),

          // Bottom controls (only show when camera active)
          if (!_permissionDenied)
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
