// lib/core/dev_tools/performance_monitor.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring service for dev tools
class PerformanceMonitor extends ChangeNotifier {
  // Memory metrics
  int _currentRss = 0;
  int _maxRss = 0;
  double _memoryUsageMB = 0;

  // Frame metrics
  double _averageFps = 60.0;
  int _droppedFrames = 0;
  final List<Duration> _frameTimes = [];
  static const int _maxFrameSamples = 60;

  // CPU approximation (based on frame timing stress)
  double _cpuLoad = 0.0;

  Timer? _monitorTimer;
  FrameCallback? _frameCallback;

  int get currentRss => _currentRss;
  int get maxRss => _maxRss;
  double get memoryUsageMB => _memoryUsageMB;
  double get averageFps => _averageFps;
  int get droppedFrames => _droppedFrames;
  double get cpuLoad => _cpuLoad;

  /// Start monitoring performance
  void startMonitoring() {
    _updateMemory();

    // Monitor memory every 2 seconds
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateMemory();
      notifyListeners();
    });

    // Monitor frames
    _frameCallback = (Duration timestamp) {
      _updateFrameMetrics(timestamp);
      SchedulerBinding.instance.addPostFrameCallback(_frameCallback!);
    };
    SchedulerBinding.instance.addPostFrameCallback(_frameCallback!);
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  void _updateMemory() {
    try {
      final info = ProcessInfo.currentRss;
      final maxInfo = ProcessInfo.maxRss;

      _currentRss = info;
      _maxRss = maxInfo;
      _memoryUsageMB = info / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('Error reading memory: $e');
    }
  }

  DateTime? _lastFrameTime;
  void _updateFrameMetrics(Duration timestamp) {
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final frameDuration = now.difference(_lastFrameTime!);
      _frameTimes.add(frameDuration);

      // Keep only recent samples
      if (_frameTimes.length > _maxFrameSamples) {
        _frameTimes.removeAt(0);
      }

      // Calculate average FPS
      if (_frameTimes.isNotEmpty) {
        final avgDuration =
            _frameTimes.fold<int>(0, (sum, d) => sum + d.inMicroseconds) /
            _frameTimes.length;
        _averageFps = 1000000 / avgDuration;

        // Count dropped frames (> 16.67ms = 60fps threshold)
        final dropped = _frameTimes.where((d) => d.inMilliseconds > 17).length;
        _droppedFrames = dropped;

        // Approximate CPU load based on frame consistency
        // More variance = higher load
        final variance = _calculateVariance(_frameTimes);
        _cpuLoad = (variance / 500).clamp(0.0, 100.0);
      }
    }

    _lastFrameTime = now;
  }

  double _calculateVariance(List<Duration> times) {
    if (times.isEmpty) return 0;

    final mean =
        times.fold<int>(0, (sum, d) => sum + d.inMicroseconds) / times.length;
    final variance =
        times.fold<double>(
          0,
          (sum, d) =>
              sum + ((d.inMicroseconds - mean) * (d.inMicroseconds - mean)),
        ) /
        times.length;

    return variance;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
