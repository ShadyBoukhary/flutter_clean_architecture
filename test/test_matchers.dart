import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matcher that checks if a Result is a Success
Matcher isSuccess<T>() => _IsSuccessMatcher<T>();

/// Matcher that checks if a Result is a Failure
Matcher isFailure() => _IsFailureMatcher();

/// Matcher that checks if a Result is a Failure of a specific type
Matcher isFailureOfType<T extends AppFailure>() => _IsFailureOfTypeMatcher<T>();

/// Matcher that checks if a Result's failure message contains a substring
Matcher failureMessageContains(String substring) =>
    _FailureMessageContainsMatcher(substring);

class _IsSuccessMatcher<T> extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is Result) {
      return item.isSuccess;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is a Success<$T>');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is Result) {
      if (item.isFailure) {
        return mismatchDescription
            .add('is a Failure: ${item.getFailureOrNull()}');
      }
    }
    return mismatchDescription.add('is not a Result');
  }
}

class _IsFailureMatcher extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is Result) {
      return item.isFailure;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is a Failure');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is Result) {
      if (item.isSuccess) {
        return mismatchDescription.add('is a Success: ${item.getOrNull()}');
      }
    }
    return mismatchDescription.add('is not a Result');
  }
}

class _IsFailureOfTypeMatcher<T extends AppFailure> extends Matcher {
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is Result) {
      if (item.isFailure) {
        final failure = item.getFailureOrNull();
        return failure is T;
      }
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is a Failure of type $T');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is Result) {
      if (item.isSuccess) {
        return mismatchDescription.add('is a Success: ${item.getOrNull()}');
      }
      final failure = item.getFailureOrNull();
      return mismatchDescription
          .add('is a Failure of type ${failure.runtimeType}');
    }
    return mismatchDescription.add('is not a Result');
  }
}

class _FailureMessageContainsMatcher extends Matcher {
  final String substring;

  _FailureMessageContainsMatcher(this.substring);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is Result) {
      if (item.isFailure) {
        final failure = item.getFailureOrNull();
        if (failure is AppFailure) {
          return failure.message.contains(substring);
        }
      }
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description.add('is a Failure with message containing "$substring"');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is Result) {
      if (item.isSuccess) {
        return mismatchDescription.add('is a Success');
      }
      final failure = item.getFailureOrNull();
      if (failure is AppFailure) {
        return mismatchDescription.add(
            'has message "${failure.message}" which does not contain "$substring"');
      }
    }
    return mismatchDescription.add('is not a Result');
  }
}
