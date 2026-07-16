import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A screen that displays a QR code for the Mac client to scan.
/// This allows for easy and secure pairing between the devices.
class PairingScreen extends StatelessWidget {
  final String deviceName;
  final int port;
  final String pairingToken;

  const PairingScreen({
    Key? key,
    required this.deviceName,
    required this.port,
    required this.pairingToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The data to be embedded in the QR code.
    // The Mac app will scan this and use the information to connect.
    final qrData = jsonEncode({
      'name': deviceName,
      'port': port,
      'token': pairingToken,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Scan this QR code from the Cartelet Mac app to connect.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              // Display the QR code using qr_flutter
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Device: $deviceName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
