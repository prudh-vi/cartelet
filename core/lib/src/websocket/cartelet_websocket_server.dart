import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A simple WebSocket server to facilitate communication between Android and Mac.
/// We use `shelf` because we will also need to serve files via HTTP in the future,
/// and `shelf` allows us to compose both HTTP and WebSocket handlers easily.
class CarteletWebSocketServer {
  final List<WebSocketChannel> _clients = [];
  HttpServer? _server;

  /// Starts the WebSocket server on the given [port].
  /// By default, it listens on all interfaces (0.0.0.0) so it can be discovered
  /// and connected to by other devices on the same network.
  Future<void> start({int port = 8080}) async {
    // webSocketHandler comes from shelf_web_socket. It upgrades HTTP requests
    // to WebSocket connections automatically.
    final handler = webSocketHandler((webSocket, subprotocol) {
      // Keep track of connected clients to broadcast messages later if needed.
      _clients.add(webSocket);
      print('Client connected. Total clients: ${_clients.length}');

      // Listen for incoming messages from this client.
      webSocket.stream.listen(
        (message) {
          print('Received message: $message');
          _onMessageReceived(message, webSocket);
        },
        onDone: () {
          // Clean up when a client disconnects.
          _clients.remove(webSocket);
          print('Client disconnected. Total clients: ${_clients.length}');
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _clients.remove(webSocket);
        },
      );
    });

    // Start the shelf server. We use InternetAddress.anyIPv4 to allow external
    // connections from the Mac client.
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    print('WebSocket Server listening on port ${_server?.port}');
  }

  // Callback for external classes to listen to incoming messages
  Function(dynamic message, WebSocketChannel sender)? onMessageReceived;

  /// Handles incoming messages.
  void _onMessageReceived(dynamic message, WebSocketChannel sender) {
    if (onMessageReceived != null) {
      onMessageReceived!(message, sender);
    }
  }

  /// Broadcasts a [message] to all connected clients.
  /// Useful for pushing clipboard updates from the host device.
  void broadcast(String message) {
    for (final client in _clients) {
      client.sink.add(message);
    }
  }

  /// Stops the server and disconnects all clients.
  Future<void> stop() async {
    for (final client in _clients) {
      client.sink.close();
    }
    _clients.clear();
    
    await _server?.close(force: true);
    _server = null;
    print('WebSocket Server stopped.');
  }
}
