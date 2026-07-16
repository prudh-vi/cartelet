import 'dart:convert';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:core/core.dart';
import 'package:flutter/services.dart';

/// Manages clipboard listening and synchronization.
/// Uses `clipboard_watcher` to detect when the clipboard changes on the Android device,
/// and then sends the new clipboard content to the Mac client via WebSocket.
class ClipboardManager extends ClipboardListener {
  final CarteletWebSocketServer _server;
  String _lastClipboardContent = '';

  ClipboardManager(this._server) {
    final existingHandler = _server.onMessageReceived;
    _server.onMessageReceived = (message, sender) {
      if (existingHandler != null) {
        existingHandler(message, sender);
      }
      _handleIncomingMessage(message);
    };
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'clipboard' && data['content'] != null) {
        final text = data['content'] as String;
        _setLocalClipboard(text);
      }
    } catch (e) {
      print('Failed to parse clipboard message on Android: $e');
    }
  }

  Future<void> _setLocalClipboard(String text) async {
    final currentData = await Clipboard.getData(Clipboard.kTextPlain);
    if (currentData?.text != text) {
      _lastClipboardContent = text;
      await Clipboard.setData(ClipboardData(text: text));
      print('Android clipboard updated from Mac sync.');
    }
  }

  /// Initializes the clipboard watcher.
  void init() {
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
    print('Clipboard Manager initialized.');
  }

  /// Cleans up the clipboard watcher.
  void dispose() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  @override
  void onClipboardChanged() async {
    // Read the current text from the clipboard
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text ?? '';

    // If the text is new and not empty, sync it over WebSocket.
    if (text.isNotEmpty && text != _lastClipboardContent) {
      _lastClipboardContent = text;
      _syncClipboard(text);
    }
  }

  /// Sends the clipboard content to all connected WebSocket clients.
  void _syncClipboard(String text) {
    final payload = jsonEncode({
      'type': 'clipboard',
      'content': text,
    });
    
    // Broadcast to connected Mac clients
    _server.broadcast(payload);
    print('Synced clipboard content to Mac.');
  }
}
