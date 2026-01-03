# iPad PhotoBooth App - Setup Guide

## Overview
This app creates a self-service photo booth using:
- **iPad** (10th generation) - Touch interface
- **Canon R100** - Camera (WiFi tethered via CCAPI)
- **Epson PM-520** - Photo printer (AirPrint)

## Requirements
- iPad 10th generation running iPadOS 16+
- Canon R100 with WiFi enabled
- Epson PM-520 printer
- Same WiFi network for all devices (or camera in AP mode)
- Xcode 15+ (for building)
- Apple Developer account (for signing)

## Hardware Setup

### Canon R100 Camera Setup
1. Enable WiFi on the Canon R100:
   - Menu → Wireless settings → WiFi → Enable
2. Set camera to **Camera Access Point mode** (recommended) or connect to same WiFi as iPad
3. Note the camera's IP address (default: 192.168.1.1 in AP mode)
4. Enable CCAPI:
   - Menu → Wireless settings → WiFi function → Camera Connect settings
   - Enable "CCAPI" access

### Epson PM-520 Printer Setup
1. Connect printer to same WiFi network as iPad
2. Load 4×6 photo paper
3. Printer should appear automatically via AirPrint

### iPad Setup
1. Connect iPad to camera's WiFi (if using AP mode) OR same network as camera/printer
2. For camera AP mode: Connect to "Canon_R100_XXXX" WiFi network

## Building the App

### Method 1: Xcode (Recommended)
1. Clone the repository:
   ```bash
   git clone https://github.com/anirudhatalmale6-alt/ipad-photobooth-app.git
   ```
2. Open `PhotoBooth.xcodeproj` in Xcode 15+
3. Select your Development Team in Signing & Capabilities
4. Change Bundle Identifier if needed (e.g., `com.yourcompany.photobooth`)
5. Connect iPad and select it as build target
6. Build and Run (Cmd+R)

### Method 2: Sideloading with AltStore/Sideloadly
1. Build Archive in Xcode (Product → Archive)
2. Export as Ad Hoc IPA
3. Use AltStore or Sideloadly to install on iPad

## App Configuration

### First Launch
1. Launch the app on iPad
2. Tap the gear icon (top-right corner)
3. Enter default PIN: **1234**

### Settings to Configure
- **Camera IP Address**: Set to your Canon R100's IP (default: 192.168.1.1)
- **Countdown**: 1-10 seconds before capture
- **Copies**: Number of prints per photo (1-5)
- **Paper Size**: 4×6 or 5×7 inches
- **Overlay/Frame**: Import PNG overlays for branded prints
- **Operator PIN**: Change from default 1234

### Adding Custom Overlays
1. Create PNG image at 1800×1200 pixels (4×6 at 300dpi)
2. Use transparency where photo should show through
3. In Settings → Overlay/Frame → Import Overlay
4. Select your PNG file

## Usage Workflow

1. **Idle Screen**: Shows "Photo Booth" with pulsing START button
2. **Live Preview**: Guest sees themselves, taps capture button
3. **Countdown**: 3-2-1 countdown overlay
4. **Capture**: Photo is taken via Canon R100
5. **Review**: Guest sees photo, chooses Retake or Print
6. **Printing**: Photo sent to Epson PM-520
7. **Return to Idle**: Ready for next guest

## Troubleshooting

### Camera Not Connecting
- Verify iPad is on camera's WiFi network
- Check camera IP in Settings matches actual IP
- Ensure CCAPI is enabled on camera
- Try restarting camera WiFi

### Printer Not Found
- Verify printer is on same network as iPad
- Check printer has paper and ink
- Restart printer
- In Settings, tap "Refresh Connections"

### Live View Laggy
- Move iPad closer to camera
- Reduce WiFi interference
- Camera and iPad should have clear line of sight

### App Freezes
- The app has auto-recovery for disconnections
- Wait 5-10 seconds for reconnection
- If stuck, tap Settings gear and "Refresh Connections"

## Network Diagram
```
[Canon R100] ←--WiFi--→ [iPad 10th Gen] ←--WiFi--→ [Epson PM-520]
     ↑                        ↑                         ↑
   Camera AP              Photo Booth               AirPrint
   192.168.1.1              App                    Auto-discover
```

## Support
For issues or feature requests, contact the developer.
