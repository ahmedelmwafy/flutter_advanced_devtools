// lib/core/dev_tools/ui_event_logger.dart

import 'package:flutter/foundation.dart';

enum UIEventType { toast, dialog, alert, snackbar, action, navigation }

class UIEvent {
  final String id;
  final UIEventType type;
  final String title;
  final String? message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  UIEvent({
    required this.type,
    required this.title,
    this.message,
    Map<String, dynamic>? metadata,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = DateTime.now(),
       metadata = metadata ?? {};

  String get displayType {
    switch (type) {
      case UIEventType.toast:
        return '🍞 Toast';
      case UIEventType.dialog:
        return '💬 Dialog';
      case UIEventType.alert:
        return '⚠️ Alert';
      case UIEventType.snackbar:
        return '📢 SnackBar';
      case UIEventType.action:
        return '⚡ Action';
      case UIEventType.navigation:
        return '🧭 Navigation';
    }
  }

  String toExportString() {
    final buffer = StringBuffer();
    buffer.writeln('[$displayType] $title');
    buffer.writeln('Time: ${timestamp.toString().substring(11, 19)}');
    if (message != null && message!.isNotEmpty) {
      buffer.writeln('Message: $message');
    }
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.writeln('Data: ${metadata.toString()}');
    }
    return buffer.toString();
  }
}

class UIEventLogger extends ChangeNotifier {
  static final UIEventLogger _instance = UIEventLogger._internal();
  factory UIEventLogger() => _instance;
  UIEventLogger._internal();

  final List<UIEvent> _events = [];
  static const int _maxEvents = 100;

  List<UIEvent> get events => List.unmodifiable(_events);

  void logToast(String message, {Map<String, dynamic>? metadata}) {
    _addEvent(
      UIEvent(type: UIEventType.toast, title: message, metadata: metadata),
    );
  }

  void logDialog(
    String title, {
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    _addEvent(
      UIEvent(
        type: UIEventType.dialog,
        title: title,
        message: message,
        metadata: metadata,
      ),
    );
  }

  void logAlert(
    String title, {
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    _addEvent(
      UIEvent(
        type: UIEventType.alert,
        title: title,
        message: message,
        metadata: metadata,
      ),
    );
  }

  void logSnackBar(String message, {Map<String, dynamic>? metadata}) {
    _addEvent(
      UIEvent(type: UIEventType.snackbar, title: message, metadata: metadata),
    );
  }

  void logAction(
    String action, {
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    _addEvent(
      UIEvent(
        type: UIEventType.action,
        title: action,
        message: details,
        metadata: metadata,
      ),
    );
  }

  void logNavigation(
    String route, {
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    _addEvent(
      UIEvent(
        type: UIEventType.navigation,
        title: route,
        message: details,
        metadata: metadata,
      ),
    );
  }

  void _addEvent(UIEvent event) {
    _events.insert(0, event);

    // Keep only recent events
    if (_events.length > _maxEvents) {
      _events.removeRange(_maxEvents, _events.length);
    }

    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }

  String exportAll() {
    final buffer = StringBuffer();
    buffer.writeln('UI Events Export');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Events: ${_events.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final event in _events) {
      buffer.writeln(event.toExportString());
      buffer.writeln('-' * 50);
    }

    return buffer.toString();
  }

  List<UIEvent> filterByType(UIEventType type) {
    return _events.where((e) => e.type == type).toList();
  }
}
