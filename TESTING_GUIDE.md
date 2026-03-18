# Quick Testing Guide - Mobistream HTTP MJPEG

## Prerequisites
- Phone and PC on same WiFi network
- Flutter installed
- OBS Studio (any version)

## Step 1: Run the App

```bash
cd C:\Users\saiko\Desktop\projects\mobistream\app
flutter run
```

## Step 2: Verify Camera Preview

**On your phone:**
1. App opens
2. ✅ You should see live camera preview immediately
3. No black screen, no texture issues!

**If camera preview works:** The Flutter camera package is working correctly!

## Step 3: Start Streaming

**On your phone:**
1. Tap "Start Streaming" button
2. Note the MJPEG URL displayed (e.g., `http://192.168.1.100:9000/stream`)
3. Note the port number (9000, 9001, etc.)

## Step 4: Test in Browser (Critical!)

**On your PC:**
1. Open web browser (Chrome, Firefox, Edge, Safari)
2. Paste the MJPEG URL
3. ✅ **Expected:** Live camera feed in browser

**If this works:** The HTTP streaming is working correctly!

**Why test in browser first?**
- Easy debugging
- Confirms streaming works before trying OBS
- If it works in browser, it WILL work in OBS

## Step 5: Connect OBS

**In OBS Studio:**
1. Sources panel → Click "+" → "Media Source"
2. Name it "Mobistream Camera" → Click OK
3. **Uncheck** "Local File" (IMPORTANT!)
4. Input box: Paste the MJPEG URL
   - Example: `http://192.168.1.100:9000/stream`
5. Click OK
6. ✅ **Expected:** Video appears in OBS preview

## Step 6: Test Multiple Cameras (Optional)

**Phone 1:**
1. Select "Camera Number: 1" (uses port 9000)
2. Tap "Start Streaming"
3. URL: `http://192.168.1.100:9000/stream`

**Phone 2:**
1. Select "Camera Number: 2" (uses port 9001)
2. Tap "Start Streaming"
3. URL: `http://192.168.1.100:9001/stream`

**In OBS:**
1. Add Media Source for each phone
2. Both cameras work simultaneously!

## Step 7: Test Latency

**Method:**
1. Open clock app on phone
2. Stream to OBS
3. Record OBS preview with another camera
4. Compare clock time in both videos

**Expected:**
- 5GHz WiFi: 100-800ms
- 2.4GHz WiFi: 800-1500ms

## Troubleshooting

### Camera preview doesn't appear
- Check Settings → Apps → Mobistream → Permissions → Camera
- Restart the app
- Close other camera apps

### Can't access URL in browser
- Ensure phone and PC on same WiFi
- Check URL exactly: `http://` not `https://`
- Try different browser
- Check Windows Firewall allows port 9000-9007

### OBS shows "Source is unreachable"
- Test URL in browser first
- Uncheck "Local File" in Media Source
- Check URL matches exactly
- Restart OBS

### High latency
- Use 5GHz WiFi
- Move closer to router
- Lower quality setting (Good instead of Best)

## Success Indicators

✅ Camera preview works on phone
✅ MJPEG URL works in browser
✅ OBS displays video
✅ Latency <1 second on 5GHz WiFi
✅ Can use multiple phones simultaneously

## What Makes This Different

### Previous attempts (RTMP/RTSP/WebRTC)
- ❌ Complex native code
- ❌ Camera preview didn't work
- ❌ Hard to debug
- ❌ Build errors

### HTTP MJPEG
- ✅ No native code
- ✅ Camera preview works
- ✅ Test in browser
- ✅ Simple and reliable

## Quick Reference URLs

Once streaming is active, use these URLs in OBS or browser:

```
Phone 1 (Camera 1): http://PHONE_IP:9000/stream
Phone 2 (Camera 2): http://PHONE_IP:9001/stream
Phone 3 (Camera 3): http://PHONE_IP:9002/stream
Phone 4 (Camera 4): http://PHONE_IP:9003/stream
```

Replace `PHONE_IP` with actual IP shown in app (e.g., 192.168.1.100)

---

**Ready to test!** Start with Step 1 and work through each step.
