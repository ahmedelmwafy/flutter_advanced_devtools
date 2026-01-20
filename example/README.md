# Flutter Advanced DevTools - Example App

This example demonstrates all major features of the Flutter Advanced DevTools package.

## Features Demonstrated

### 🔥 **1. Network Logger with Dio Integration**
- Shows how to integrate `NetworkLoggerInterceptor` with Dio
- Demonstrates automatic logging of HTTP requests/responses
- Single and multiple API call examples
- Error handling and logging

### 📊 **2. UI Event Logging**
- Manual event logging for button taps
- Automatic toast message logging
- Custom event data tracking

### ⚠️ **3. Exception Logging**
- Demonstrates automatic exception capture
- Shows how to manually log errors
- Stack trace recording

### 🌐 **4. Environment Switching**
- Multiple pre-configured environments
- Automatic Dio re-initialization on environment change
- Base URL switching

### 🎨 **5. Custom Toasts**
- Success, error, info, and warning toasts
- Integration with UI event logger

## How to Run

1. **Install dependencies:**
   ```bash
   cd example
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **Open DevTools:**
   - **Method 1:** Shake your device 3 times
   - **Method 2:** Tap the floating DevTools button
   - **Method 3:** Tap the info icon in the app bar

## What to Try

### Test Network Logging:
1. Tap "Single API Call" button
2. Open DevTools → Network tab
3. See the logged request/response with full details

### Test Multiple Requests:
1. Tap "Multiple Calls" button
2. Open DevTools → Network tab
3. See all 3 requests logged with timing information

### Test Exception Logging:
1. Tap "Trigger Test Error" button
2. Open DevTools → Logs tab
3. See the exception with stack trace

### Test Environment Switching:
1. Open DevTools → Settings or Info tab
2. Switch between "Development" and "Production"
3. Make an API call to see the new base URL in action

### Test Performance Monitoring:
1. Open DevTools → Performance tab
2. See real-time CPU, RAM, and FPS metrics
3. Watch metrics update every 2 seconds

## Code Highlights

### Dio Integration Example:
```dart
class DioHelper {
  static late Dio dio;

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl: DevToolsConfig().currentBaseUrl,
    ));

    // Add NetworkLoggerInterceptor
    if (DevToolsConfig().isDioLoggerEnabled) {
      dio.interceptors.add(NetworkLoggerInterceptor());
    }
  }

  static Future<void> reinitialize() async {
    dio.options.baseUrl = DevToolsConfig().currentBaseUrl;
    dio.interceptors.clear();
    if (DevToolsConfig().isDioLoggerEnabled) {
      dio.interceptors.add(NetworkLoggerInterceptor());
    }
  }
}
```

### DevTools Initialization:
```dart
await DevToolsConfig().init(
  customEnvironments: [
    const Environment(
      name: 'Development',
      baseUrl: 'https://jsonplaceholder.typicode.com/',
      description: 'Development API',
    ),
    const Environment(
      name: 'Production',
      baseUrl: 'https://api.example.com/',
      description: 'Production API',
      isProduction: true,
    ),
  ],
  onReinitializeDio: DioHelper.reinitialize,
);
```

### Manual Event Logging:
```dart
UIEventLogger().logEvent(
  type: UIEventType.buttonTap,
  message: 'Counter button tapped',
  data: {'counter': _counter},
);
```

### Exception Logging:
```dart
try {
  throw Exception('Test error');
} catch (e, stackTrace) {
  ExceptionLogger().logException(
    e,
    stackTrace,
    context: 'Test error from button click',
  );
}
```

## API Used

This example uses [JSONPlaceholder](https://jsonplaceholder.typicode.com/) - a free fake REST API for testing.

Endpoints demonstrated:
- `GET /posts/1` - Get a single post
- `GET /users/1` - Get user details
- `GET /comments?postId=1` - Get post comments

## Learn More

- **Main Package:** [flutter_advanced_devtools](https://pub.dev/packages/flutter_advanced_devtools)
- **GitHub:** [Repository](https://github.com/ahmedelmwafy/flutter_advanced_devtools)
- **Documentation:** [README](https://github.com/ahmedelmwafy/flutter_advanced_devtools#readme)

## Screenshots

See the main package README for screenshots of DevTools in action!

## Support

For issues or questions:
- 📧 Email: ahmedelmwafy@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/ahmedelmwafy/flutter_advanced_devtools/issues)
