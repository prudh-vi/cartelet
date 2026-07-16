import 'dart:math';
import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'clipboard/clipboard_manager.dart';
import 'mdns/mdns_broadcaster.dart';
import 'ui/pairing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CarteletAndroidApp());
}

class CarteletAndroidApp extends StatefulWidget {
  const CarteletAndroidApp({Key? key}) : super(key: key);

  @override
  State<CarteletAndroidApp> createState() => _CarteletAndroidAppState();
}

class _CarteletAndroidAppState extends State<CarteletAndroidApp> {
  late CarteletWebSocketServer _wsServer;
  late CarteletFileServer _fileServer;
  late MdnsBroadcaster _mdnsBroadcaster;
  late ClipboardManager _clipboardManager;

  final String deviceName = 'Android-${Random().nextInt(9000) + 1000}';
  final String pairingToken = 'token-${Random().nextInt(999999)}';
  final int wsPort = 8080;
  final int filePort = 8081;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    // 1. Start WebSocket Server
    _wsServer = CarteletWebSocketServer();
    await _wsServer.start(port: wsPort);

    // 2. Start HTTP File Server
    // For production, we'd request storage permissions and use a real path like '/storage/emulated/0/Download'
    _fileServer = CarteletFileServer(rootDirectory: '/storage/emulated/0/Download');
    await _fileServer.start(port: filePort);

    // 3. Start mDNS Broadcaster so Mac can find us
    _mdnsBroadcaster = MdnsBroadcaster(deviceName: deviceName, port: wsPort);
    await _mdnsBroadcaster.start();

    // 4. Start Clipboard Manager
    _clipboardManager = ClipboardManager(_wsServer);
    _clipboardManager.init();
  }

  @override
  void dispose() {
    _clipboardManager.dispose();
    _mdnsBroadcaster.stop();
    _fileServer.stop();
    _wsServer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cartelet',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: PairingScreen(
        deviceName: deviceName,
        port: wsPort,
        pairingToken: pairingToken,
      ),
    );
  }
}
