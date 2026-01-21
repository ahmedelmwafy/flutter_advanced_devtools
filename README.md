# Flutter Advanced DevTools 🛠️

[![pub package](https://img.shields.io/badge/pub-v0.1.0-blue)](https://pub.dev/packages/flutter_advanced_devtools)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0.0-02569B?logo=flutter)](https://flutter.dev)

A comprehensive, production-ready developer tools package for Flutter applications. Boost your development workflow with powerful debugging, network monitoring, performance tracking, and customizable theming.

---

## 📸 Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/ahmedelmwafy/flutter_advanced_devtools/main/assets/screenshots/main_screen.png" alt="Main Screen" width="250"/>
  <img src="https://raw.githubusercontent.com/ahmedelmwafy/flutter_advanced_devtools/main/assets/screenshots/network_logger.png" alt="Network Logger" width="250"/>
  <img src="https://raw.githubusercontent.com/ahmedelmwafy/flutter_advanced_devtools/main/assets/screenshots/performance_monitor.png" alt="Performance Monitor" width="250"/>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/ahmedelmwafy/flutter_advanced_devtools/main/assets/screenshots/environment_switcher.png" alt="Environment Switcher" width="250"/>
  <img src="https://raw.githubusercontent.com/ahmedelmwafy/flutter_advanced_devtools/main/assets/screenshots/network_details.png" alt="Network Details" width="250"/>
  <img src="https://raw.githubusercontent.com/ahmedelmwafy/flutter_advanced_devtools/main/assets/screenshots/permissions.png" alt="Permissions" width="250"/>
</p>

---


## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎨 **Customizable Theme** | Match your app's branding with preset or custom themes |
| 🌐 **Environment Switcher** | Switch between Dev/Staging/Production environments on-the-fly |
| 📡 **Network Logger** | Full HTTP request/response tracking with Dio integration |
| 👤 **User Info** | View auth tokens, user data, and device information |
| ⚡ **Performance Monitor** | Real-time CPU, RAM, and FPS tracking |
| 🔔 **Push Notifications** | Test and debug Firebase Cloud Messaging |
| 💾 **Storage Inspector** | Browse and inspect cached/stored data |
| 🔐 **Permissions Manager** | Check and request app permissions |
| 📢 **UI Event Logger** | Track toasts, dialogs, and user interactions |
| ⚠️ **Exception Logger** | Catch and view runtime errors |
| ⚙️ **Debug Settings** | Hot reload, debug paint, performance overlay & more |

---

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_advanced_devtools: ^0.1.0
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

### 1. Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:flutter_advanced_devtools/flutter_advanced_devtools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DevTools with your custom environments
  await DevToolsConfig().init(
    environments: [
      const Environment(
        name: 'Development',
        baseUrl: 'https://api.dev.yourapp.com/',
        description: 'Development server',
      ),
      const Environment(
        name: 'Staging',
        baseUrl: 'https://api.staging.yourapp.com/',
        description: 'Staging server for QA',
      ),
      const Environment(
        name: 'Production',
        baseUrl: 'https://api.yourapp.com/',
        description: 'Production server',
        isProduction: true,
      ),
    ],
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DevToolsWrapper(
      child: MaterialApp(
        title: 'My App',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const HomePage(),
      ),
    );
  }
}
```

### 2. Customize Theme (Optional)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = DevToolsConfig();
  await config.init();
  
  // Option 1: Use preset themes
  config.setTheme(DevToolsTheme.purple());
  
  // Option 2: Generate from your app color
  config.setTheme(DevToolsTheme.fromAppColor(Color(0xFF6200EE)));
  
  // Option 3: Fully custom theme
  config.setTheme(DevToolsTheme(
    primaryColor: Color(0xFF1976D2),
    secondaryColor: Color(0xFF64B5F6),
    successColor: Color(0xFF4CAF50),
    warningColor: Color(0xFFFF9800),
    errorColor: Color(0xFFF44336),
  ));
  
  runApp(const MyApp());
}
```

---

## 📡 Network Logger Integration with Dio

The Network Logger automatically captures **ALL** HTTP requests/responses made through your Dio instance, regardless of where in your app they originate.

### Step 1: Create Your Dio Helper

```dart
import 'package:dio/dio.dart';
import 'package:flutter_advanced_devtools/flutter_advanced_devtools.dart';

class DioHelper {
  static late Dio dio;

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl: DevToolsConfig().currentBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      receiveDataWhenStatusError: true,
    ));

    // 🔥 Add NetworkLoggerInterceptor to capture all network activity
    if (DevToolsConfig().isDioLoggerEnabled) {
      dio.interceptors.add(NetworkLoggerInterceptor());
    }

    // Add other interceptors (auth, retry, etc.)
    // dio.interceptors.add(AuthInterceptor());
  }

  static Future<void> reinitialize() async {
    // Update base URL when environment changes
    dio.options.baseUrl = DevToolsConfig().currentBaseUrl;
    
    // Re-add interceptors
    dio.interceptors.clear();
    if (DevToolsConfig().isDioLoggerEnabled) {
      dio.interceptors.add(NetworkLoggerInterceptor());
    }
  }
}
```

### Step 2: Initialize in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DevTools with reinitialize callback
  await DevToolsConfig().init(
    onReinitializeDio: DioHelper.reinitialize, // Called when settings change
    environments: [
      // Your environments...
    ],
  );
  
  // Initialize Dio with interceptor
  DioHelper.init();
  
  runApp(const MyApp());
}
```

### Step 3: Make Requests Anywhere

```dart
// In your repositories, services, or anywhere in your app
class UserRepository {
  Future<List<User>> getUsers() async {
    try {
      final response = await DioHelper.dio.get('/users');
      // ✅ This request is automatically logged in DevTools!
      return (response.data as List)
          .map((json) => User.fromJson(json))
          .toList();
    } catch (e) {
      // ✅ Errors are also logged!
      rethrow;
    }
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    final response = await DioHelper.dio.post('/users', data: data);
    // ✅ POST requests are logged with request/response bodies!
    return User.fromJson(response.data);
  }
}
```

### What Gets Logged?

The Network Logger captures:
- ✅ **All HTTP methods** (GET, POST, PUT, DELETE, PATCH, etc.)
- ✅ **Request details** (URL, headers, body)
- ✅ **Response details** (status code, headers, body)
- ✅ **Timing** (request duration in milliseconds)
- ✅ **Errors** (network failures, timeouts, server errors)
- ✅ **Request origin** (doesn't matter where in your app it's called from!)

### View Network Logs

1. **Shake your device** 3 times (or tap the DevTools FAB)
2. Navigate to the **"Network"** tab
3. See all requests in real-time with:
   - Method badges (GET, POST, etc.)
   - Status codes with color coding
   - Request/response times
   - Full request/response inspection
   - Copy/share functionality

---

## 🎯 How to Access DevTools

### Method 1: Shake Gesture (Recommended)
Shake your device **3 times within 1 second** to toggle DevTools.

### Method 2: Floating Action Button
Tap the floating developer button (visible in debug/profile builds).

### Method 3: Programmatic
```dart
// Trigger from your code (useful for custom gestures)
DevToolsService().toggleOverlay();
```

---

## 📖 Feature Details

### 🌐 Environment Switching

Switch between environments in real-time without rebuilding:

```dart
// Define environments during initialization
await DevToolsConfig().init(
  environments: [
    Environment(
      name: 'Local',
      baseUrl: 'http://localhost:3000/',
      description: 'Local development server',
    ),
    Environment(
      name: 'Development',
      baseUrl: 'https://api.dev.example.com/',
      description: 'Remote dev server',
    ),
    Environment(
      name: 'Production',
      baseUrl: 'https://api.example.com/',
      description: 'Live server',
      isProduction: true,
    ),
  ],
);
```

**Features:**
- Switch environments from DevTools UI
- Automatically reinitializes Dio with new base URL
- Persists selection across app restarts
- Custom environment support

---

### ⚡ Performance Monitoring

Real-time performance metrics updated every 2 seconds:

| Metric | Description |
|--------|-------------|
| **Memory** | Current RAM usage (MB) |
| **CPU** | Estimated CPU load (0-100%) |
| **FPS** | Frame rate & dropped frames |

```dart
// Access performance data programmatically
final stats = PerformanceMonitor().getCurrentStats();
print('Memory: ${stats.memoryUsageMB} MB');
print('CPU: ${stats.cpuUsage}%');
print('FPS: ${stats.fps}');
```

---

### 📢 UI Event Logger

Automatically tracks user interactions:

```dart
import 'package:flutter_advanced_devtools/flutter_advanced_devtools.dart';

// Manually log custom events
UIEventLogger().logEvent(
  type: UIEventType.custom,
  message: 'User completed onboarding',
  data: {'step': 3, 'time_spent': '2m 34s'},
);
```

**Auto-logged events:**
- Button taps
- Navigation changes
- Toasts/SnackBars
- Dialog displays
- Custom user actions

---

### ⚠️ Exception Logger

Catch and view all runtime errors:

```dart
void main() async {
  // Initialize exception handling
  FlutterError.onError = (FlutterErrorDetails details) {
    ExceptionLogger().logException(
      details.exception,
      details.stack,
      context: 'Flutter Framework Error',
    );
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await DevToolsConfig().init();
    runApp(const MyApp());
  }, (error, stack) {
    ExceptionLogger().logException(error, stack, context: 'Async Error');
  });
}
```

---

### 🔐 Permissions Manager

View and request app permissions:

```dart
// The DevTools UI automatically shows:
// - Camera, Location, Storage, Notifications, etc.
// - Current permission status
// - Request button for denied permissions
```

Requires `permission_handler` package (already included).

---

### 🔔 Firebase Debugging

Test push notifications without external tools:

1. View current FCM token
2. Copy token for testing
3. Check notification permissions
4. View last notification payload
5. Test local notifications

---

## ⚙️ Configuration

### Build-Mode Behavior

DevTools automatically adjusts based on build mode:

| Build Mode | DevTools | Network Logger | Performance Monitor |
|------------|----------|----------------|---------------------|
| **Debug** | ✅ Enabled | ✅ Enabled | ✅ Enabled |
| **Profile** | ✅ Enabled | ⚠️ Optional | ✅ Enabled |
| **Release** | ❌ Disabled | ❌ Disabled | ❌ Disabled |

No code changes needed! DevTools is **automatically disabled** in release builds.

### Advanced Configuration

```dart
final config = DevToolsConfig();

// Check current state
print('Build Mode: ${DevToolsConfig.buildModeString}');
print('Base URL: ${config.currentBaseUrl}');
print('Logger Enabled: ${config.isDioLoggerEnabled}');
print('Environment: ${config.currentEnvironmentName}');

// Toggle features
await config.setDioLoggerEnabled(false);
await config.setNetworkAnalysisEnabled(true);

// Reset to defaults
await config.resetToDefault();

// Get environment info
final info = config.getEnvironmentInfo();
```

---

## 🌍 Localization

Built-in support for:
- ✅ **English (EN)**
- ✅ **Arabic (AR)** with full RTL support

**203+ translation keys** covering all DevTools features.

To add your own language, extend the localization files in `assets/lang/`.

---

## 🎨 Theme Customization

### Preset Themes

```dart
DevToolsTheme.material()  // Blue (Material Design)
DevToolsTheme.green()     // Green
DevToolsTheme.orange()    // Orange
DevToolsTheme.purple()    // Purple
DevToolsTheme.red()       // Red
DevToolsTheme.teal()      // Teal
DevToolsTheme.dark()      // Dark mode
```

### Auto-Generate from App Color

```dart
// Automatically creates a harmonious theme
config.setTheme(DevToolsTheme.fromAppColor(
  Theme.of(context).primaryColor,
));
```

### Fully Custom Theme

```dart
config.setTheme(DevToolsTheme(
  primaryColor: Color(0xFF1E88E5),
  secondaryColor: Color(0xFF64B5F6),
  successColor: Color(0xFF43A047),
  warningColor: Color(0xFFFB8C00),
  errorColor: Color(0xFFE53935),
  backgroundColor: Color(0xFFFAFAFA),
  textColor: Color(0xFF212121),
  cardColor: Colors.white,
  borderRadius: 12.0,
  elevation: 4.0,
));
```

---

## 🏗️ Package Structure

```
flutter_advanced_devtools/
├── lib/
│   ├── flutter_advanced_devtools.dart      # Main export file
│   ├── dev_tools_config.dart                # Configuration & state
│   ├── dev_tools_theme.dart                 # Theme system
│   ├── dev_tools_preferences.dart           # Persistent storage
│   ├── dev_tools_service.dart               # Core service
│   ├── network_logger.dart                  # HTTP interceptor 🔥
│   ├── exception_logger.dart                # Error tracking
│   ├── ui_event_logger.dart                 # UI event tracking
│   ├── performance_monitor.dart             # Performance metrics
│   ├── firebase_debug_service.dart          # FCM debugging
│   └── widgets/
│       ├── dev_tools_wrapper.dart           # Root wrapper
│       ├── dev_tools_overlay.dart           # Main UI
│       ├── dev_tools_fab.dart               # Floating button
│       └── dev_toast.dart                   # Custom toasts
├── assets/
│   └── lang/
│       ├── en.json                          # English translations
│       └── ar.json                          # Arabic translations
└── example/                                 # Example app
```

---

## 📚 Examples

Check out the [`/example`](example/) folder for complete examples:

- ✅ **Basic Setup** - Minimal integration
- ✅ **Dio Integration** - Full network logging
- ✅ **Custom Theming** - Theme customization
- ✅ **Environment Switching** - Multi-environment setup
- ✅ **Advanced Configuration** - All features enabled

---

## 🔧 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0                               # For network interceptor
  device_info_plus: ^9.0.0                  # Device information
  package_info_plus: ^4.0.0                 # App version info
  permission_handler: ^11.0.0               # Permissions
  firebase_messaging: ^14.0.0               # FCM support
  flutter_local_notifications: ^16.0.0      # Local notifications
  sensors_plus: ^4.0.0                      # Shake detection
  share_plus: ^7.0.0                        # Share logs
  shared_preferences: ^2.0.0                # Persistent storage
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by modern developer tools and debugging practices
- Built with ❤️ for the Flutter community
- Special thanks to all contributors

---

## 📞 Support

- 📧 Email: ahmedelmwafy@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/ahmedelmwafy/flutter_advanced_devtools/issues)
---

## 🌟 Show Your Support

If this package helped you, please give it a ⭐️ on GitHub!

---

<p align="center">Made with ❤️ for Flutter developers worldwide</p>
