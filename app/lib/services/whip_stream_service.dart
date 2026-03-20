import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/stream_config.dart';
import 'stream_service.dart';

class WHIPStreamService implements StreamService {
  final String _serverURL = 'http://192.168.1.45:8080';
  String? _streamID;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final StreamController<StreamState> _stateController =
      StreamController<StreamState>.broadcast();
  StreamState _currentState = StreamState.idle;

  @override
  Stream<StreamState> get stateStream => _stateController.stream;

  @override
  StreamState get currentState => _currentState;

  Future<String> _getStreamID() async {
    if (_streamID == null) {
      final prefs = await SharedPreferences.getInstance();
      _streamID = prefs.getString('camera_name') ?? 'Camera';
    }
    return _streamID!;
  }

  @override
  Future<void> startStream({
    required int port,
    required StreamConfig config,
    int cameraNumber = 1,
  }) async {
    if (_currentState == StreamState.streaming) return;

    _setState(StreamState.starting);

    try {
      // Get stream ID (camera name)
      _streamID = await _getStreamID();

      debugPrint('🎥 Starting WHIP stream: $_streamID');

      // Initialize WebRTC peer connection
      final configuration = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'}
        ]
      };

      _peerConnection = await createPeerConnection(configuration);

      // Get camera stream
      _localStream = await _getUserMedia();
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle ICE candidates
      _peerConnection!.onIceCandidate = (candidate) {
        _sendICECandidate(candidate);
      };

      // Create SDP offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      debugPrint('📤 Sending WHIP offer to /whip/$_streamID');

      // Send WHIP POST request
      final response = await http.post(
        Uri.parse('$_serverURL/whip/$_streamID'),
        headers: {'Content-Type': 'application/sdp'},
        body: offer.sdp,
      );

      if (response.statusCode == 201) {
        debugPrint('📥 Received WHIP answer');

        // Set remote description (answer)
        final answer = RTCSessionDescription(response.body, 'answer');
        await _peerConnection!.setRemoteDescription(answer);

        _setState(StreamState.streaming);
        debugPrint('✅ WHIP stream started: $_streamID');
      } else {
        debugPrint('❌ WHIP request failed: ${response.statusCode}');
        _setState(StreamState.error);
      }
    } catch (e) {
      debugPrint('❌ WHIP error: $e');
      _setState(StreamState.error);
      await _cleanupResources();
    }
  }

  Future<void> _sendICECandidate(RTCIceCandidate candidate) async {
    try {
      await http.patch(
        Uri.parse('$_serverURL/whip/$_streamID'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'candidate': candidate.candidate}),
      );
    } catch (e) {
      debugPrint('⚠️  Failed to send ICE candidate: $e');
    }
  }

  Future<MediaStream> _getUserMedia() async {
    final constraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': '1280',
          'minHeight': '720',
          'minFrameRate': '30',
        },
      },
    };

    return await navigator.mediaDevices.getUserMedia(constraints);
  }

  void _setState(StreamState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<void> stopStream() async {
    if (_currentState == StreamState.idle) return;

    debugPrint('🛑 Stopping WHIP stream: $_streamID');

    // Send DELETE request
    try {
      await http.delete(Uri.parse('$_serverURL/whip/$_streamID'));
    } catch (e) {
      debugPrint('⚠️  Failed to send DELETE request');
    }

    await _cleanupResources();
    _setState(StreamState.idle);
  }

  Future<void> _cleanupResources() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
  }

  @override
  Future<void> dispose() async {
    await _cleanupResources();
    await _stateController.close();
  }

  @override
  String getObsStreamUrl(String phoneIp, int port) {
    return '$_serverURL/whip/$_streamID';
  }
}
