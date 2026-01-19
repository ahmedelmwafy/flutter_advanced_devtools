// lib/core/dev_tools/dev_tools_config.dart

import 'package:flutter_advanced_devtools/dev_tools_preferences.dart';
import 'package:flutter_advanced_devtools/dev_tools_theme.dart';
import 'package:flutter/foundation.dart';

/// Build mode enum
enum BuildMode { debug, profile, release }

/// Predefined environment configurations
class Environment {
  final String name;
  final String baseUrl;
  final String description;
  final bool isProduction;

  const Environment({
    required this.name,
    required this.baseUrl,
    required this.description,
    this.isProduction = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Environment &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          baseUrl == other.baseUrl;

  @override
  int get hashCode => name.hashCode ^ baseUrl.hashCode;
}

/// DevTools configuration manager
class DevToolsConfig {
  static final DevToolsConfig _instance = DevToolsConfig._internal();
  factory DevToolsConfig() => _instance;
  DevToolsConfig._internal();

  /// Shared Preferences keys
  static const String _baseUrlKey = 'dev_tools_base_url';
  static const String _environmentNameKey = 'dev_tools_environment';
  static const String _dioLoggerEnabledKey = 'dev_tools_dio_logger';
  static const String _networkAnalysisEnabledKey = 'dev_tools_network_analysis';

  /// Predefined environments
  /// Configurable environments
  List<Environment> _environments = [
    const Environment(
      name: 'Development',
      baseUrl: 'https://api.dev.example.com/',
      description: 'Development server for testing',
    ),
    const Environment(
      name: 'Staging',
      baseUrl: 'https://api.staging.example.com/',
      description: 'Staging server for QA',
    ),
    const Environment(
      name: 'Production',
      baseUrl: 'https://api.example.com/',
      description: 'Live production server',
      isProduction: true,
    ),
  ];

  List<Environment> get environments => _environments;

  /// Get default environment based on build mode
  Environment get defaultEnvironment {
    if (isRelease) {
      // In release mode, default to Production
      return _environments.firstWhere(
        (e) => e.name == 'Production',
        orElse: () => _environments.last,
      );
    } else {
      // In debug/profile mode, default to Development
      return _environments.firstWhere(
        (e) => e.name == 'Development',
        orElse: () => _environments.first,
      );
    }
  }

  /// Current configuration state
  String _currentBaseUrl = '';
  String _currentEnvironmentName = '';
  bool _dioLoggerEnabled = true;
  bool _networkAnalysisEnabled = false;
  bool _isInitialized = false;
  DevToolsTheme _theme = const DevToolsTheme();

  // Callback for Dio re-initialization
  Future<void> Function()? onReinitializeDio;

  /// Build mode detection
  static BuildMode get buildMode {
    if (kReleaseMode) return BuildMode.release;
    if (kProfileMode) return BuildMode.profile;
    return BuildMode.debug;
  }

  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;

  /// Get build mode as string
  static String get buildModeString {
    switch (buildMode) {
      case BuildMode.debug:
        return 'Debug';
      case BuildMode.profile:
        return 'Profile';
      case BuildMode.release:
        return 'Release';
    }
  }

  /// Getters
  String get currentBaseUrl =>
      _currentBaseUrl.isEmpty ? defaultEnvironment.baseUrl : _currentBaseUrl;
  String get currentEnvironmentName => _currentEnvironmentName.isEmpty
      ? defaultEnvironment.name
      : _currentEnvironmentName;
  bool get isDioLoggerEnabled => _dioLoggerEnabled;
  bool get isNetworkAnalysisEnabled => _networkAnalysisEnabled;
  bool get isInitialized => _isInitialized;
  DevToolsTheme get theme => _theme;

  /// Get current environment object
  Environment? get currentEnvironment {
    try {
      return _environments.firstWhere((e) => e.name == currentEnvironmentName);
    } catch (_) {
      return null;
    }
  }

  /// Check if dev tools should be enabled
  /// Only enabled in debug/profile mode, disabled in release
  bool get isDevToolsEnabled => !isRelease;

  /// Initialize configuration from stored preferences
  Future<void> init({
    Future<void> Function()? onReinitializeDio,
    List<Environment>? customEnvironments,
  }) async {
    if (customEnvironments != null && customEnvironments.isNotEmpty) {
      _environments = customEnvironments;
    }
    if (onReinitializeDio != null) {
      this.onReinitializeDio = onReinitializeDio;
    }
    final savedBaseUrl = DevToolsPreferences.getData(key: _baseUrlKey);
    final savedEnvName = DevToolsPreferences.getData(key: _environmentNameKey);

    // Use saved values if available, otherwise use build-mode defaults
    if (savedBaseUrl != null && savedEnvName != null) {
      _currentBaseUrl = savedBaseUrl;
      _currentEnvironmentName = savedEnvName;
    } else {
      // First run - set defaults based on build mode
      _currentBaseUrl = defaultEnvironment.baseUrl;
      _currentEnvironmentName = defaultEnvironment.name;
    }

    // In release mode, disable logging by default
    if (isRelease) {
      _dioLoggerEnabled =
          DevToolsPreferences.getData(key: _dioLoggerEnabledKey) ?? false;
      _networkAnalysisEnabled = false; // Always disabled in release
    } else {
      _dioLoggerEnabled =
          DevToolsPreferences.getData(key: _dioLoggerEnabledKey) ?? true;
      _networkAnalysisEnabled =
          DevToolsPreferences.getData(key: _networkAnalysisEnabledKey) ?? false;
    }

    _isInitialized = true;
  }

  /// Set base URL (will also try to match an environment)
  Future<void> setBaseUrl(String url) async {
    _currentBaseUrl = url;
    await DevToolsPreferences.saveData(key: _baseUrlKey, value: url);

    // Try to match an environment
    final matchedEnv = _environments.where((e) => e.baseUrl == url).firstOrNull;
    if (matchedEnv != null) {
      _currentEnvironmentName = matchedEnv.name;
      await DevToolsPreferences.saveData(
        key: _environmentNameKey,
        value: matchedEnv.name,
      );
    } else {
      _currentEnvironmentName = 'Custom';
      await DevToolsPreferences.saveData(
        key: _environmentNameKey,
        value: 'Custom',
      );
    }

    await onReinitializeDio?.call();
  }

  /// Set environment by name
  Future<void> setEnvironment(Environment environment) async {
    _currentBaseUrl = environment.baseUrl;
    _currentEnvironmentName = environment.name;
    await DevToolsPreferences.saveData(
      key: _baseUrlKey,
      value: environment.baseUrl,
    );
    await DevToolsPreferences.saveData(
      key: _environmentNameKey,
      value: environment.name,
    );
    await onReinitializeDio?.call();
  }

  /// Toggle Dio logger
  Future<void> setDioLoggerEnabled(bool enabled) async {
    _dioLoggerEnabled = enabled;
    await DevToolsPreferences.saveData(
      key: _dioLoggerEnabledKey,
      value: enabled,
    );
    await onReinitializeDio?.call();
  }

  /// Toggle network analysis
  Future<void> setNetworkAnalysisEnabled(bool enabled) async {
    // Prevent network analysis in release mode
    if (isRelease) {
      _networkAnalysisEnabled = false;
      return;
    }
    _networkAnalysisEnabled = enabled;
    await DevToolsPreferences.saveData(
      key: _networkAnalysisEnabledKey,
      value: enabled,
    );
  }

  /// Reset to default configuration based on current build mode
  Future<void> resetToDefault() async {
    await setEnvironment(defaultEnvironment);
    await setDioLoggerEnabled(
      !isRelease,
    ); // Enable in debug, disable in release
    await setNetworkAnalysisEnabled(false);
  }

  /// Get environment info for display
  Map<String, String> getEnvironmentInfo() {
    return {
      'Build Mode': buildModeString,
      'Environment': currentEnvironmentName,
      'Base URL': currentBaseUrl,
      'Dio Logger': isDioLoggerEnabled ? 'Enabled' : 'Disabled',
      'Network Analysis': isNetworkAnalysisEnabled ? 'Enabled' : 'Disabled',
      'Dev Tools Available': isDevToolsEnabled ? 'Yes' : 'No',
    };
  }

  /// Set custom theme for dev tools
  void setTheme(DevToolsTheme theme) {
    _theme = theme;
  }
}
