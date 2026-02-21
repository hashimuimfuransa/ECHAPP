import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:excellencecoachinghub/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Starting minimal Firebase test app...');
    print('Initializing Firebase...');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.windows,
    );
    
    print('Firebase initialized successfully!');
    print('Launching app...');
    
    runApp(const MinimalApp());
  } catch (e, stack) {
    print('ERROR: $e');
    print('STACK: $stack');
    
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text('Firebase Initialization Failed', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Error: $e'),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building minimal app');
    return MaterialApp(
      title: 'Firebase Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Test App')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check, color: Colors.green, size: 64),
              const SizedBox(height: 20),
              const Text('Firebase Connected Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('App is working!'),
            ],
          ),
        ),
      ),
    );
  }
}