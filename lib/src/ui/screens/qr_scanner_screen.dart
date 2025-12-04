import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ark_flutter/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessingQR = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Scan QR Code',
          style: TextStyle(color: theme.primaryWhite),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (barcode) {
              if (barcode.barcodes.isNotEmpty &&
                  barcode.barcodes.first.rawValue != null) {
                _onQRCodeScanned(barcode.barcodes.first.rawValue!);
              }
            },
          ),
          CustomPaint(
            painter: QRScannerOverlayPainter(),
            child: Container(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Theme.of(context).brightness == Brightness.light
                      ? Border.all(
                          color: Colors.black.withValues(alpha: 0.1),
                          width: 1,
                        )
                      : null,
                  boxShadow: Theme.of(context).brightness == Brightness.light
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        cameraController.facing == CameraFacing.front
                            ? Icons.camera_front
                            : Icons.camera_rear,
                        color: theme.primaryWhite,
                      ),
                      onPressed: () => cameraController.switchCamera(),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: Icon(
                        cameraController.torchEnabled
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: theme.primaryWhite,
                      ),
                      onPressed: () => cameraController.toggleTorch(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the QR scanner overlay
class QRScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final holePaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw the semi-transparent background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Calculate the scanning area (square in the center)
    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Cut out the scanning area
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      holePaint,
    );
    canvas.restore();

    // Draw the border around the scanning area
    const borderRadius = 12.0;
    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + borderRadius),
      Offset(left, top + cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + borderRadius, top),
      Offset(left + cornerLength, top),
      borderPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - borderRadius, top),
      Offset(left + scanAreaSize - cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + borderRadius),
      Offset(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize - borderRadius),
      Offset(left, top + scanAreaSize - cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + borderRadius, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - borderRadius, top + scanAreaSize),
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - borderRadius),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
