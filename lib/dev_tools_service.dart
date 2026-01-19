// lib/core/dev_tools/dev_tools_service.dart

import 'package:flutter_advanced_devtools/dev_tools_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_devtools/widgets/dev_tools_overlay.dart';

/// Service to manage dev tools functionality
class DevToolsService {
  static final DevToolsService _instance = DevToolsService._internal();
  factory DevToolsService() => _instance;
  DevToolsService._internal();

  /// Number of long presses required to open dev tools
  static const int requiredLongPresses = 2;

  /// Time window for long presses (in milliseconds)
  static const int longPressWindowMs = 3000;

  /// Track long press timestamps
  final List<DateTime> _longPressTimestamps = [];

  /// Overlay entry reference
  OverlayEntry? _overlayEntry;

  /// Check if dev tools are visible
  bool get isVisible => _overlayEntry != null;

  /// Check if dev tools are enabled
  /// Disabled in release mode by default
  bool get isEnabled => DevToolsConfig().isDevToolsEnabled;

  /// Register a long press and check if dev tools should open
  /// Returns true if dev tools should be opened (2 long presses within 3 seconds)
  bool registerLongPress() {
    if (!isEnabled) return false;

    final now = DateTime.now();

    // Remove old long presses outside the time window
    _longPressTimestamps.removeWhere(
      (t) => now.difference(t).inMilliseconds > longPressWindowMs,
    );

    // Add current long press
    _longPressTimestamps.add(now);

    // Check if we have enough long presses
    if (_longPressTimestamps.length >= requiredLongPresses) {
      _longPressTimestamps.clear();
      return true;
    }

    return false;
  }

  /// Legacy method - Register a tap (kept for compatibility)
  bool registerTap() {
    return registerLongPress();
  }

  /// Reset long press count
  void resetLongPresses() {
    _longPressTimestamps.clear();
  }

  /// Get current long press count (for debugging/feedback)
  int get currentLongPressCount {
    final now = DateTime.now();
    _longPressTimestamps.removeWhere(
      (t) => now.difference(t).inMilliseconds > longPressWindowMs,
    );
    return _longPressTimestamps.length;
  }

  /// Show dev tools overlay
  void showDevTools(
    BuildContext context, {
    VoidCallback? onEnvironmentChanged,
  }) {
    if (!isEnabled) return;
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => DevToolsOverlay(
        onClose: () => hideDevTools(),
        onEnvironmentChanged: onEnvironmentChanged,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hide dev tools overlay
  void hideDevTools() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Toggle dev tools visibility
  void toggleDevTools(
    BuildContext context, {
    VoidCallback? onEnvironmentChanged,
  }) {
    if (isVisible) {
      hideDevTools();
    } else {
      showDevTools(context, onEnvironmentChanged: onEnvironmentChanged);
    }
  }
}
