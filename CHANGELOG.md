## 1.0.8
* **Critical Bug Fix**: Resolved "Navigator operation requested with a context that does not include a Navigator" crash.
* Fixed navigation context issues in Network Logger and UI Event Logger tabs properly.
* Ensure all bottom sheets and dialogs in DevToolsOverlay use the correct Navigator context.

## 1.0.7
* **Improved API for custom environments initialization**
  * Added `environments` parameter to `init()` method for better developer experience
  * Deprecated `customEnvironments` parameter (use `environments` instead)
  * Developers can now pass custom environments more intuitively
  * Example: `DevToolsConfig().init(environments: [...], onReinitializeDio: ...)`
* Enhanced documentation with clearer parameter descriptions

## 1.0.6
* **Fixed all deprecated API warnings** for Flutter compatibility.
* Replaced deprecated `withOpacity()` with `withValues(alpha:)` (4 occurrences).
* Replaced deprecated `Share.share()` with `SharePlus.instance.share()` (2 occurrences).
* Added missing exports for `UIEventLogger` and `DevToast` in main library.
* Fixed example app compilation errors and API usage.
* Added comprehensive example demonstrating all features.
* **Zero warnings, zero errors** - fully compatible with latest Flutter/Dart.

## 1.0.5
* **Added 6 professional screenshots** showcasing all major features.
* Added comprehensive documentation for pub.dev publication.
* Refactored README with detailed Dio integration instructions.
* Added screenshot directory structure and preparation guide.
* Added helper scripts for screenshot optimization and renaming.
* Updated all GitHub URLs to correct repository.
* Improved package documentation and examples.
* **Ready for pub.dev publication.**

## 1.0.4
* Removed project-specific default URLs and branding.
* Added support for custom environments initialization.

## 1.0.3
* Fixed remaining hardcoded strings.

## 1.0.2
* Added localization support (English and Arabic).
* Added missing localizations for new keys.

## 1.0.1

* Fixed the issue with the floating button not being visible.
* Added new tabs for Firebase debugging tools, UI event logging, and performance monitoring.
* Added new features:
  * Network logging with Dio interceptors.
  * Environment management (switch between Dev, Staging, Prod).
  * Device information display.
  * Exception logging and handling.
  * Customizable theming.
  * Permission handling and viewing.
  * Firebase debugging tools.
