import 'package:bonsoir/bonsoir.dart';

/// Handles mDNS discovery on the Mac to find the Cartelet Android app on the network.
class MdnsDiscovery {
  BonsoirDiscovery? _discovery;

  /// Starts scanning for devices broadcasting the Cartelet service.
  /// [onDeviceFound] is called when a device is discovered and resolved.
  Future<void> startDiscovery(Function(ResolvedBonsoirService) onDeviceFound) async {
    // We look for the exact same service type we broadcast from Android.
    _discovery = BonsoirDiscovery(type: '_cartelet._tcp');
    
    await _discovery!.ready;
    await _discovery!.start();
    print('Started mDNS discovery for Cartelet devices...');

    _discovery!.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        print('Found service: ${event.service?.name}. Resolving...');
        event.service!.resolve(_discovery!.serviceResolver);
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        print('Resolved service: ${event.service?.name} at ${event.service?.toJson()}');
        
        final resolvedService = event.service as ResolvedBonsoirService;
        onDeviceFound(resolvedService);
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        print('Lost service: ${event.service?.name}');
      }
    });
  }

  /// Stops discovery.
  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      await _discovery!.stop();
      _discovery = null;
      print('Stopped mDNS discovery.');
    }
  }
}
