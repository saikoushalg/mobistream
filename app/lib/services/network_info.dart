import 'dart:io';
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

  /// Scan local network for MediaMTX server on port 8889 in parallel.
  /// Returns the IP address of the first MediaMTX server found, or null.
  Future<String?> discoverMediaMtx() async {
    final info = await getConnectionInfo();
    if (info == null) return null;

    final subnet = info.ipAddress.substring(0, info.ipAddress.lastIndexOf('.'));

    // Group IP scanning into batches to avoid OS socket limits
    const int batchSize = 30;
    final List<int> hostParts = List.generate(254, (i) => i + 1);

    for (int i = 0; i < hostParts.length; i += batchSize) {
      final end = (i + batchSize < hostParts.length) ? i + batchSize : hostParts.length;
      final batch = hostParts.sublist(i, end);

      final results = await Future.wait(batch.map((hostPart) async {
        final targetIp = '$subnet.$hostPart';
        try {
          final socket = await Socket.connect(targetIp, 8889,
              timeout: const Duration(milliseconds: 500));
          await socket.close();
          return targetIp;
        } catch (_) {
          return null;
        }
      }));

      final foundIp = results.firstWhere((ip) => ip != null, orElse: () => null);
      if (foundIp != null) {
        debugPrint('NetworkInfoService: Found MediaMTX at $foundIp');
        return foundIp;
      }
    }

    return null;
  }
}
