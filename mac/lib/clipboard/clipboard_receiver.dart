import 'package:flutter/services.dart';

import '../connection/device_connection.dart';

/// Listens for clipboard sync messages from the connected Android device
/// and updates the Mac's local clipboard accordingly.
class ClipboardReceiver {
  final DeviceConnection _connection;

  ClipboardReceiver(this._connection) {
    // Add our message handler to the connection
    final existingHandler = _connection.onMessageReceived;
    _connection.onMessageReceived = (data) {
      // Allow other handlers to run if they exist
      if (existingHandler != null) {
        existingHandler(data);
      }
      _handleMessage(data);
    };
  }

  void _handleMessage(Map<String, dynamic> data) {
    if (data['type'] == 'clipboard' && data['content'] != null) {
      final text = data['content'] as String;
      _setLocalClipboard(text);
    }
  }

  Future<void> _setLocalClipboard(String text) async {
    // Check if the current clipboard is already the same to avoid unnecessary writes
    final currentData = await Clipboard.getData(Clipboard.kTextPlain);
    if (currentData?.text != text) {
      await Clipboard.setData(ClipboardData(text: text));
      print('Mac clipboard updated from Android sync.');
    }
  }
}
