import 'package:flutter/foundation.dart';

class ExceptionLogEntry {
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  ExceptionLogEntry(this.error, this.stackTrace, this.timestamp);

  @override
  String toString() {
    return 'Time: $timestamp\nError: $error\nStack: $stackTrace';
  }
}

class ExceptionLogger {
  static final ExceptionLogger _instance = ExceptionLogger._internal();
  factory ExceptionLogger() => _instance;
  ExceptionLogger._internal();

  final List<ExceptionLogEntry> _logs = [];
  final int maxLogs = 50;
  final List<VoidCallback> _listeners = [];

  List<ExceptionLogEntry> get logs => List.unmodifiable(_logs);

  void logException(dynamic error, [StackTrace? stackTrace]) {
    final entry = ExceptionLogEntry(error, stackTrace, DateTime.now());
    if (_logs.length >= maxLogs) {
      _logs.removeAt(0);
    }
    _logs.add(entry);
    _notifyListeners();

    // Also print to console for standard debugging
    debugPrint('🔴 Exception captured by DevTools: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void clear() {
    _logs.clear();
    _notifyListeners();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
