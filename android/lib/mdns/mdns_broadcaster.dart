import 'package:bonsoir/bonsoir.dart';

/// Handles mDNS broadcasting (Bonjour/NSD) for the Android device.
/// This allows the Mac client to discover the Android device automatically
/// without needing to enter IP addresses manually.
class MdnsBroadcaster {
  BonsoirBroadcast? _broadcast;
  final String deviceName;
  final int port;

  MdnsBroadcaster({required this.deviceName, required this.port});

  /// Starts broadcasting the service on the local network.
  Future<void> start() async {
    // Define the mDNS service.
    // _cartelet._tcp is the service type we will look for on the Mac side.
    final service = BonsoirService(
      name: deviceName, 
      type: '_cartelet._tcp',
      port: port,
    );

    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
    
    print('mDNS Broadcasting started for $deviceName on port $port');
  }

  /// Stops broadcasting the service.
  Future<void> stop() async {
    if (_broadcast != null) {
      await _broadcast!.stop();
      _broadcast = null;
      print('mDNS Broadcasting stopped.');
    }
  }
}
