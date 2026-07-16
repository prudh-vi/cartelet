import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'clipboard/clipboard_receiver.dart';
import 'connection/device_connection.dart';
import 'mdns/mdns_discovery.dart';
import 'ui/file_browser_screen.dart';
import 'ui/qr_scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {});
  await _initSystemTray();

  runApp(const CarteletMacApp());
}

Future<void> _initSystemTray() async {
  // Use a simple system tray icon setup.
  await trayManager.setIcon('assets/images/tray_icon.png');
  
  Menu menu = Menu(
    items: [
      MenuItem(key: 'show_window', label: 'Open Cartelet'),
      MenuItem.separator(),
      MenuItem(key: 'exit_app', label: 'Quit'),
    ],
  );
  
  await trayManager.setContextMenu(menu);
}

class CarteletMacApp extends StatefulWidget {
  const CarteletMacApp({Key? key}) : super(key: key);

  @override
  State<CarteletMacApp> createState() => _CarteletMacAppState();
}

class _CarteletMacAppState extends State<CarteletMacApp> with TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cartelet Mac',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MacHomeScreen(),
    );
  }
}

class MacHomeScreen extends StatefulWidget {
  const MacHomeScreen({Key? key}) : super(key: key);

  @override
  State<MacHomeScreen> createState() => _MacHomeScreenState();
}

class _MacHomeScreenState extends State<MacHomeScreen> {
  final DeviceConnection _connection = DeviceConnection();
  final MdnsDiscovery _discovery = MdnsDiscovery();
  ClipboardReceiver? _clipboardReceiver;

  String _status = 'Disconnected';
  String? _connectedIp;

  void _startPairingFlow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrScannerScreen(
          onPairingDataScanned: (name, port, token) {
            setState(() {
              _status = 'Discovering $name on network...';
            });
            _discoverAndConnect(name, port, token);
          },
        ),
      ),
    );
  }

  void _discoverAndConnect(String expectedName, int port, String token) {
    _discovery.startDiscovery((service) {
      if (service.name == expectedName && service.ip != null) {
        _discovery.stopDiscovery();
        final ip = service.ip!;
        
        setState(() {
          _status = 'Connecting to $ip:$port...';
          _connectedIp = ip;
        });

        _connection.connect(ip, port).then((_) {
          setState(() => _status = 'Connected to $expectedName');
          
          // Authenticate with token if needed (omitted for brevity)
          
          // Start receiving clipboard updates
          _clipboardReceiver = ClipboardReceiver(_connection);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cartelet for Mac')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Pair via QR Code'),
              onPressed: _connectedIp == null ? _startPairingFlow : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder),
              label: const Text('Browse Android Files'),
              onPressed: _connectedIp == null ? null : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FileBrowserScreen(
                      ip: _connectedIp!,
                      port: 8081, // Default file server port on Android
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
