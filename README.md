# FittPub Dev Tools

A comprehensive, production-ready developer tools package for Flutter apps with customizable theming.

## Features

🎨 **Customizable Theme** - Match your app's branding  
👤 **User Info** - Auth status, tokens, device info  
🌐 **Environment Switcher** - Dev/Staging/Production  
📡 **Network Logger** - Request/response tracking  
🔔 **Push Notifications** - FCM testing & debugging  
💾 **Storage Inspector** - View cached data  
🔐 **Permissions** - Check & request permissions  
⚡ **Performance Monitor** - CPU, RAM, FPS tracking  
📢 **UI Events** - Toast/dialog/alert logger  
⚠️ **Exception Logger** - Catch & view errors  
⚙️ **Settings** - Hot reload, debug paint, & more

## Installation

### As a Local Package

1. Copy the `dev_tools` folder to your project:
```
your_project/
  lib/
    core/
      dev_tools/  ← Copy this folder
```

2. Import in your main.dart:
```dart
import 'package:your_app/core/dev_tools/dev_tools_wrapper.dart';
import 'package:your_app/core/dev_tools/dev_tools_config.dart';
import 'package:your_app/core/dev_tools/dev_tools_theme.dart';
```

## Usage

### Basic Setup

Wrap your `MaterialApp` with `DevToolsWrapper`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dev tools config
  await DevToolsConfig().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DevToolsWrapper(
      child: MaterialApp(
        title: 'My App',
        home: HomePage(),
      ),
    );
  }
}
```

### Custom Theme

#### Option 1: Use Preset Themes

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = DevToolsConfig();
  await config.init();
  
  // Choose from preset themes
  config.setTheme(DevToolsTheme.material());  // Blue (default)
  config.setTheme(DevToolsTheme.green());     // Green
  config.setTheme(DevToolsTheme.orange());    // Orange
  config.setTheme(DevToolsTheme.purple());    // Purple
  config.setTheme(DevToolsTheme.red());       // Red
  config.setTheme(DevToolsTheme.teal());      // Teal
  config.setTheme(DevToolsTheme.dark());      // Dark mode
  
  runApp(const MyApp());
}
```

#### Option 2: Match Your App Color

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = DevToolsConfig();
  await config.init();
  
  // Automatically generate theme from your app's primary color
  config.setTheme(DevToolsTheme.fromAppColor(
    Color(0xFF6200EE), // Your app's primary color
  ));
  
  runApp(const MyApp());
}
```

#### Option 3: Full Custom Theme

```dart
void main() async {
  WidgetsFlutterBinding.ensure Initialized();
  
  final config = DevToolsConfig();
  await config.init();
  
  // Create completely custom theme
  config.setTheme(DevToolsTheme(
    primaryColor: Color(0xFF1976D2),
    secondaryColor: Color(0xFF64B5F6),
    successColor: Color(0xFF4CAF50),
    warningColor: Color(0xFFFF9800),
    errorColor: Color(0xFFF44336),
    backgroundColor: Colors.white,
    textColor: Color(0xFF212121),
    cardColor: Colors.white,
  ));
  
  runApp(const MyApp());
}
```

### Change Theme at Runtime

```dart
// In your settings screen or anywhere in the app:
DevToolsConfig().setTheme(DevToolsTheme.purple());

// Or create your own theme picker:
class ThemePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Blue Theme'),
          onTap: () => DevToolsConfig().setTheme(DevToolsTheme.material()),
        ),
        ListTile(
          title: Text('Green Theme'),
          onTap: () => DevToolsConfig().setTheme(DevToolsTheme.green()),
        ),
        // ... more options
      ],
    );
  }
}
```

## How to Access Dev Tools

### Method 1: Shake Device
Shake your device 3 times within 1 second to open dev tools.

### Method 2: Floating Button
Tap the floating developer mode button (visible in debug builds).

### Method 3: Programmatic
```dart
// You can also trigger it programmatically if needed
// (Implementation depends on your state management)
```

## Features Details

### Environment Switching
- **Development**: Testing server
- **Staging**: QA server  
- **Production**: Live server
- **Custom**: Enter any base URL

### Network Logging
- View all HTTP requests/responses
- Filter by method (GET, POST, etc.)
- Copy URLs and responses
- Export logs for sharing
- Statistics dashboard

### Performance Monitoring
- **Memory**: Current & max usage (MB)
- **CPU**: Estimated load (0-100%)
- **FPS**: Average frame rate & dropped frames
- Auto-updates every 2 seconds

### UI Events
Automatically logs:
- Toasts
- Dialogs
- Alerts
- SnackBars
- User actions
- Navigation events

### Visual Debug Tools
- **Debug Paint**: Show widget boundaries
- **Performance Overlay**: FPS & GPU graphs
- **Hot Reload**: Programmatic widget rebuild
- **Image Cache**: Clear cached images
- **Garbage Collection**: Force memory cleanup

## Configuration

### Disable in Release Builds

Dev tools are automatically disabled in release builds. No code changes needed!

```dart
// This check happens automatically:
bool get isDevToolsEnabled => !kReleaseMode;
```

### Custom Environments

```dart
// Add your own environments:
DevToolsConfig().setEnvironment(Environment(
  name: 'My Custom Env',
  baseUrl: 'https://my-server.com/api/',
  description: 'My description',
  isProduction: false,
));
```

## Localization

Dev tools supports:
- ✅ English (EN)
- ✅ Arabic (AR) with RTL support

203+ translation keys included.

## Package Structure

```
dev_tools/
├── dev_tools_config.dart          # Configuration & env management
├── dev_tools_theme.dart            # Theme customization
├── dev_tools_wrapper.dart          # Main wrapper widget
├── performance_monitor.dart        # CPU/RAM/FPS tracking
├── network_logger.dart             # HTTP logging
├── exception_logger.dart           # Error tracking
├── ui_event_logger.dart            # UI interaction logging
├── firebase_debug_service.dart     # Firebase testing
└── widgets/
    ├── dev_tools_overlay.dart      # Main overlay UI
    ├── dev_toast.dart              # Custom toast widget
    └── dev_tools_fab.dart          # Floating action button
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  device_info_plus: ^9.0.0
  package_info_plus: ^4.0.0
  permission_handler: ^11.0.0
  firebase_messaging: ^14.0.0
  flutter_local_notifications: ^16.0.0
  sensors_plus: ^4.0.0
  share_plus: ^7.0.0
```

## Examples

See the `/examples` folder for more detailed examples:
- Basic setup
- Custom theming
- Advanced configuration
- Custom loggers

## License

MIT License - Free to use in your projects!

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## Author

Created for FittPub mobile app - Made with ❤️ by the FittPub team

---

**Note**: This package is production-ready and actively maintained. It's used in the FittPub mobile app serving thousands of users.
