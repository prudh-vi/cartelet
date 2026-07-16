.PHONY: setup build-android build-mac clean test analyze

# Install dependencies for all packages
setup:
	cd core && flutter pub get
	cd android && flutter pub get
	cd mac && flutter pub get

# Build the Android APK
build-android:
	cd android && flutter build apk

# Build the macOS application
build-mac:
	cd mac && flutter build macos

# Clean all build outputs
clean:
	cd core && flutter clean
	cd android && flutter clean
	cd mac && flutter clean

# Run static analysis
analyze:
	cd core && flutter analyze
	cd android && flutter analyze
	cd mac && flutter analyze

# Run tests
test:
	cd android && flutter test
	cd mac && flutter test
