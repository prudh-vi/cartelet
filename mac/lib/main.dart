import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize window_manager to control the window
  await windowManager.ensureInitialized();
  
  // Set up the window to be hidden initially
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // We intentionally don't show the window on startup to keep it in the background
    // until the user clicks the tray icon.
  });

  // Initialize the system tray
  await _initSystemTray();

  runApp(const CarteletMacApp());
}

Future<void> _initSystemTray() async {
  await trayManager.setIcon(
    // A placeholder icon - normally you'd use a macOS specific icon in the Assets folder
    // Note: Since we haven't added an image asset yet, using a system icon might crash
    // if not configured properly, but trayManager works fine with basic strings on some platforms
    // For now we'll set a basic setup.
    'assets/images/tray_icon.png', // We'll need to create this later or just leave it empty if it crashes
  );
  
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show_window',
        label: 'Open Cartelet',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: 'Quit',
      ),
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
    // Show window when tray icon is clicked
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
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Cartelet Mac is running in the menubar.'),
        ),
      ),
    );
  }
}
