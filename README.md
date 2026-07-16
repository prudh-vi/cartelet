# Cartelet

Cartelet is an open-source wireless bridge between Android and Mac. Think of it as a universal OnePlus Connect that works for ALL Android phones. It allows for seamless clipboard synchronization and file browsing between your Android device and your Mac via a local network connection.

## Features
- **Zero-Config Pairing**: Just scan a QR code from your Mac to instantly pair with your Android device via mDNS (Bonjour).
- **Clipboard Sync**: Automatically syncs your Android clipboard to your Mac in real-time.
- **Wireless File Browser**: View and download files from your Android device directly on your Mac.
- **Auto-Reconnect**: Seamlessly re-establishes the connection if the network drops.
- **OTA Updates**: Built-in GitHub Releases checker to notify you of new updates.

## Tech Stack
- **Framework**: Flutter + Dart (used for both Android and Mac clients)
- **Communication**: WebSockets (`shelf_web_socket` / `web_socket_channel`)
- **Discovery**: mDNS / Network Service Discovery (`bonsoir`)
- **File Serving**: HTTP (`shelf` / `http`)

## Project Structure
This is a Flutter monorepo containing three main packages:

* `core/`: Shared Dart logic containing the WebSocket server, mDNS utility definitions, and OTA update logic.
* `android/`: The Android companion app. It hosts the WebSocket and HTTP file servers, broadcasts its presence via mDNS, and displays a pairing QR code.
* `mac/`: The macOS menubar app. It discovers the Android device, scans the QR code for pairing, receives clipboard updates, and provides the file browser UI.

## Build Instructions

### Prerequisites
- Flutter SDK (stable channel)
- Android Studio (for Android build)
- Xcode (for macOS build)

### 1. Build the Android Companion App
```bash
cd android
flutter pub get
flutter build apk
```
This will generate an APK file located at `android/build/app/outputs/flutter-apk/app-release.apk`.

### 2. Build the macOS Menubar App
```bash
cd mac
flutter pub get
flutter build macos
```
This will generate a macOS application located at `mac/build/macos/Build/Products/Release/mac.app`.

## License
MIT License
