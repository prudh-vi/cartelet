import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A screen that uses the Mac's webcam to scan a QR code displayed on the Android device.
class QrScannerScreen extends StatefulWidget {
  final Function(String name, int port, String token) onPairingDataScanned;

  const QrScannerScreen({Key? key, required this.onPairingDataScanned}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        try {
          final data = jsonDecode(barcode.rawValue!);
          if (data is Map && data.containsKey('port') && data.containsKey('token')) {
            setState(() {
              _scanned = true;
            });
            _controller.stop();
            
            widget.onPairingDataScanned(
              data['name'] ?? 'Unknown Device',
              data['port'] as int,
              data['token'] as String,
            );
          }
        } catch (e) {
          print('Invalid QR code scanned: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Pairing QR Code'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay to guide the user
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Hold the Android device\'s QR code up to the webcam.',
                style: TextStyle(
                  color: Colors.white,
                  backgroundColor: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
