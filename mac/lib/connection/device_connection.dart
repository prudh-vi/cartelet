import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages the WebSocket connection to the Android device.
class DeviceConnection {
  WebSocketChannel? _channel;
  
  // Callback when a message is received from the Android device
  Function(Map<String, dynamic>)? onMessageReceived;
  // Callback when the connection is closed
  Function()? onDisconnected;

  /// Connects to the Android device at the given [ip] and [port].
  Future<void> connect(String ip, int port) async {
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
        onDone: () {
          print('Disconnected from Android device.');
          if (onDisconnected != null) onDisconnected!();
          _channel = null;
        },
        onError: (error) {
          print('WebSocket Error: $error');
          if (onDisconnected != null) onDisconnected!();
          _channel = null;
        },
      );
      print('Connected to Android device successfully.');
    } catch (e) {
      print('Failed to connect to Android device: $e');
    }
  }

  /// Sends a message to the Android device.
  void sendMessage(Map<String, dynamic> payload) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    } else {
      print('Cannot send message: Not connected.');
    }
  }

  /// Disconnects from the device.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
