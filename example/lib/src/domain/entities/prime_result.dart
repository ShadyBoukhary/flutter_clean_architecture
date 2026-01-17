/// Result of a prime number calculation.
///
/// Used to demonstrate BackgroundUseCase with CPU-intensive operations.
class PrimeResult {
  /// The nth prime that was calculated
  final int nthPrime;

  /// The actual prime number value
  final int value;

  /// How long the calculation took
  final Duration duration;

  const PrimeResult({
    required this.nthPrime,
    required this.value,
    required this.duration,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrimeResult &&
          runtimeType == other.runtimeType &&
          nthPrime == other.nthPrime &&
          value == other.value &&
          duration == other.duration);

  @override
  int get hashCode => nthPrime.hashCode ^ value.hashCode ^ duration.hashCode;

  @override
  String toString() =>
      'PrimeResult(n: $nthPrime, value: $value, duration: ${duration.inMilliseconds}ms)';
}
