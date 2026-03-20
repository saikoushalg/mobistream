# Local Live Streaming Ecosystem - MediaMTX + WHIP/WHEP

## Architecture Overview

```
┌──────────────────┐         WHIP POST          ┌─────────────────────┐
│  Flutter App     │ ─────────────────────────► │                     │
│  (WHIP Client)   │     /whip/{stream-id}      │                     │
│                  │                             │   MediaMTX Server   │
│ - flutter_webrtc │         WHEP POST           │   (Go Media Server) │
│ - Camera stream  │ ◄───────────────────────── │                     │
└──────────────────┘     /whep/{stream-id}      │                     │
                                                 │  - WHIP Ingest     │
                      ┌─────────────────────────│  - WHEP Playback   │
                      │                         │  - No STUN/TURN    │
                      │ Direct HTTP             └─────────────────────┘
                      │
                      ▼
              ┌──────────────────┐
              │  OBS Studio      │
              │  (Browser Source)│
              │                  │
              │  - WHEP Client   │
              │  - WebRTC API    │
              └──────────────────┘
```

## Why This Architecture is Superior

1. **MediaMTX** is production-ready, battle-tested, handles edge cases
2. **WHIP/WHEP** are W3C/IETF standards (not custom protocols)
3. **No STUN/TURN needed** for local network (faster connection)
4. **Browser Source in OBS** works with any OBS version (no v30+ requirement)
5. **Automatic reconnection** logic handles network drops
6. **Scalable** - add unlimited camera streams

## Network Configuration

**Server (PC):** 192.168.1.45
**WHIP Endpoint:** http://192.168.1.45:8888/whip/{stream-id}
**WHEP Endpoint:** http://192.168.1.45:8888/whep/{stream-id}
**Protocol:** HTTP (no SSL needed for local network)

## Stream IDs

Multiple cameras use different stream IDs:
- Phone 1: `cam1` → WHIP: `/whip/cam1`, WHEP: `/whep/cam1`
- Phone 2: `cam2` → WHIP: `/whip/cam2`, WHEP: `/whep/cam2`
- Phone 3: `cam3` → WHIP: `/whip/cam3`, WHEP: `/whep/cam3`
