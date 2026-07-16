import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages the WebSocket connection to the Android device with auto-reconnect support.
class DeviceConnection {
  WebSocketChannel? _channel;
  
  // Callback when a message is received from the Android device
  Function(Map<String, dynamic>)? onMessageReceived;
  // Callback when the connection is closed
  Function()? onDisconnected;
  // Callback when reconnected
  Function()? onReconnected;

  String? _lastIp;
  int? _lastPort;
  bool _isIntentionalDisconnect = false;
  Timer? _reconnectTimer;
  
  // Reconnect settings
  final Duration reconnectInterval = const Duration(seconds: 5);

  /// Connects to the Android device at the given [ip] and [port].
  Future<void> connect(String ip, int port) async {
    _lastIp = ip;
    _lastPort = port;
    _isIntentionalDisconnect = false;
    _reconnectTimer?.cancel();
    
    final uri = Uri.parse('ws://$ip:$port');
    print('Attempting to connect to $uri...');
    
    try {
      _channel = WebSocketChannel.connect(uri);
      
      // Listen for incoming messages
      _channel!.stream.listen(
        (message) {
          print('Received message from Android: $message');
          if (onMessageReceived != null) {
            try {
              final data = jsonDecode(message);
              onMessageReceived!(data);
            } catch (e) {
              print('Failed to decode message: $e');
            }
          }
        },
        onDone: _handleDisconnect,
        onError: (error) {
          print('WebSocket Error: $error');
          _handleDisconnect();
        },
      );
      print('Connected to Android device successfully.');
      if (onReconnected != null) onReconnected!();
    } catch (e) {
      print('Failed to connect to Android device: $e');
      _scheduleReconnect();
    }
  }

  void _handleDisconnect() {
    print('Disconnected from Android device.');
    _channel = null;
    if (onDisconnected != null) onDisconnected!();
    
    if (!_isIntentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isIntentionalDisconnect || _lastIp == null || _lastPort == null) return;
    
    print('Scheduling reconnect in ${reconnectInterval.inSeconds} seconds...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectInterval, () {
      print('Attempting to auto-reconnect...');
      connect(_lastIp!, _lastPort!);
    });
  }

  /// Sends a message to the Android device.
  void sendMessage(Map<String, dynamic> payload) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    } else {
      print('Cannot send message: Not connected.');
    }
  }

  /// Disconnects from the device intentionally and stops auto-reconnect.
  void disconnect() {
    _isIntentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
