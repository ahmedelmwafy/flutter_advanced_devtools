// lib/core/dev_tools/widgets/dev_tools_overlay.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_advanced_devtools/dev_tools_config.dart';
import 'package:flutter_advanced_devtools/firebase_debug_service.dart';
import 'package:flutter_advanced_devtools/network_logger.dart';
import 'package:flutter_advanced_devtools/exception_logger.dart';
import 'package:flutter_advanced_devtools/performance_monitor.dart';
import 'package:flutter_advanced_devtools/ui_event_logger.dart';
import 'package:flutter_advanced_devtools/dev_tools_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' hide Priority;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Modern Dev Tools Overlay with clean card-based UI
class DevToolsOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onEnvironmentChanged;

  const DevToolsOverlay({
    super.key,
    required this.onClose,
    this.onEnvironmentChanged,
  });

  @override
  State<DevToolsOverlay> createState() => _DevToolsOverlayState();
}

class _DevToolsOverlayState extends State<DevToolsOverlay> {
  final DevToolsConfig _config = DevToolsConfig();
  final NetworkLogger _networkLogger = NetworkLogger();
  final ExceptionLogger _exceptionLogger = ExceptionLogger();
  final FirebaseDebugService _firebaseService = FirebaseDebugService();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final UIEventLogger _uiEventLogger = UIEventLogger();
  final TextEditingController _customUrlController = TextEditingController();

  int _selectedIndex = 0;
  bool _dioLoggerEnabled = true;
  bool _networkAnalysisEnabled = false;
  String _currentLanguage = 'en';

  // New state for additional tabs
  String? _fcmToken;
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _deviceInfo;
  bool _isLoadingFcm = false;
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  final List<_NavItem> _navItems = [
    _NavItem(Icons.person_outline, 'dev_tools_tab_user'),
    _NavItem(Icons.dns_outlined, 'dev_tools_environment'),
    _NavItem(Icons.wifi_outlined, 'dev_tools_network'),
    _NavItem(Icons.notifications_outlined, 'dev_tools_tab_push'),
    _NavItem(Icons.storage_outlined, 'dev_tools_tab_storage'),
    _NavItem(Icons.security, 'dev_tools_tab_permissions'),
    _NavItem(Icons.error_outline, 'dev_tools_tab_exceptions'),
    _NavItem(Icons.speed, 'dev_tools_tab_performance'),
    _NavItem(Icons.notification_important_outlined, 'dev_tools_tab_ui_events'),
    _NavItem(Icons.tune_outlined, 'dev_tools_settings'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDeviceInfo();
    _loadPermissions();
    _networkLogger.addListener(_refresh);
    _exceptionLogger.addListener(_refresh);
    _firebaseService.addListener(_refresh);
    _performanceMonitor.addListener(_refresh);
    _uiEventLogger.addListener(_refresh);
    _performanceMonitor.startMonitoring();
  }

  Future<void> _loadPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.notification,
      Permission.location,
      Permission.photos,
      Permission.storage,
    ];

    final Map<Permission, PermissionStatus> statuses = {};
    for (final p in permissions) {
      statuses[p] = await p.status;
    }

    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
      });
    }
  }

  void _loadSettings() {
    _dioLoggerEnabled = _config.isDioLoggerEnabled;
    _networkAnalysisEnabled = _config.isNetworkAnalysisEnabled;
    _currentLanguage =
        (DevToolsPreferences.getData(key: 'lang') as String?) ?? 'en';
    _customUrlController.text = _config.currentBaseUrl;
  }

  Future<void> _loadDeviceInfo() async {
    // Load package info
    _packageInfo = await PackageInfo.fromPlatform();

    // Load device info
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfoPlugin.androidInfo;
      _deviceInfo = {
        'Device': '${info.manufacturer} ${info.model}',
        'Android Version': info.version.release,
        'SDK': info.version.sdkInt.toString(),
        'Brand': info.brand,
        'Hardware': info.hardware,
        'Display': info.display,
        'Is Physical': info.isPhysicalDevice.toString(),
      };
    } else if (Platform.isIOS) {
      final info = await deviceInfoPlugin.iosInfo;
      _deviceInfo = {
        'Device': info.model,
        'Name': info.name,
        'iOS Version': info.systemVersion,
        'System': info.systemName,
        'Is Physical': info.isPhysicalDevice.toString(),
      };
    }

    if (mounted) setState(() {});
  }

  void _refresh() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      setState(() {});
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    _networkLogger.removeListener(_refresh);
    _exceptionLogger.removeListener(_refresh);
    _firebaseService.removeListener(_refresh);
    _performanceMonitor.removeListener(_refresh);
    _uiEventLogger.removeListener(_refresh);
    _performanceMonitor.dispose();
    super.dispose();
  }

  String _getLocalizedEnvName(String name) {
    switch (name.toLowerCase()) {
      case 'development':
        return 'dev_tools_development'.tr();
      case 'staging':
        return 'dev_tools_staging'.tr();
      case 'production':
        return 'dev_tools_production'.tr();
      case 'custom':
        return 'dev_tools_custom'.tr();
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope.none(
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => Container(
            color: Colors.black54,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      children: [
                        _buildHeader(),
                        _buildNavBar(),
                        Expanded(child: _buildContent()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = _config.theme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bug_report_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dev_tools_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildBadge(
                      DevToolsConfig.buildModeString.toUpperCase(),
                      DevToolsConfig.isRelease ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    _buildBadge(
                      _getLocalizedEnvName(_config.currentEnvironmentName),
                      Colors.white24,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'dev_tools_close'.tr(),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _config.theme.primaryColor
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildUserContent();
      case 1:
        return _buildEnvironmentContent();
      case 2:
        return _buildNetworkContent();
      case 3:
        return _buildPushContent();
      case 4:
        return _buildStorageContent();
      case 5:
        return _buildPermissionsContent();
      case 6:
        return _buildExceptionsContent();
      case 7:
        return _buildPerformanceContent();
      case 8:
        return _buildUIEventsContent();
      case 9:
        return _buildSettingsContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserContent() {
    final userToken =
        (DevToolsPreferences.getData(key: 'user_token') as String?) ?? '';
    final refreshToken =
        (DevToolsPreferences.getData(key: 'refresh_token') as String?) ?? '';
    final hasToken = userToken.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          title: 'dev_tools_auth_status'.tr(),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      hasToken ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasToken ? Icons.check_circle : Icons.warning,
                      color: hasToken ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      hasToken
                          ? 'dev_tools_user_logged_in'.tr()
                          : 'dev_tools_no_user_session'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hasToken
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (hasToken) ...[
          _buildCard(
            title: 'dev_tools_access_token'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _truncateToken(userToken),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(
                          userToken,
                          'dev_tools_token_copied'.tr(),
                        ),
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text('dev_tools_copy'.tr()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(text: userToken),
                        ),
                        icon: const Icon(Icons.share, size: 16),
                        label: Text('dev_tools_share'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (refreshToken.isNotEmpty) ...[
          _buildCard(
            title: 'dev_tools_refresh_token'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _truncateToken(refreshToken),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _copyToClipboard(refreshToken, 'dev_tools_copied'.tr()),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text('dev_tools_copy_refresh_token'.tr()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildCard(
          title: 'dev_tools_app_info'.tr(),
          child: Column(
            children: [
              if (_packageInfo != null) ...[
                _buildInfoTile('App Name', _packageInfo!.appName),
                _buildInfoTile('Version', _packageInfo!.version),
                _buildInfoTile('Build Number', _packageInfo!.buildNumber),
                _buildInfoTile(
                  'Package',
                  _packageInfo!.packageName,
                  mono: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_deviceInfo != null)
          _buildCard(
            title: 'dev_tools_device_info'.tr(),
            child: Column(
              children: _deviceInfo!.entries
                  .map((e) => _buildInfoTile(e.key, e.value.toString()))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPushContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          title: 'dev_tools_fcm_token'.tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingFcm)
                const Center(child: CircularProgressIndicator())
              else if (_fcmToken != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _fcmToken!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(
                          _fcmToken!,
                          'dev_tools_fcm_copied'.tr(),
                        ),
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text('dev_tools_copy'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _config.theme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => SharePlus.instance.share(
                          ShareParams(text: _fcmToken!),
                        ),
                        icon: const Icon(Icons.share, size: 16),
                        label: Text('dev_tools_share'.tr()),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'dev_tools_no_fcm_token'.tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadFcmToken,
                    icon: const Icon(Icons.refresh),
                    label: Text('dev_tools_get_fcm_token'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _config.theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_test_notifications'.tr(),
          child: Column(
            children: [
              _buildActionTile(
                'dev_tools_send_test_notification'.tr(),
                Icons.notifications_active,
                () {
                  _sendTestNotification();
                },
              ),
              _buildActionTile(
                'dev_tools_check_permission'.tr(),
                Icons.verified_user,
                () async {
                  final settings = await FirebaseMessaging.instance
                      .getNotificationSettings();
                  _showToast(
                    'Permission: ${settings.authorizationStatus.name}',
                  );
                },
              ),
              _buildActionTile(
                'dev_tools_request_permission'.tr(),
                Icons.app_settings_alt,
                () async {
                  final settings =
                      await FirebaseMessaging.instance.requestPermission();
                  _showToast(
                    'Permission: ${settings.authorizationStatus.name}',
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_topic_management'.tr(),
          child: Column(
            children: [
              _buildActionTile(
                'dev_tools_subscribe_test'.tr(),
                Icons.add_circle_outline,
                () async {
                  await FirebaseMessaging.instance.subscribeToTopic('test');
                  _showToast('dev_tools_subscribed'.tr());
                },
              ),
              _buildActionTile(
                'dev_tools_unsubscribe_test'.tr(),
                Icons.remove_circle_outline,
                () async {
                  await FirebaseMessaging.instance.unsubscribeFromTopic('test');
                  _showToast('dev_tools_unsubscribed'.tr());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageContent() {
    final userToken =
        (DevToolsPreferences.getData(key: 'user_token') as String?) ?? '';
    final refreshToken =
        (DevToolsPreferences.getData(key: 'refresh_token') as String?) ?? '';
    final lang = (DevToolsPreferences.getData(key: 'lang') as String?) ?? 'en';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          title: 'dev_tools_cached_data'.tr(),
          child: Column(
            children: [
              _buildStorageItem(
                'dev_tools_user_token'.tr(),
                userToken.isNotEmpty
                    ? '${userToken.length} ${"dev_tools_chars".tr()}'
                    : 'dev_tools_empty'.tr(),
              ),
              const Divider(height: 1),
              _buildStorageItem(
                'dev_tools_refresh_token'.tr(),
                refreshToken.isNotEmpty
                    ? '${refreshToken.length} ${"dev_tools_chars".tr()}'
                    : 'dev_tools_empty'.tr(),
              ),
              const Divider(height: 1),
              _buildStorageItem('dev_tools_language'.tr(), lang),
              const Divider(height: 1),
              _buildStorageItem(
                'dev_tools_environment'.tr(),
                _getLocalizedEnvName(_config.currentEnvironmentName),
              ),
              const Divider(height: 1),
              _buildStorageItem(
                'dev_tools_base_url'.tr(),
                _config.currentBaseUrl,
              ),
              const Divider(height: 1),
              _buildStorageItem(
                'dev_tools_dio_logger'.tr(),
                _config.isDioLoggerEnabled
                    ? 'dev_tools_on'.tr()
                    : 'dev_tools_off'.tr(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_storage_actions'.tr(),
          child: Column(
            children: [
              _buildActionTile(
                'dev_tools_clear_user_token'.tr(),
                Icons.person_off,
                () async {
                  await DevToolsPreferences.saveData(
                      key: 'user_token', value: '');
                  setState(() {});
                  _showToast('dev_tools_token_cleared'.tr());
                },
              ),
              _buildActionTile(
                'dev_tools_clear_refresh_token'.tr(),
                Icons.refresh,
                () async {
                  await DevToolsPreferences.saveData(
                      key: 'refresh_token', value: '');
                  setState(() {});
                  _showToast('dev_tools_refresh_token_cleared'.tr());
                },
              ),
              _buildActionTile(
                'dev_tools_clear_all_auth'.tr(),
                Icons.logout,
                () async {
                  await DevToolsPreferences.saveData(
                      key: 'user_token', value: '');
                  await DevToolsPreferences.saveData(
                      key: 'refresh_token', value: '');
                  setState(() {});
                  _showToast('dev_tools_all_auth_cleared'.tr());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_export_data'.tr(),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final data = '''
Storage Export
=======================
Date: ${DateTime.now()}

User Token: ${userToken.isNotEmpty ? 'Present (${userToken.length} chars)' : 'Empty'}
Refresh Token: ${refreshToken.isNotEmpty ? 'Present' : 'Empty'}
Language: $lang
Environment: ${_config.currentEnvironmentName}
Base URL: ${_config.currentBaseUrl}

App Version: ${_packageInfo?.version ?? 'N/A'}
Build: ${_packageInfo?.buildNumber ?? 'N/A'}
''';
                    // ignore: deprecated_member_use
                    Share.share(data, subject: 'Storage Export');
                  },
                  icon: const Icon(Icons.file_download),
                  label: Text('dev_tools_export_storage_info'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsContent() {
    final permissions = [
      Permission.camera,
      Permission.notification,
      Permission.location,
      Permission.photos,
      Permission.storage,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          title: 'dev_tools_tab_permissions'.tr(),
          child: Column(
            children: permissions.map((p) => _buildPermissionTile(p)).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_settings'.tr(),
          child: _buildActionTile(
            'dev_tools_open_settings'.tr(),
            Icons.settings_applications,
            () => openAppSettings(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionTile(Permission permission) {
    final status = _permissionStatuses[permission];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                _getPermissionIcon(permission),
                size: 22,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getPermissionName(permission),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (status != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getPermissionColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getPermissionColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getLocalizedStatus(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getPermissionColor(status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!status.isGranted)
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () async {
                        await permission.request();
                        _loadPermissions();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _config.theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'dev_tools_request'.tr(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ] else
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  IconData _getPermissionIcon(Permission permission) {
    if (permission == Permission.camera) return Icons.camera_alt;
    if (permission == Permission.notification) return Icons.notifications;
    if (permission == Permission.location) return Icons.location_on;
    if (permission == Permission.photos) return Icons.photo_library;
    if (permission == Permission.storage) return Icons.sd_storage;
    if (permission == Permission.microphone) return Icons.mic;
    if (permission == Permission.contacts) return Icons.contacts;
    if (permission == Permission.bluetooth) return Icons.bluetooth;
    return Icons.perm_device_information;
  }

  String _getPermissionName(Permission permission) {
    if (permission == Permission.camera) {
      return 'dev_tools_permission_camera'.tr();
    }
    if (permission == Permission.notification) {
      return 'dev_tools_permission_notification'.tr();
    }
    if (permission == Permission.location) {
      return 'dev_tools_permission_location'.tr();
    }
    if (permission == Permission.photos) {
      return 'dev_tools_permission_photos'.tr();
    }
    if (permission == Permission.storage) {
      return 'dev_tools_permission_storage'.tr();
    }
    if (permission == Permission.microphone) {
      return 'dev_tools_permission_microphone'.tr();
    }
    if (permission == Permission.contacts) {
      return 'dev_tools_permission_contacts'.tr();
    }
    if (permission == Permission.bluetooth) {
      return 'dev_tools_permission_bluetooth'.tr();
    }
    return permission.toString().split('.').last;
  }

  Color _getPermissionColor(PermissionStatus status) {
    if (status.isGranted) return Colors.green;
    if (status.isDenied) return Colors.orange;
    if (status.isPermanentlyDenied) return Colors.red;
    return Colors.grey;
  }

  String _getLocalizedStatus(PermissionStatus status) {
    if (status.isGranted) return 'dev_tools_permission_granted'.tr();
    if (status.isDenied) return 'dev_tools_permission_denied'.tr();
    if (status.isPermanentlyDenied) {
      return 'dev_tools_permission_permanently_denied'.tr();
    }
    if (status.isRestricted) return 'dev_tools_permission_restricted'.tr();
    if (status.isLimited) return 'dev_tools_permission_limited'.tr();
    if (status.isProvisional) return 'dev_tools_permission_provisional'.tr();
    return status.name;
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPerformanceContent() {
    final monitor = _performanceMonitor;
    final memoryPercent = (monitor.memoryUsageMB / 512).clamp(0.0, 1.0);
    final cpuPercent = monitor.cpuLoad / 100;
    final fpsPercent = (monitor.averageFps / 60).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Memory Card
        _buildCard(
          title: 'dev_tools_memory_usage'.tr(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'dev_tools_current_memory'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${monitor.memoryUsageMB.toStringAsFixed(2)} MB',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: memoryPercent,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getPerformanceColor(memoryPercent),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'dev_tools_max_memory'.tr(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${(monitor.maxRss / (1024 * 1024)).toStringAsFixed(2)} MB',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CPU Card
        _buildCard(
          title: 'dev_tools_cpu_load'.tr(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'dev_tools_estimated_load'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${monitor.cpuLoad.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: cpuPercent,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getPerformanceColor(cpuPercent),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'dev_tools_cpu_note'.tr(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // FPS Card
        _buildCard(
          title: 'dev_tools_frame_rate'.tr(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'dev_tools_average_fps'.tr(),
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${monitor.averageFps.toStringAsFixed(1)} FPS',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fpsPercent,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    fpsPercent > 0.9
                        ? Colors.green
                        : fpsPercent > 0.7
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dev_tools_dropped_frames'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${monitor.droppedFrames}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: fpsPercent > 0.9
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: fpsPercent > 0.9 ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Text(
                      fpsPercent > 0.9
                          ? 'dev_tools_smooth'.tr()
                          : 'dev_tools_janky'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fpsPercent > 0.9 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Performance Tips
        _buildCard(
          title: 'dev_tools_tips'.tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTipItem(Icons.info_outline, 'dev_tools_tip_memory'.tr()),
              const Divider(height: 20),
              _buildTipItem(Icons.info_outline, 'dev_tools_tip_fps'.tr()),
              const Divider(height: 20),
              _buildTipItem(Icons.info_outline, 'dev_tools_tip_cpu'.tr()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _config.theme.primaryColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Color _getPerformanceColor(double percent) {
    if (percent < 0.6) return Colors.green;
    if (percent < 0.8) return Colors.orange;
    return Colors.red;
  }

  Widget _buildUIEventsContent() {
    final events = _uiEventLogger.events;

    return Column(
      children: [
        if (events.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${events.length} ${'dev_tools_events'.tr()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final data = _uiEventLogger.exportAll();
                    // ignore: deprecated_member_use
                    Share.share(data, subject: 'UI Events Export');
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: Text('dev_tools_export'.tr()),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _uiEventLogger.clear();
                  },
                  icon: const Icon(
                    Icons.delete_sweep,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: Text(
                    'dev_tools_clear'.tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: events.isEmpty
              ? _buildEmptyState(
                  'dev_tools_no_ui_events'.tr(),
                  Icons.notifications_none,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildUIEventTile(context, event);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUIEventTile(BuildContext context, UIEvent event) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getEventColor(event.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _getEventIcon(event.type),
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(
        event.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getEventColor(event.type),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.displayType,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                event.timestamp.toString().substring(11, 19),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (event.message != null && event.message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.message!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () {
          _copyToClipboard(event.toExportString(), 'dev_tools_copied'.tr());
        },
        tooltip: 'dev_tools_copy'.tr(),
      ),
      onTap: () => _showUIEventDetails(context, event),
    );
  }

  String _getEventIcon(UIEventType type) {
    switch (type) {
      case UIEventType.toast:
        return '🍞';
      case UIEventType.dialog:
        return '💬';
      case UIEventType.alert:
        return '⚠️';
      case UIEventType.snackbar:
        return '📢';
      case UIEventType.action:
        return '⚡';
      case UIEventType.navigation:
        return '🧭';
    }
  }

  Color _getEventColor(UIEventType type) {
    switch (type) {
      case UIEventType.toast:
        return Colors.blue;
      case UIEventType.dialog:
        return Colors.purple;
      case UIEventType.alert:
        return Colors.orange;
      case UIEventType.snackbar:
        return Colors.teal;
      case UIEventType.action:
        return Colors.green;
      case UIEventType.navigation:
        return Colors.indigo;
    }
  }

  void _showUIEventDetails(BuildContext context, UIEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      event.displayType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        _copyToClipboard(
                          event.toExportString(),
                          'dev_tools_copied'.tr(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildDetailRow('dev_tools_title'.tr(), event.title),
                    const Divider(),
                    _buildDetailRow(
                      'dev_tools_time'.tr(),
                      event.timestamp.toString(),
                    ),
                    if (event.message != null && event.message!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow('dev_tools_message'.tr(), event.message!),
                    ],
                    if (event.metadata != null &&
                        event.metadata!.isNotEmpty) ...[
                      const Divider(),
                      _buildDetailRow(
                        'dev_tools_metadata'.tr(),
                        event.metadata.toString(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildExceptionsContent() {
    final logs = _exceptionLogger.logs;

    return Column(
      children: [
        if (logs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _exceptionLogger.clear();
                  },
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: Text(
                    'dev_tools_clear_exceptions'.tr(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: logs.isEmpty
              ? _buildEmptyState(
                  'dev_tools_no_exceptions'.tr(),
                  Icons.check_circle_outline,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[logs.length - 1 - index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          log.error.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          log.timestamp.toString().substring(11, 19),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        children: [
                          if (log.stackTrace != null)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'dev_tools_stack_trace'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SelectableText(
                                      log.stackTrace.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _copyToClipboard(
                                      'Error: ${log.error}\nStack: ${log.stackTrace}',
                                      'dev_tools_copied'.tr(),
                                    ),
                                    icon: const Icon(Icons.copy, size: 14),
                                    label: Text('dev_tools_copy'.tr()),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          title: 'dev_tools_current_config'.tr(),
          child: Column(
            children: [
              _buildInfoTile(
                'dev_tools_environment'.tr(),
                _getLocalizedEnvName(_config.currentEnvironmentName),
              ),
              _buildInfoTile(
                'dev_tools_base_url'.tr(),
                _config.currentBaseUrl,
                mono: true,
              ),
              _buildInfoTile(
                'dev_tools_build_mode'.tr(),
                DevToolsConfig.buildModeString,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_select_environment'.tr(),
          child: Column(
            children: _config.environments.map((env) {
              final isSelected = _config.currentEnvironmentName == env.name;
              return _buildEnvOption(env, isSelected);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_custom_base_url'.tr(),
          child: Column(
            children: [
              TextField(
                controller: _customUrlController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'https://api.yourdomain.com',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyCustomUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('dev_tools_apply_custom_url'.tr()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnvOption(Environment env, bool isSelected) {
    final isProduction = env.isProduction;

    return GestureDetector(
      onTap: () => _selectEnvironment(env),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? _config.theme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _config.theme.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isProduction
                    ? Colors.red
                    : env.name.toLowerCase() == 'staging'
                        ? Colors.orange
                        : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLocalizedEnvName(env.name),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? _config.theme.primaryColor
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    env.baseUrl,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _config.theme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _selectEnvironment(Environment env) async {
    await _config.setEnvironment(env);
    widget.onEnvironmentChanged?.call();
    setState(() {});
    _showToast(
      '${'dev_tools_environment'.tr()}: ${_getLocalizedEnvName(env.name)}',
    );
  }

  void _applyCustomUrl() async {
    final url = _customUrlController.text.trim();
    if (url.isNotEmpty) {
      await _config.setBaseUrl(url);
      widget.onEnvironmentChanged?.call();
      setState(() {});
      _showToast('dev_tools_custom_url_applied'.tr());
    }
  }

  Widget _buildNetworkContent() {
    final entries = _networkLogger.entries;
    final stats = _networkLogger.getStatistics();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                'dev_tools_stat_total'.tr(),
                '${stats['total']}',
                Colors.blue,
              ),
              _buildStatChip(
                'dev_tools_stat_ok'.tr(),
                '${stats['successful']}',
                Colors.green,
              ),
              _buildStatChip(
                'dev_tools_stat_failed'.tr(),
                '${stats['failed']}',
                Colors.red,
              ),
              _buildStatChip(
                'dev_tools_stat_avg'.tr(),
                '${stats['avgDuration']}ms',
                Colors.orange,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${entries.length} requests',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Row(
                children: [
                  if (entries.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _shareAllLogs(entries),
                      icon: const Icon(Icons.share, size: 16),
                      label: Text('dev_tools_share'.tr()),
                      style: TextButton.styleFrom(
                        foregroundColor: _config.theme.primaryColor,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      _networkLogger.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text('dev_tools_clear_logs'.tr()),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? _buildEmptyState(
                  'dev_tools_no_requests'.tr(),
                  Icons.wifi_off_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, i) =>
                      _buildRequestItem(context, entries[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRequestItem(BuildContext context, NetworkLogEntry entry) {
    final statusColor = entry.hasError || entry.isServerError
        ? Colors.red
        : entry.isClientError
            ? Colors.orange
            : Colors.green;

    return GestureDetector(
      onTap: () => _showRequestDetails(context, entry),
      onLongPress: () => _showRequestActions(context, entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: statusColor, width: 3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getMethodColor(entry.method).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.method,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getMethodColor(entry.method),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Uri.parse(entry.url).path,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${entry.statusCode ?? '-'} • ${entry.duration?.inMilliseconds ?? '-'}ms',
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(BuildContext context, NetworkLogEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestDetailSheet(entry: entry),
    );
  }

  void _showRequestActions(BuildContext context, NetworkLogEntry entry) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text('dev_tools_copy_url'.tr()),
              onTap: () {
                Clipboard.setData(ClipboardData(text: entry.url));
                Navigator.pop(context);
                _showToast('dev_tools_url_copied'.tr());
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text('dev_tools_copy_response'.tr()),
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: entry.responseBody ?? ''),
                );
                Navigator.pop(context);
                _showToast('dev_tools_copied'.tr());
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text('dev_tools_share'.tr()),
              onTap: () {
                Navigator.pop(context);
                _shareLog(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareLog(NetworkLogEntry entry) {
    final text = '''
📡 ${entry.method} ${entry.url}
Status: ${entry.statusCode ?? 'N/A'}
Duration: ${entry.duration?.inMilliseconds ?? 'N/A'}ms
Time: ${entry.timestamp}

Request Body:
${entry.requestBody ?? 'None'}

Response:
${entry.responseBody ?? 'None'}
''';
    // ignore: deprecated_member_use
    Share.share(
      text,
      subject: 'Network Log - ${entry.method} ${Uri.parse(entry.url).path}',
    );
  }

  void _shareAllLogs(List<NetworkLogEntry> entries) {
    final buffer = StringBuffer('Network Logs\n${'=' * 30}\n\n');
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      buffer.writeln('[${i + 1}] ${e.method} ${e.url}');
      buffer.writeln(
        '    Status: ${e.statusCode} | ${e.duration?.inMilliseconds}ms',
      );
      buffer.writeln();
    }
    // ignore: deprecated_member_use
    Share.share(buffer.toString(), subject: 'Network Logs');
  }

  Widget _buildSettingsContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          title: 'dev_tools_app_language'.tr(),
          child: Row(
            children: [
              _buildLangButton('English', 'en'),
              const SizedBox(width: 12),
              _buildLangButton('العربية', 'ar'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_debug_options'.tr(),
          child: Column(
            children: [
              _buildSwitchTile(
                'dev_tools_dio_logger'.tr(),
                'dev_tools_dio_logger_desc'.tr(),
                _dioLoggerEnabled,
                (v) async {
                  await _config.setDioLoggerEnabled(v);
                  setState(() => _dioLoggerEnabled = v);
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'dev_tools_network_analysis'.tr(),
                'dev_tools_network_analysis_desc'.tr(),
                _networkAnalysisEnabled,
                (v) async {
                  await _config.setNetworkAnalysisEnabled(v);
                  setState(() => _networkAnalysisEnabled = v);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_firebase'.tr(),
          child: Column(
            children: [
              _buildActionTile(
                'dev_tools_log_screen_view'.tr(),
                Icons.visibility,
                () {
                  _firebaseService.logScreenView(
                    screenName: 'DevToolsTestScreen',
                  );
                  _showToast('dev_tools_screen_view_logged'.tr());
                },
              ),
              _buildActionTile(
                'dev_tools_send_test_events'.tr(),
                Icons.event,
                () {
                  _firebaseService.sendTestEvents();
                  _showToast('dev_tools_test_events_sent'.tr());
                },
              ),
              _buildActionTile(
                'dev_tools_record_test_exception'.tr(),
                Icons.error_outline,
                () {
                  _firebaseService.throwTestException();
                  _showToast('Exception recorded');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_quick_actions'.tr(),
          child: Column(
            children: [
              _buildActionTile(
                'dev_tools_reinitialize_dio'.tr(),
                Icons.refresh,
                () {
                  _config.onReinitializeDio?.call();
                  _showToast('dev_tools_dio_reinitialized'.tr());
                },
              ),
              _buildActionTile(
                'dev_tools_clear_caches'.tr(),
                Icons.cleaning_services,
                () {
                  _networkLogger.clear();
                  _showToast('dev_tools_caches_cleared'.tr());
                },
              ),
              _buildActionTile(
                'dev_tools_reset_defaults'.tr(),
                Icons.restore,
                () async {
                  await _config.resetToDefault();
                  _loadSettings();
                  setState(() {});
                  _showToast('dev_tools_defaults_reset'.tr());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_flutter_tools'.tr(),
          child: Column(
            children: [
              _buildActionTile(
                'dev_tools_hot_reload'.tr(),
                Icons.autorenew,
                () async {
                  try {
                    await WidgetsBinding.instance.performReassemble();
                    _showToast('dev_tools_hot_reload_triggered'.tr());
                  } catch (e) {
                    _showToast('Error: $e');
                  }
                },
              ),
              _buildActionTile(
                'dev_tools_hot_restart'.tr(),
                Icons.restart_alt,
                () {
                  _showToast('dev_tools_hot_restart_note'.tr());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_visual_debug'.tr(),
          child: Column(
            children: [
              _buildSwitchTile(
                'dev_tools_debug_paint'.tr(),
                'dev_tools_debug_paint_desc'.tr(),
                debugPaintSizeEnabled,
                (v) {
                  setState(() {
                    debugPaintSizeEnabled = v;
                  });
                  _showToast(
                    v
                        ? 'dev_tools_debug_paint_on'.tr()
                        : 'dev_tools_debug_paint_off'.tr(),
                  );
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'dev_tools_perf_overlay'.tr(),
                'dev_tools_perf_overlay_desc'.tr(),
                WidgetsApp.showPerformanceOverlayOverride,
                (v) {
                  setState(() {
                    WidgetsApp.showPerformanceOverlayOverride = v;
                  });
                  _showToast(
                    v
                        ? 'dev_tools_perf_overlay_on'.tr()
                        : 'dev_tools_perf_overlay_off'.tr(),
                  );
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'dev_tools_check_mode'.tr(),
                'dev_tools_check_mode_desc'.tr(),
                debugCheckIntrinsicSizes,
                (v) {
                  setState(() {
                    debugCheckIntrinsicSizes = v;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'dev_tools_advanced'.tr(),
          child: Column(
            children: [
              _buildActionTile(
                'dev_tools_force_gc'.tr(),
                Icons.delete_forever,
                () {
                  // Trigger garbage collection by creating pressure
                  List.generate(1000, (i) => []).clear();
                  _showToast('dev_tools_gc_triggered'.tr());
                },
              ),
              _buildActionTile(
                'dev_tools_clear_image_cache'.tr(),
                Icons.image_not_supported,
                () {
                  imageCache.clear();
                  imageCache.clearLiveImages();
                  _showToast('dev_tools_image_cache_cleared'.tr());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLangButton(String label, String code) {
    final isSelected = _currentLanguage == code;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await DevToolsPreferences.init(); // Ensure prefs initialized
          if (!mounted) return;
          // Locale logic would need abstraction or rely on app context helper
          // For now, assuming standard usage or leaving it to user
          // await CachedHelper.setLang(code);
          context.setLocale(Locale(code));
          setState(() => _currentLanguage = code);
          _showToast('dev_tools_language_changed'.tr());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? _config.theme.primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCard({
    required String title,
    required Widget child,
    Color? titleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: titleColor ?? Colors.grey.shade700,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                fontFamily: mono ? 'monospace' : null,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                _copyToClipboard(value, '$label ${"dev_tools_copied".tr()}'),
            child: Icon(Icons.copy, size: 16, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _config.theme.primaryColor),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _config.theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  String _truncateToken(String token) {
    if (token.length <= 50) return token;
    return '${token.substring(0, 25)}...${token.substring(token.length - 20)}';
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast(message);
  }

  void _showToast(String message) {
    _uiEventLogger.logToast(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: _config.theme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _loadFcmToken() async {
    setState(() => _isLoadingFcm = true);
    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      _showToast('Error: $e');
    }
    setState(() => _isLoadingFcm = false);
  }

  Future<void> _sendTestNotification() async {
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const androidDetails = AndroidNotificationDetails(
        'dev_tools_channel',
        'Dev Tools Notifications',
        channelDescription: 'Test notifications from dev tools',
        importance: Importance.max,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🔔 Test Notification',
        'This is a test from Dev Tools - ${DateTime.now().toString().substring(11, 19)}',
        details,
      );

      _showToast('dev_tools_notification_sent'.tr());
    } catch (e) {
      _showToast('Error: $e');
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem(this.icon, this.label);
}

/// Request details bottom sheet
class _RequestDetailSheet extends StatelessWidget {
  final NetworkLogEntry entry;
  const _RequestDetailSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _getMethodColor(entry.method).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.method,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getMethodColor(entry.method),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Uri.parse(entry.url).path,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: DevToolsConfig().theme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: DevToolsConfig().theme.primaryColor,
                    tabs: [
                      Tab(text: 'dev_tools_tab_info'.tr()),
                      Tab(text: 'dev_tools_tab_request'.tr()),
                      Tab(text: 'dev_tools_tab_response'.tr()),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildInfoTab(),
                        _buildBodyTab(entry.requestBody),
                        _buildBodyTab(entry.responseBody),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tile('dev_tools_url'.tr(), entry.url),
        _tile('dev_tools_method'.tr(), entry.method),
        _tile('dev_tools_status'.tr(), '${entry.statusCode ?? 'N/A'}'),
        _tile(
          'dev_tools_duration'.tr(),
          '${entry.duration?.inMilliseconds ?? 'N/A'}ms',
        ),
        _tile('dev_tools_time'.tr(), entry.timestamp.toString()),
      ],
    );
  }

  Widget _buildBodyTab(String? body) {
    if (body == null || body.isEmpty) {
      return Center(child: Text('dev_tools_no_data'.tr()));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        body,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
