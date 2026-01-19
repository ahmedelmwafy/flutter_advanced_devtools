import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_advanced_devtools/dev_tools_config.dart';
import 'package:flutter_advanced_devtools/widgets/dev_tools_overlay.dart';
import 'package:flutter_advanced_devtools/dev_tools_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:localize_and_translate/localize_and_translate.dart';

/// Global Dev Tools Wrapper - wrap your MaterialApp with this
/// to enable dev tools globally with a floating button on all pages
class DevToolsWrapper extends StatefulWidget {
  final Widget child;
  final DevToolsTheme? theme;

  const DevToolsWrapper({super.key, required this.child, this.theme});

  @override
  State<DevToolsWrapper> createState() => _DevToolsWrapperState();
}

class _DevToolsWrapperState extends State<DevToolsWrapper> {
  // Overlay state
  bool _isExpanded = false;
  bool _isDragging = false;
  // FAB position (bottom right by default)
  double _fabX = 16;
  double _fabY = 100;
  bool _isInitialized = false;

  // Shake detection
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  static const double _shakeThreshold = 15.0;
  static const int _shakeCountThreshold = 3;
  static const int _shakeTimeWindowMs = 1000;
  final List<DateTime> _shakeTimestamps = [];
  double _lastX = 0, _lastY = 0, _lastZ = 0;
  bool _isFirstReading = true;

  @override
  void initState() {
    super.initState();
    if (widget.theme != null) {
      DevToolsConfig().setTheme(widget.theme!);
    }
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
    _shakeTimestamps.removeWhere(
      (t) => now.difference(t).inMilliseconds > _shakeTimeWindowMs,
    );
    _shakeTimestamps.add(now);

    if (_shakeTimestamps.length >= _shakeCountThreshold && !_isExpanded) {
      _shakeTimestamps.clear();
      _toggleExpanded();
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  void _initPosition(BuildContext context) {
    if (_isInitialized) return;
    final size = MediaQuery.of(context).size;
    _fabX = size.width - 70;
    _fabY = size.height - 200;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if dev tools disabled
    if (!DevToolsConfig().isDevToolsEnabled) {
      return widget.child;
    }

    _initPosition(context);

    return Stack(
      children: [
        widget.child,

        // Expanded overlay
        if (_isExpanded)
          Positioned.fill(
            child: DevToolsOverlay(
              onClose: () => setState(() => _isExpanded = false),
              onEnvironmentChanged: () =>
                  DevToolsConfig().onReinitializeDio?.call(),
            ),
          ),

        // Floating button (always visible when not expanded)
        if (!_isExpanded)
          Positioned(left: _fabX, top: _fabY, child: _buildFloatingButton()),
      ],
    );
  }

  Widget _buildFloatingButton() {
    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) {
        setState(() {
          _fabX += details.delta.dx;
          _fabY += details.delta.dy;

          // Keep within bounds
          final size = MediaQuery.of(context).size;
          _fabX = _fabX.clamp(0, size.width - 56);
          _fabY = _fabY.clamp(50, size.height - 100);
        });
      },
      onPanEnd: (_) => setState(() => _isDragging = false),
      onTap: _toggleExpanded,
      onLongPress: () {
        // Haptic feedback on long press
        HapticFeedback.mediumImpact();
        _toggleExpanded();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: _isDragging ? 60 : 52,
        height: _isDragging ? 60 : 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DevToolsConfig().theme.primaryColor,
              DevToolsConfig().theme.secondaryColor,
            ],
          ),
          borderRadius: BorderRadius.circular(_isDragging ? 18 : 14),
          boxShadow: [
            BoxShadow(
              color: DevToolsConfig().theme.primaryColor.withValues(
                    alpha: _isDragging ? 0.5 : 0.3,
                  ),
              blurRadius: _isDragging ? 16 : 12,
              spreadRadius: _isDragging ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.developer_mode_rounded,
              color: Colors.white,
              size: _isDragging ? 28 : 24,
            ),
            // Environment indicator dot
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getEnvironmentColor(),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEnvironmentColor() {
    final env = DevToolsConfig().currentEnvironmentName.toLowerCase();
    switch (env) {
      case 'development':
        return DevToolsConfig().theme.successColor;
      case 'staging':
        return DevToolsConfig().theme.warningColor;
      case 'production':
        return DevToolsConfig().theme.errorColor;
      default:
        return DevToolsConfig().theme.primaryColor;
    }
  }
}

/// Utility class for copying and sharing log data
class DevToolsShareUtils {
  /// Copy text to clipboard with feedback
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String? successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage ?? 'dev_tools_copied_to_clipboard'.tr()),
          duration: const Duration(seconds: 2),
          backgroundColor: DevToolsConfig().theme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Share text via system share sheet
  static Future<void> shareText(String text, {String? subject}) async {
    // ignore: deprecated_member_use
    await Share.share(text, subject: subject);
  }

  /// Format network log for sharing
  static String formatNetworkLog(Map<String, dynamic> log) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📡 NETWORK REQUEST LOG');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('🔗 URL: ${log['url'] ?? 'N/A'}');
    buffer.writeln('📋 Method: ${log['method'] ?? 'N/A'}');
    buffer.writeln('📊 Status: ${log['statusCode'] ?? 'N/A'}');
    buffer.writeln('⏱️ Duration: ${log['duration'] ?? 'N/A'}ms');
    buffer.writeln('📅 Time: ${log['timestamp'] ?? 'N/A'}');
    buffer.writeln();

    if (log['requestHeaders'] != null) {
      buffer.writeln('📤 REQUEST HEADERS:');
      buffer.writeln(_formatJson(log['requestHeaders']));
      buffer.writeln();
    }

    if (log['requestBody'] != null) {
      buffer.writeln('📤 REQUEST BODY:');
      buffer.writeln(_formatJson(log['requestBody']));
      buffer.writeln();
    }

    if (log['responseHeaders'] != null) {
      buffer.writeln('📥 RESPONSE HEADERS:');
      buffer.writeln(_formatJson(log['responseHeaders']));
      buffer.writeln();
    }

    if (log['responseBody'] != null) {
      buffer.writeln('📥 RESPONSE BODY:');
      buffer.writeln(_formatJson(log['responseBody']));
      buffer.writeln();
    }

    if (log['error'] != null) {
      buffer.writeln('❌ ERROR:');
      buffer.writeln(log['error']);
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════════');
    return buffer.toString();
  }

  /// Format all network logs for export
  static String formatAllNetworkLogs(List<dynamic> logs) {
    final buffer = StringBuffer();
    buffer.writeln('╔═══════════════════════════════════════╗');
    buffer.writeln('║     FITTPUB DEV TOOLS - NETWORK LOG    ║');
    buffer.writeln(
      '║     Exported: ${DateTime.now().toString().substring(0, 19)}     ║',
    );
    buffer.writeln('╚═══════════════════════════════════════╝');
    buffer.writeln();
    buffer.writeln('Total Requests: ${logs.length}');
    buffer.writeln();

    for (int i = 0; i < logs.length; i++) {
      buffer.writeln(
        '[${'${i + 1}'.padLeft(3, '0')}] ──────────────────────────────',
      );
      buffer.writeln(formatNetworkLog(logs[i] as Map<String, dynamic>));
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _formatJson(dynamic data) {
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
