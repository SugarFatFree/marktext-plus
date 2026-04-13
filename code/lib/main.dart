import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MarkTextPlusApp()));
}

class MarkTextPlusApp extends StatelessWidget {
  const MarkTextPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarkText Plus',
      theme: ThemeData.light(),
      home: const Scaffold(
        body: Center(child: Text('MarkText Plus V1.0.1')),
      ),
    );
  }
}
