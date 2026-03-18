import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connection information.
class NetworkConnectionInfo {
  final String ipAddress;
  final bool isConnected;

  const NetworkConnectionInfo({
    required this.ipAddress,
    required this.isConnected,
  });
}

/// Service for detecting network information.
class NetworkInfoService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Get the current WiFi IP address.
  /// Returns null if not connected to WiFi or IP cannot be determined.
  Future<NetworkConnectionInfo?> getConnectionInfo() async {
    try {
      final ipAddress = await _networkInfo.getWifiIP();

      if (ipAddress == null) {
        debugPrint('NetworkInfoService: Unable to get WiFi IP');
        return null;
      }

      // Validate IP address format
      final ipParts = ipAddress.split('.');
      if (ipParts.length != 4) {
        debugPrint('NetworkInfoService: Invalid IP format: $ipAddress');
        return null;
      }

      return NetworkConnectionInfo(
        ipAddress: ipAddress,
        isConnected: true,
      );
    } catch (e) {
      debugPrint('NetworkInfoService: Error getting connection info: $e');
      return null;
    }
  }
}
