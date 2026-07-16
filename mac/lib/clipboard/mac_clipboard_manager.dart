import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';

import '../connection/device_connection.dart';

/// Handles two-way clipboard synchronization on the Mac side.
/// Listens to local clipboard changes and sends them to Android,
/// and receives clipboard changes from Android and applies them locally.
class MacClipboardManager extends ClipboardListener {
  final DeviceConnection _connection;
  String _lastClipboardContent = '';

  MacClipboardManager(this._connection) {
    // Listen for incoming messages from Android
    final existingHandler = _connection.onMessageReceived;
    _connection.onMessageReceived = (data) {
      if (existingHandler != null) {
        existingHandler(data);
      }
      _handleIncomingMessage(data);
    };
  }

  void init() {
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
    print('Mac Clipboard Manager initialized.');
  }

  void dispose() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  // --- Sending to Android ---

  @override
  void onClipboardChanged() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text ?? '';

    if (text.isNotEmpty && text != _lastClipboardContent) {
      _lastClipboardContent = text;
      _connection.sendMessage({
        'type': 'clipboard',
        'content': text,
      });
      print('Synced Mac clipboard content to Android.');
    }
  }

  // --- Receiving from Android ---

  void _handleIncomingMessage(Map<String, dynamic> data) {
    if (data['type'] == 'clipboard' && data['content'] != null) {
      final text = data['content'] as String;
      _setLocalClipboard(text);
    }
  }

  Future<void> _setLocalClipboard(String text) async {
    final currentData = await Clipboard.getData(Clipboard.kTextPlain);
    if (currentData?.text != text) {
      // Update our last seen content so we don't bounce it back
      _lastClipboardContent = text;
      await Clipboard.setData(ClipboardData(text: text));
      print('Mac clipboard updated from Android sync.');
    }
  }
}
