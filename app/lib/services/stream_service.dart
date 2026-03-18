import '../config/stream_config.dart';

/// Streaming state enumeration.
enum StreamState {
  idle,
  starting,
  ready,
  streaming,
  error,
}

/// Abstract interface for streaming services.
abstract class StreamService {
  /// Stream of state changes for UI to listen to.
  Stream<StreamState> get stateStream;

  /// Get the current streaming state.
  StreamState get currentState;

  /// Start the stream with the given config.
  /// [cameraNumber] is used to differentiate multiple phone streams.
  Future<void> startStream({
    required int port,
    required StreamConfig config,
    int cameraNumber = 1,
  });

  /// Stop the current stream.
  Future<void> stopStream();

  /// Clean up resources.
  Future<void> dispose();

  /// Get the URL that the user should paste in OBS.
  String getObsStreamUrl(String phoneIp, int port);
}
