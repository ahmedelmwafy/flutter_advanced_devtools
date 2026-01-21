import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_advanced_devtools/flutter_advanced_devtools.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DevTools with custom environments
  await DevToolsConfig().init(
    environments: [
      const Environment(
        name: 'Development',
        baseUrl: 'https://jsonplaceholder.typicode.com/',
        description: 'Development API (JSONPlaceholder)',
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

  // Initialize Dio with DevTools Network Logger
  DioHelper.init();

  runApp(const MyApp());
}

/// Dio Helper with Network Logger Integration
class DioHelper {
  static late Dio dio;

  static void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: DevToolsConfig().currentBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        receiveDataWhenStatusError: true,
      ),
    );

    // Add NetworkLoggerInterceptor to capture all network activity
    if (DevToolsConfig().isDioLoggerEnabled) {
      dio.interceptors.add(NetworkLoggerInterceptor());
    }
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DevToolsWrapper(
      child: MaterialApp(
        title: 'Flutter Advanced DevTools Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isLoading = false;
  String _apiResponse = 'No API calls yet';

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    // Log UI event manually
    UIEventLogger().logAction(
      'Counter button tapped',
      details: 'Counter value: $_counter',
      metadata: {'counter': _counter},
    );

    // Show success toast
    DevToast.success(context, 'Counter incremented to $_counter! 🎉');
  }

  Future<void> _testNetworkCall() async {
    setState(() {
      _isLoading = true;
      _apiResponse = 'Loading...';
    });

    try {
      // This request will be automatically logged in DevTools Network tab!
      final response = await DioHelper.dio.get('posts/1');

      setState(() {
        _apiResponse = 'Success! Got post: ${response.data['title']}';
        _isLoading = false;
      });

      if (mounted) {
        DevToast.success(context, 'API call successful! Check Network tab.');
      }
    } catch (e) {
      setState(() {
        _apiResponse = 'Error: $e';
        _isLoading = false;
      });

      if (mounted) {
        DevToast.error(
          context,
          'API call failed! Check Network tab for details.',
        );
      }

      // Log exception
      ExceptionLogger().logException(e, StackTrace.current);
    }
  }

  Future<void> _testMultipleAPICalls() async {
    DevToast.info(context, 'Making multiple API calls...');

    try {
      // Make multiple calls to see them in Network Logger
      await Future.wait([
        DioHelper.dio.get('posts/1'),
        DioHelper.dio.get('users/1'),
        DioHelper.dio.get('comments?postId=1'),
      ]);

      if (mounted) {
        DevToast.success(context, '3 API calls completed! Check Network tab.');
      }
    } catch (e) {
      if (mounted) {
        DevToast.error(context, 'Some API calls failed!');
      }
    }
  }

  void _triggerError() {
    try {
      // Intentionally throw an error to demonstrate exception logging
      throw Exception('This is a test error to demonstrate exception logging!');
    } catch (e, stackTrace) {
      ExceptionLogger().logException(e, stackTrace);

      DevToast.error(context, 'Error triggered! Check Logs tab.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('DevTools Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              DevToast.info(
                context,
                'Shake device or tap FAB to open DevTools! 📱',
              );
            },
            tooltip: 'How to open DevTools',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🛠️ Flutter Advanced DevTools',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This demo showcases key features:\n'
                      '• Network Logger with Dio\n'
                      '• UI Event Tracking\n'
                      '• Exception Logging\n'
                      '• Environment Switching\n'
                      '• Performance Monitoring',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Counter Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Counter Demo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Each increment logs a UI event'),
                    const SizedBox(height: 16),
                    Text(
                      '$_counter',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _incrementCounter,
                      icon: const Icon(Icons.add),
                      label: const Text('Increment Counter'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Network Testing Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Network Logger Demo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All requests are logged in DevTools Network tab',
                    ),
                    const SizedBox(height: 16),
                    Text(_apiResponse, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testNetworkCall,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_download),
                          label: const Text('Single API Call'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testMultipleAPICalls,
                          icon: const Icon(Icons.cloud_sync),
                          label: const Text('Multiple Calls'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Exception Logging Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exception Logger Demo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Trigger an error to see exception logging'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _triggerError,
                      icon: const Icon(Icons.error_outline),
                      label: const Text('Trigger Test Error'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to Open DevTools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Shake your device 3 times\n'
                      '2. Or tap the floating DevTools button\n'
                      '3. Navigate through tabs to explore features',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }
}
