import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import 'src/presentation/pages/todo_page.dart';

void main() {
  // Enable framework logging in debug mode
  FlutterCleanArchitecture.enableLogging();

  runApp(const CleanArchitectureExampleApp());
}

/// Example app demonstrating Flutter Clean Architecture v7.
///
/// This app shows:
/// - [UseCase] for single-shot operations (create, toggle, delete todos)
/// - [StreamUseCase] for real-time updates (watch todos)
/// - [BackgroundUseCase] for CPU-intensive work (calculate primes)
/// - [Controller] and [CleanView] for presentation layer
/// - [ControlledWidgetBuilder] for fine-grained UI updates
/// - [Result] and [AppFailure] for type-safe error handling
/// - [CancelToken] for cooperative cancellation
class CleanArchitectureExampleApp extends StatelessWidget {
  const CleanArchitectureExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Architecture Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TodoPage(),
    );
  }
}
