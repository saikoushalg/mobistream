# MediaMTX Setup for Mobistream WebRTC

MediaMTX acts as the signaling and media relay server for Mobistream. It allows the app to stream using WebRTC (WHIP) and OBS to pull the stream using WebRTC (WHEP).

## 1. Download MediaMTX

1.  Go to the [MediaMTX Releases page](https://github.com/bluenviron/mediamtx/releases).
2.  Download the latest release for your operating system (e.g., `mediamtx_v1.9.0_windows_amd64.zip` for Windows).
3.  Extract the ZIP file to a folder on your computer.

## 2. Configure MediaMTX

By default, MediaMTX is configured correctly for WebRTC, but you should verify these settings in `mediamtx.yml`:

```yaml
# mediamtx.yml

# Enable WebRTC (WHIP/WHEP)
webrtc: yes
webrtcAddress: :8889
webrtcICEUDP: yes
webrtcICEUDPMuxAddress: :8889
```

**Firewall Note:** Ensure that port `8889` (TCP and UDP) is allowed in your computer's firewall so the phone can connect to it.

## 3. Run MediaMTX

Simply run the `mediamtx` executable:
- **Windows:** Double-click `mediamtx.exe`
- **macOS/Linux:** Run `./mediamtx` in a terminal

You should see output indicating that the server is running and the WebRTC server is listening on port 8889.

## 4. Connect Mobistream

1.  Open the Mobistream app on your phone.
2.  Ensure your phone is on the **same WiFi network** as your computer.
3.  Enter your computer's **Local IP Address** in the "MediaMTX IP" field (e.g., `192.168.1.5`).
    - *Tip: Use the search icon to try and auto-discover MediaMTX.*
4.  Set a "Stream Name" (e.g., `cam1`).
5.  Tap **Start Streaming**.

## 5. Add to OBS Studio

OBS Studio 30.0+ supports WHIP/WHEP natively, but for the most reliable experience on the same local network, use the **Browser Source**:

1.  In OBS, click the **+** icon under Sources.
2.  Select **Browser**.
3.  Give it a name (e.g., "Phone Camera").
4.  **URL:** Enter the WHEP URL displayed in Mobistream (e.g., `http://192.168.1.5:8889/cam1/whep`).
5.  **Width/Height:** Set to match your selected quality (e.g., 1280x720 for "Good", 1920x1080 for "Better/Best").
6.  **Use custom frame rate:** Check this and set to 30 or 60 to match the app.
7.  **Control audio via OBS:** Check this if you want to use the phone's microphone in OBS.
8.  Click **OK**.

The stream should appear in OBS with ultra-low latency!
