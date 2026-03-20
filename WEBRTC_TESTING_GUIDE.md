# WebRTC Testing Guide

This guide provides step-by-step instructions for testing the Mobistream WebRTC streaming implementation.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Setup Instructions](#setup-instructions)
4. [Testing Single Camera](#testing-single-camera)
5. [Testing Multiple Cameras](#testing-multiple-cameras)
6. [Switching Cameras](#switching-cameras)
7. [Troubleshooting](#troubleshooting)
8. [Verification Checklist](#verification-checklist)

---

## Prerequisites

### Hardware
- One or more Android/iOS phones (Android 5.0+ or iOS 14+)
- Computer running OBS Studio
- All devices on the same WiFi network

### Software
- Go 1.21+ (for signaling server)
- OBS Studio 28.0+
- Flutter 3.11.1+
- Android Studio / Xcode (for building the app)

### Network
- All devices must be on the same local network
- Some enterprise networks may block mDNS - use a home/office WiFi if issues occur
- Firewall should allow local network traffic

---

## Quick Start

### 1. Start the Signaling Server

```bash
cd server
go mod download
go run main.go
```

**Expected Output:**
```
mDNS service registered: _obs_cam._tcp
Service will be broadcast as: Mobistream._obs_cam._tcp.local.
Signaling server starting on :8080
Serving static files from current directory
```

### 2. Add OBS Browser Source

1. Open OBS Studio
2. In the **Sources** panel, click **+** → **Browser**
3. Enter:
   - **Name:** Mobistream Receiver
   - **Local File:** Browse to `server/obs_receiver.html`
   - **Width:** 1920
   - **Height:** 1080
4. Click **OK**

**Expected:** OBS preview shows "Receiver XXXX - Waiting for cameras..."

### 3. Run the Flutter App

```bash
cd app
flutter run
```

**Expected:**
- App shows "Searching for OBS..." → "OBS Studio (XXXX)"
- Tap on the receiver
- App shows "Connecting..." → "Streaming"
- Video appears in OBS

---

## Setup Instructions

### Step 1: Build the Go Signaling Server

```bash
# Navigate to server directory
cd server

# Download dependencies
go mod download

# Run the server
go run main.go
```

The server will:
- Start on port 8080
- Broadcast mDNS service `_obs_cam._tcp`
- Listen for WebSocket connections
- Log all connections and messages

### Step 2: Build the Flutter App

#### Android:
```bash
cd app
flutter build apk --release
# Install APK on phone
```

#### iOS:
```bash
cd app
flutter build ios --release
# Open in Xcode and deploy to device
```

### Step 3: Configure OBS

1. **Add Browser Source:**
   - Sources → + → Browser
   - Local file: `server/obs_receiver.html`
   - Width: 1920, Height: 1080
   - Check "Control audio via OBS" (if using audio)

2. **Verify Connection:**
   - Check OBS preview for receiver ID
   - Check server logs for connection

3. **Optional: Set Up Scenes for Camera Switching:**
   - Create 3 scenes: Main, Wide, Close
   - Add the same browser source to each scene
   - Use JavaScript `switchCamera()` in scene transitions

---

## Testing Single Camera

### Test 1: Basic Connection

1. Start the Go server
2. Add browser source in OBS
3. Run the app on one phone
4. Set camera name (e.g., "Main")
5. Select receiver and connect

**Expected Results:**
- ✅ Phone shows "Streaming to OBS"
- ✅ OBS shows live video from phone
- ✅ Latency < 100ms
- ✅ No UI overlays on video

### Test 2: Camera Name Persistence

1. Set camera name to "TestCamera"
2. Connect and stream
3. Stop streaming
4. Close and reopen app
5. Check settings

**Expected Results:**
- ✅ Camera name remembered as "TestCamera"
- ✅ No need to re-enter

### Test 3: Stop and Restart

1. Start streaming
2. Wait 10 seconds
3. Tap "Stop Streaming"
4. Wait 2 seconds
5. Reconnect to receiver

**Expected Results:**
- ✅ Clean disconnect
- ✅ Can reconnect successfully
- ✅ No server crash

---

## Testing Multiple Cameras

### Test 4: Two Phones, Same Receiver

1. Phone 1: Set name "Main", connect
2. Phone 2: Set name "Wide", connect
3. Check OBS preview

**Expected Results:**
- ✅ Both phones show "Streaming to OBS"
- ✅ Receiver shows "2 cameras connected"
- ✅ One camera visible in OBS (active camera)
- ✅ Can switch between cameras

### Test 5: Three Phones

1. Phone 1: "Main"
2. Phone 2: "Wide"
3. Phone 3: "Close"
4. All connect to same receiver

**Expected Results:**
- ✅ All three streaming
- ✅ Receiver shows "3 cameras connected"
- ✅ Can switch between all three
- ✅ No lag or instability

### Test 6: Camera Disconnect

1. Connect 3 phones
2. Close app on Phone 2
3. Check OBS and server logs

**Expected Results:**
- ✅ Phone 2 disconnects cleanly
- ✅ Other phones continue streaming
- ✅ Receiver shows "2 cameras connected"
- ✅ No crash or instability

---

## Switching Cameras

### Method 1: OBS Scenes

1. Create 3 scenes: Main, Wide, Close
2. Add the same browser source to all scenes
3. Add transition logic:

```javascript
// In scene transition (advanced)
switchCamera('Main');  // or 'Wide', 'Close'
```

4. Switch scenes in OBS

**Expected Results:**
- ✅ Camera switches when scene changes
- ✅ Clean transition between cameras

### Method 2: JavaScript Console

1. Open OBS JavaScript console (View → Docks → Script Log)
2. Run:
```javascript
switchCamera('Main');
switchCamera('Wide');
switchCamera('Close');
```

**Expected Results:**
- ✅ Camera switches immediately
- ✅ Video updates in < 1 second

### Method 3: OBS Hotkeys (Future)

Set up hotkeys to call `switchCamera()` functions:
- Hotkey 1: `switchCamera('Main')`
- Hotkey 2: `switchCamera('Wide')`
- Hotkey 3: `switchCamera('Close')`

---

## Troubleshooting

### Issue: "No OBS receivers found"

**Causes:**
- Go server not running
- mDNS blocked by network
- Different network segments

**Solutions:**
1. Check server is running: `netstat -an | grep 8080`
2. Ping phone from computer (same network?)
3. Try manual IP: Set signaling server URL manually

### Issue: "Connection error - Retrying"

**Causes:**
- Server crashed
- WebSocket connection failed
- Network interruption

**Solutions:**
1. Restart server
2. Check server logs
3. Verify OBS browser source is using local file

### Issue: Video not appearing in OBS

**Causes:**
- WebRTC handshake failed
- Camera permissions denied
- ICE negotiation failed

**Solutions:**
1. Check app permissions (Settings → Apps → Mobistream)
2. Restart app
3. Check server logs for errors
4. Try pressing 'D' key in OBS browser source (debug mode)

### Issue: High latency (> 500ms)

**Causes:**
- Network congestion
- Poor WiFi signal
- Hardware limitations

**Solutions:**
1. Move devices closer to router
2. Use 5GHz WiFi instead of 2.4GHz
3. Lower video quality in app settings (future)
4. Close other network-intensive apps

### Issue: Audio not working

**Note:** Current implementation is video-only. Audio support can be enabled by:
1. In `webrtc_stream_service.dart`, change `'audio': false` to `'audio': true`
2. Grant microphone permissions
3. Enable audio in OBS browser source properties

### Issue: Server won't start (port 8080 in use)

**Solution:**
```bash
# Find process using port 8080
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# Kill the process or change port in main.go
```

---

## Verification Checklist

### Server Setup
- [ ] Go server starts without errors
- [ ] mDNS service registered (check logs)
- [ ] Can access `http://localhost:8080/obs_receiver.html` in browser
- [ ] Server logs show WebSocket connections

### OBS Setup
- [ ] Browser source added successfully
- [ ] Preview shows receiver ID
- [ ] No errors in browser source console
- [ ] Audio enabled (if needed)

### App Setup
- [ ] App launches without crashes
- [ ] Camera permissions granted
- [ ] Network permissions granted
- [ ] Can discover receivers via mDNS

### Streaming Tests
- [ ] Single camera streams successfully
- [ ] Video appears in OBS < 1 second
- [ ] Latency < 100ms (ideally < 50ms)
- [ ] Video quality is good (720p+)
- [ ] Can stop and restart streaming

### Multi-Camera Tests
- [ ] Multiple phones connect to same receiver
- [ ] Each camera has unique name
- [ ] Can switch between cameras
- [ ] Disconnecting one phone doesn't affect others
- [ ] Receiver list updates correctly

### Camera Naming
- [ ] Can set custom camera name
- [ ] Name persists across app restarts
- [ ] Name appears in receiver list
- [ ] Switching by name works

### Edge Cases
- [ ] App handles server disconnection gracefully
- [ ] App handles network changes gracefully
- [ ] Server handles abrupt client disconnects
- [ ] Memory usage is stable (no leaks)
- [ ] Can stream for 30+ minutes without issues

---

## Performance Benchmarks

### Expected Performance (WiFi, 5GHz):

| Metric | Target | Acceptable |
|--------|--------|------------|
| Latency | < 50ms | < 100ms |
| FPS | 30 | 24-30 |
| Resolution | 1280x720 | ≥ 720p |
| CPU Usage | < 30% | < 50% |
| Memory | < 200MB | < 400MB |

### Network Bandwidth:

| Quality | Bitrate | Bandwidth |
|---------|---------|-----------|
| Good | 2-3 Mbps | ~2.5 Mbps |
| Better | 3-5 Mbps | ~4 Mbps |
| Best | 5-8 Mbps | ~6.5 Mbps |

---

## Debug Mode

### OBS Browser Source Debug Mode

1. Right-click browser source → Properties
2. Check "Enable custom CSS"
3. Add: `#debug-info { display: block !important; }`
4. Or press 'D' key while browser source is focused

This shows:
- Connection status
- WebRTC state changes
- ICE candidates
- Camera switches

### Server Debug Logging

The server logs all:
- WebSocket connections
- mDNS discoveries
- Signaling messages
- Camera connections/disconnections
- Errors

### App Debug Logging

```bash
flutter run --verbose
```

Shows:
- mDNS discovery progress
- WebSocket connection status
- WebRTC peer connection state
- ICE candidate exchange
- Errors

---

## Next Steps

After successful testing:

1. **Production Build:**
   - Build release APK/IPA
   - Test on real devices (not emulator)
   - Test on different networks

2. **Performance Tuning:**
   - Adjust video quality based on network
   - Implement adaptive bitrate
   - Add quality selector in UI

3. **Additional Features:**
   - Add audio streaming
   - Add camera controls (focus, zoom)
   - Add connection quality indicator
   - Add manual IP entry fallback

4. **Documentation:**
   - User guide for non-technical users
   - Video tutorial
   - FAQ for common issues

---

## Support

### Common Commands

```bash
# Start server
cd server && go run main.go

# Run app (debug)
cd app && flutter run

# Run app (release)
cd app && flutter run --release

# Build APK
cd app && flutter build apk --release

# Build iOS
cd app && flutter build ios --release

# Check for issues
cd app && flutter analyze
```

### Log Locations

- **Server:** Terminal output
- **App:** `flutter run` output or Android Logcat
- **OBS:** View → Docks → Log Files

### Useful URLs

- mDNS Service: `_obs_cam._tcp.local`
- Signaling Server: `ws://localhost:8080/ws`
- Browser Source: `file:///path/to/server/obs_receiver.html`

---

**Last Updated:** 2026-03-19
**Version:** 1.0.0 (WebRTC Implementation)
