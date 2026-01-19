import 'package:flutter/material.dart';
import 'package:flutter_advanced_devtools/widgets/dev_tools_wrapper.dart';
import 'package:flutter_advanced_devtools/widgets/dev_toast.dart';

import 'package:flutter_advanced_devtools/dev_tools_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DevTools with custom environments
  await DevToolsConfig().init(
    customEnvironments: [
      const Environment(
        name: 'Dev',
        baseUrl: 'https://dev.api.com',
        description: 'Development Environment',
      ),
      const Environment(
        name: 'Prod',
        baseUrl: 'https://prod.api.com',
        description: 'Production Environment',
        isProduction: true,
      ),
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DevToolsWrapper(
      child: MaterialApp(
        title: 'Flutter Advanced DevTools Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Flutter Advanced DevTools Example'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    // Use DevToast to demonstrate functionality
    DevToast.success(context, 'Counter incremented to $_counter');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
