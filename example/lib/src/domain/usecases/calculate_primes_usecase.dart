import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../entities/prime_result.dart';

/// Parameters for the prime calculation.
class PrimeParams {
  /// The nth prime to calculate (e.g., 1000 means find the 1000th prime)
  final int n;

  const PrimeParams(this.n);

  @override
  String toString() => 'PrimeParams(n: $n)';
}

/// UseCase to calculate the nth prime number on a background isolate.
///
/// This demonstrates the [BackgroundUseCase] pattern for CPU-intensive
/// operations that would otherwise block the UI thread.
///
/// ## Example
/// ```dart
/// final subscription = calculatePrimesUseCase(PrimeParams(10000)).listen((result) {
///   result.fold(
///     (primeResult) => print('Found: ${primeResult.value}'),
///     (failure) => print('Error: ${failure.message}'),
///   );
/// });
///
/// // Cancel if needed
/// subscription.cancel();
/// ```
///
/// ## Important
/// - The [buildTask] must return a static or top-level function
/// - Parameters must be serializable (primitives, Lists, Maps)
/// - Not supported on web platforms
class CalculatePrimesUseCase
    extends BackgroundUseCase<PrimeResult, PrimeParams> {
  @override
  BackgroundTask<PrimeParams> buildTask() => _calculatePrime;

  /// Static function that runs on the isolate.
  ///
  /// This MUST be static or top-level - instance methods won't work!
  static void _calculatePrime(BackgroundTaskContext<PrimeParams> context) {
    final stopwatch = Stopwatch()..start();
    final n = context.params.n;

    if (n <= 0) {
      context.sendError(ArgumentError('n must be positive, got: $n'));
      return;
    }

    int count = 0;
    int candidate = 1;

    while (count < n) {
      candidate++;
      if (_isPrime(candidate)) {
        count++;
      }
    }

    stopwatch.stop();

    // Send the result back to the main isolate
    context.sendData(PrimeResult(
      nthPrime: n,
      value: candidate,
      duration: stopwatch.elapsed,
    ));

    // Signal completion
    context.sendDone();
  }

  /// Check if a number is prime.
  static bool _isPrime(int n) {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;

    for (int i = 3; i * i <= n; i += 2) {
      if (n % i == 0) return false;
    }

    return true;
  }
}
