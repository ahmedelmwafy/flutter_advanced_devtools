// lib/core/dev_tools/firebase_debug_service.dart

import 'dart:developer';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_advanced_devtools/exception_logger.dart';

/// Represents a logged analytics event
class AnalyticsEventLog {
  final DateTime timestamp;
  final String eventName;
  final Map<String, dynamic>? parameters;

  AnalyticsEventLog({
    required this.timestamp,
    required this.eventName,
    this.parameters,
  });
}

/// Service for Firebase debugging features
class FirebaseDebugService {
  static final FirebaseDebugService _instance =
      FirebaseDebugService._internal();
  factory FirebaseDebugService() => _instance;
  FirebaseDebugService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  /// Analytics event log (max 50 entries)
  final List<AnalyticsEventLog> _analyticsLog = [];
  static const int _maxLogEntries = 50;

  /// Listeners for UI updates
  final List<VoidCallback> _listeners = [];

  /// Get analytics log (newest first)
  List<AnalyticsEventLog> get analyticsLog =>
      List.unmodifiable(_analyticsLog.reversed.toList());

  /// Add a listener for updates
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // ==================== ANALYTICS ====================

  /// Log an analytics event and track it
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.map((k, v) => MapEntry(k, v)),
      );

      _analyticsLog.add(
        AnalyticsEventLog(
          timestamp: DateTime.now(),
          eventName: name,
          parameters: parameters,
        ),
      );

      if (_analyticsLog.length > _maxLogEntries) {
        _analyticsLog.removeAt(0);
      }

      _notifyListeners();
      log('📊 Analytics Event: $name | Params: $parameters');
    } catch (e) {
      log('❌ Analytics Error: $e');
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
    log('📊 Analytics User ID set: $userId');
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
    log('📊 Analytics User Property: $name = $value');
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
      },
    );
  }

  /// Clear analytics log
  void clearAnalyticsLog() {
    _analyticsLog.clear();
    _notifyListeners();
  }

  /// Send predefined test events
  Future<void> sendTestEvents() async {
    await logEvent(
      name: 'dev_tools_test_event',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'dev_tools',
      },
    );

    await logEvent(
      name: 'button_click',
      parameters: {'button_name': 'test_button', 'screen': 'dev_tools'},
    );

    await logEvent(
      name: 'user_action',
      parameters: {'action_type': 'test', 'duration_ms': 1500},
    );
  }

  // ==================== CRASHLYTICS ====================

  /// Check if Crashlytics collection is enabled
  bool get isCrashlyticsEnabled => _crashlytics.isCrashlyticsCollectionEnabled;

  /// Enable/disable Crashlytics collection
  Future<void> setCrashlyticsEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    log('🔥 Crashlytics collection ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Set user identifier for Crashlytics
  Future<void> setCrashlyticsUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
    log('🔥 Crashlytics User ID set: $userId');
  }

  /// Set custom key-value for Crashlytics
  Future<void> setCrashlyticsCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
    log('🔥 Crashlytics Custom Key: $key = $value');
  }

  /// Log a message to Crashlytics
  Future<void> logToCrashlytics(String message) async {
    await _crashlytics.log(message);
    log('🔥 Crashlytics Log: $message');
  }

  /// Record a non-fatal error
  Future<void> recordError({
    required dynamic exception,
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
    // Also log to local DevTools ExceptionLogger
    ExceptionLogger().logException(exception, stackTrace);
    log('🔥 Crashlytics Error Recorded: $exception');
  }

  /// Force a test crash (use with caution!)
  void forceCrash() {
    log('💥 Forcing test crash...');
    _crashlytics.crash();
  }

  /// Throw a test exception (non-fatal)
  Future<void> throwTestException() async {
    try {
      throw Exception('Dev Tools Test Exception - ${DateTime.now()}');
    } catch (e, stack) {
      await recordError(
        exception: e,
        stackTrace: stack,
        reason: 'Test exception from Dev Tools',
      );
    }
  }

  /// Send unsent reports
  Future<void> sendUnsentReports() async {
    await _crashlytics.sendUnsentReports();
    log('🔥 Crashlytics: Sent unsent reports');
  }

  /// Check for unsent reports
  Future<bool> checkUnsentReports() async {
    return await _crashlytics.checkForUnsentReports();
  }

  /// Delete unsent reports
  Future<void> deleteUnsentReports() async {
    await _crashlytics.deleteUnsentReports();
    log('🔥 Crashlytics: Deleted unsent reports');
  }

  // ==================== COMBINED ACTIONS ====================

  /// Set user info for both Analytics and Crashlytics
  Future<void> setUserInfo({
    required String userId,
    String? email,
    String? name,
  }) async {
    await setUserId(userId);
    await setCrashlyticsUserId(userId);

    if (email != null) {
      await setUserProperty(name: 'email', value: email);
      await setCrashlyticsCustomKey('email', email);
    }

    if (name != null) {
      await setUserProperty(name: 'name', value: name);
      await setCrashlyticsCustomKey('name', name);
    }
  }

  /// Clear user info from both Analytics and Crashlytics
  Future<void> clearUserInfo() async {
    await setUserId(null);
    await setCrashlyticsUserId('');
    log('🔥📊 User info cleared from Analytics and Crashlytics');
  }
}
