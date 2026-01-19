// lib/core/dev_tools/widgets/dev_tools_fab.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter_advanced_devtools/dev_tools_config.dart';
import 'package:flutter_advanced_devtools/widgets/dev_tools_overlay.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// A floating action button widget that can be added to any screen
/// to access dev tools. Also listens for device shake.
class DevToolsFab extends StatefulWidget {
  final Widget child;

  const DevToolsFab({super.key, required this.child});

  @override
  State<DevToolsFab> createState() => _DevToolsFabState();
}

class _DevToolsFabState extends State<DevToolsFab> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Shake detection
  static const double _shakeThreshold = 15.0;
  static const int _shakeCountThreshold = 3;
  static const int _shakeTimeWindowMs = 1000;

  final List<DateTime> _shakeTimestamps = [];
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  bool _isFirstReading = true;

  // FAB position
  double _fabX = 20;
  double _fabY = 100;
  bool _isDragging = false;
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _startShakeDetection();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startShakeDetection() {
    if (!DevToolsConfig().isDevToolsEnabled) return;

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (_isFirstReading) {
        _lastX = event.x;
        _lastY = event.y;
        _lastZ = event.z;
        _isFirstReading = false;
        return;
      }

      final double deltaX = (event.x - _lastX).abs();
      final double deltaY = (event.y - _lastY).abs();
      final double deltaZ = (event.z - _lastZ).abs();

      final double acceleration = sqrt(
        deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ,
      );

      if (acceleration > _shakeThreshold) {
        _registerShake();
      }

      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
    });
  }

  void _registerShake() {
    final now = DateTime.now();

    // Remove old shakes outside the time window
    _shakeTimestamps.removeWhere(
      (t) => now.difference(t).inMilliseconds > _shakeTimeWindowMs,
    );

    _shakeTimestamps.add(now);

    if (_shakeTimestamps.length >= _shakeCountThreshold) {
      _shakeTimestamps.clear();
      _openDevTools();
    }
  }

  void _openDevTools() {
    if (_isOverlayVisible) return;

    setState(() => _isOverlayVisible = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DevToolsOverlay(
        onClose: () {
          Navigator.pop(context);
          setState(() => _isOverlayVisible = false);
        },
        onEnvironmentChanged: () {
          DevToolsConfig().onReinitializeDio?.call();
        },
      ),
    ).then((_) {
      setState(() => _isOverlayVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't show FAB if dev tools are disabled
    if (!DevToolsConfig().isDevToolsEnabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _fabX,
          top: _fabY,
          child: GestureDetector(
            onPanStart: (_) => setState(() => _isDragging = true),
            onPanUpdate: (details) {
              setState(() {
                _fabX += details.delta.dx;
                _fabY += details.delta.dy;

                // Keep FAB within screen bounds
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                _fabX = _fabX.clamp(0, screenWidth - 56);
                _fabY = _fabY.clamp(0, screenHeight - 100);
              });
            },
            onPanEnd: (_) => setState(() => _isDragging = false),
            onTap: _openDevTools,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isDragging ? 64 : 48,
              height: _isDragging ? 64 : 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DevToolsConfig().theme.primaryColor,
                    DevToolsConfig().theme.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(_isDragging ? 16 : 12),
                boxShadow: [
                  BoxShadow(
                    color: DevToolsConfig().theme.primaryColor.withOpacity(0.4),
                    blurRadius: _isDragging ? 12 : 8,
                    spreadRadius: _isDragging ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.developer_mode,
                color: Colors.white,
                size: _isDragging ? 28 : 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A simpler inline button for dev tools access
class DevToolsButton extends StatelessWidget {
  final double size;

  const DevToolsButton({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    if (!DevToolsConfig().isDevToolsEnabled) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _openDevTools(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DevToolsConfig().theme.primaryColor,
              DevToolsConfig().theme.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: DevToolsConfig().theme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.developer_mode,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  void _openDevTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DevToolsOverlay(
        onClose: () => Navigator.pop(ctx),
        onEnvironmentChanged: () => DevToolsConfig().onReinitializeDio?.call(),
      ),
    );
  }
}
