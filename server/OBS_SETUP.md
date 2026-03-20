# OBS WHIP Setup for Mobistream

## Requirements
- OBS Studio 30.0 or higher (for WHIP support)
- Mobistream WHIP server running
- Phone on same network as PC running OBS

## Quick Start

### 1. Start WHIP Server
```bash
cd server
go run whip_server.go
```

Expected output:
```
🚀 WHIP Server starting on :8080
📡 WHIP endpoint: http://localhost:8080/whip/<stream-id>
```

### 2. Start Stream on Phone
- Set camera name (e.g., "Main")
- Tap "Start Stream"
- Note the stream URL: `http://localhost:8080/whip/Main`

### 3. Add WHIP Source in OBS
1. Sources → + → WHIP
2. URL: `http://localhost:8080/whip/Main`
3. Token: (leave empty for local server)
4. Click OK

Video should appear immediately!

## Multi-Camera Setup

Add multiple WHIP sources with different stream IDs:
- Camera 1: `http://localhost:8080/whip/Main`
- Camera 2: `http://localhost:8080/whip/Wide`
- Camera 3: `http://localhost:8080/whip/Close`

Switch between sources using OBS scenes!

## Troubleshooting

**Video not appearing:**
1. Check server is running: `curl http://localhost:8080/health`
2. Check phone is streaming: Look for "✅ WHIP stream started" in server logs
3. Verify OBS version is 30.0+
4. Try refreshing the WHIP source in OBS (right-click → Refresh)

**High latency:**
- Ensure phone and PC on same network
- Check network congestion
- Lower quality settings in app

**Connection drops:**
- Check OBS logs (Help → Log Files)
- Restart WHIP server
- Verify network stability
- Ensure phone stays unlocked (wakelock enabled)

**Server not starting:**
- Check port 8080 is not in use: `netstat -ano | findstr :8080` (Windows)
- Try different port: Edit `whip_server.go` and change `port := ":8080"`

## Advanced Configuration

### Quality Settings
Modify video constraints in `whip_stream_service.dart`:
```dart
final constraints = {
  'audio': false,
  'video': {
    'mandatory': {
      'minWidth': '1920',        // Increase for HD
      'minHeight': '1080',       // Increase for HD
      'minFrameRate': '60',      // Increase for 60fps
    },
  },
};
```

### STUN Servers
To improve connectivity through NATs, configure STUN servers in `whip_server.go`:
```go
config := webrtc.Configuration{
    ICEServers: []webrtc.ICEServer{
        {URLs: []string{"stun:stun.l.google.com:19302"}},
        {URLs: []string{"stun:stun1.l.google.com:19302"}},
    },
}
```

## Verification

### Test Server Health
```bash
curl http://localhost:8080/health
```
**Expected:** `OK`

### List Active Streams
```bash
curl http://localhost:8080/whip
```
**Expected:** JSON with active streams array

## Architecture

```
┌─────────────────────────┐         HTTP POST          ┌──────────────────┐
│  Flutter App            │ ─────────────────────────► │                  │
│  (WHIP Sender)          │     /whip/{stream-id}      │  Go WHIP Server  │
│                         │                             │  (Local)         │
│ - flutter_webrtc        │         HTTP PATCH         │  - Pion WebRTC   │
│ - HTTP client           │ ◄───────────────────────── │                  │
│ - Camera stream         │     /whip/{stream-id}      │                  │
└─────────────────────────┘                             └──────────────────┘
                                                                 │
                                                                 │ Direct P2P
                                                                 │ WebRTC
                                                                 ▼
                                                       ┌──────────────────┐
                                                       │  OBS Studio      │
                                                       │  (WHIP Client)   │
                                                       │                  │
                                                       │ - Native WHIP    │
                                                       │ - No browser!    │
                                                       └──────────────────┘
```

## Why WHIP?

**Benefits:**
- **Standard Protocol** - W3C/IETF draft standard
- **OBS Native** - No browser source needed
- **HTTP-Based** - Easy to debug with curl
- **Low Latency** - Direct P2P connection (10-100ms)
- **Reliable** - No WebSocket disconnections
- **Multi-Camera** - Multiple streams via different IDs

**Compared to old WebSocket implementation:**
- ✅ More stable connection
- ✅ Easier debugging
- ✅ Lower latency
- ✅ Simpler setup
- ✅ Better multi-camera support
