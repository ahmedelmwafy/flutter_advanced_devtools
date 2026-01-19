// lib/core/dev_tools/network_logger.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Represents a single network request log entry
class NetworkLogEntry {
  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final Map<String, dynamic>? requestHeaders;
  final dynamic requestBody;
  final int? statusCode;
  final Map<String, dynamic>? responseHeaders;
  final dynamic responseBody;
  final Duration? duration;
  final String? error;
  final bool isCompleted;

  NetworkLogEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseHeaders,
    this.responseBody,
    this.duration,
    this.error,
    this.isCompleted = false,
  });

  /// Create a copy with updated values
  NetworkLogEntry copyWith({
    int? statusCode,
    Map<String, dynamic>? responseHeaders,
    dynamic responseBody,
    Duration? duration,
    String? error,
    bool? isCompleted,
  }) {
    return NetworkLogEntry(
      id: id,
      timestamp: timestamp,
      method: method,
      url: url,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      duration: duration ?? this.duration,
      error: error ?? this.error,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Get status color based on status code
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get hasError => error != null;

  /// Format response body for display
  String get formattedRequestBody {
    if (requestBody == null) return 'No request body';
    try {
      if (requestBody is Map || requestBody is List) {
        return const JsonEncoder.withIndent('  ').convert(requestBody);
      }
      return requestBody.toString();
    } catch (_) {
      return requestBody.toString();
    }
  }

  String get formattedResponseBody {
    if (responseBody == null) return 'No response body';
    try {
      if (responseBody is Map || responseBody is List) {
        return const JsonEncoder.withIndent('  ').convert(responseBody);
      }
      return responseBody.toString();
    } catch (_) {
      return responseBody.toString();
    }
  }

  /// Get request summary for list display
  String get summary {
    if (hasError) return error!;
    if (statusCode != null) {
      return '$statusCode - ${duration?.inMilliseconds ?? 0}ms';
    }
    return 'Pending...';
  }
}

/// Network logger singleton to capture all requests
class NetworkLogger {
  static final NetworkLogger _instance = NetworkLogger._internal();
  factory NetworkLogger() => _instance;
  NetworkLogger._internal();

  /// List of logged entries (max 100)
  final List<NetworkLogEntry> _entries = [];
  static const int _maxEntries = 100;

  /// Listeners for UI updates
  final List<VoidCallback> _listeners = [];

  /// Get all entries (newest first)
  List<NetworkLogEntry> get entries =>
      List.unmodifiable(_entries.reversed.toList());

  /// Get entries count
  int get entriesCount => _entries.length;

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

  /// Log a new request (returns entry ID)
  String logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${_entries.length}';
    final entry = NetworkLogEntry(
      id: id,
      timestamp: DateTime.now(),
      method: method,
      url: url,
      requestHeaders: headers,
      requestBody: body,
    );

    _entries.add(entry);

    // Trim if too many entries
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }

    _notifyListeners();
    return id;
  }

  /// Update an existing entry with response data
  void logResponse({
    required String id,
    required int statusCode,
    Map<String, dynamic>? headers,
    dynamic body,
    required Duration duration,
  }) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(
        statusCode: statusCode,
        responseHeaders: headers,
        responseBody: body,
        duration: duration,
        isCompleted: true,
      );
      _notifyListeners();
    }
  }

  /// Log an error for an existing entry
  void logError({
    required String id,
    required String error,
    Duration? duration,
  }) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(
        error: error,
        duration: duration,
        isCompleted: true,
      );
      _notifyListeners();
    }
  }

  /// Clear all entries
  void clear() {
    _entries.clear();
    _notifyListeners();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final completed = _entries.where((e) => e.isCompleted).toList();
    final successful = completed.where((e) => e.isSuccess).length;
    final failed = completed
        .where((e) => e.hasError || e.isClientError || e.isServerError)
        .length;
    final avgDuration = completed.isEmpty
        ? 0
        : completed
                  .where((e) => e.duration != null)
                  .map((e) => e.duration!.inMilliseconds)
                  .fold<int>(0, (a, b) => a + b) ~/
              completed.where((e) => e.duration != null).length;

    return {
      'total': _entries.length,
      'completed': completed.length,
      'successful': successful,
      'failed': failed,
      'pending': _entries.length - completed.length,
      'avgDuration': avgDuration,
    };
  }
}

/// Dio interceptor for network logging
class NetworkLoggerInterceptor extends Interceptor {
  final NetworkLogger _logger = NetworkLogger();
  final Map<RequestOptions, String> _requestIds = {};
  final Map<RequestOptions, DateTime> _requestStarts = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = _logger.logRequest(
      method: options.method,
      url: options.uri.toString(),
      headers: options.headers.map((k, v) => MapEntry(k, v.toString())),
      body: options.data,
    );
    _requestIds[options] = id;
    _requestStarts[options] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final id = _requestIds.remove(response.requestOptions);
    final startTime = _requestStarts.remove(response.requestOptions);

    if (id != null) {
      final duration = startTime != null
          ? DateTime.now().difference(startTime)
          : Duration.zero;

      _logger.logResponse(
        id: id,
        statusCode: response.statusCode ?? 0,
        headers: response.headers.map.map((k, v) => MapEntry(k, v.join(', '))),
        body: response.data,
        duration: duration,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = _requestIds.remove(err.requestOptions);
    final startTime = _requestStarts.remove(err.requestOptions);

    if (id != null) {
      final duration = startTime != null
          ? DateTime.now().difference(startTime)
          : Duration.zero;

      _logger.logError(
        id: id,
        error: err.message ?? 'Unknown error',
        duration: duration,
      );
    }
    handler.next(err);
  }
}
