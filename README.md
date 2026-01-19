# Flutter Clean Architecture

[![Pub Version](https://img.shields.io/pub/v/flutter_clean_architecture)](https://pub.dev/packages/flutter_clean_architecture)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A comprehensive Clean Architecture framework for Flutter applications with **Result-based error handling**, **type-safe failures**, and **minimal boilerplate**.

## What's New in v7

Version 7 is a major redesign focused on developer experience and modern Dart patterns:

- ✅ **Single-shot by default**: `UseCase` returns `Future<Result<T, AppFailure>>` instead of streams
- ✅ **Opt-in streaming**: `StreamUseCase` for reactive operations
- ✅ **Type-safe errors**: `AppFailure` sealed class for exhaustive pattern matching
- ✅ **Cooperative cancellation**: `CancelToken` for cancelling long-running operations
- ✅ **Background processing**: `BackgroundUseCase` for CPU-intensive work on isolates
- ✅ **Fine-grained rebuilds**: `ControlledWidgetBuilder` and `ControlledWidgetSelector`
- ✅ **Automatic cleanup**: Controllers automatically cancel operations on dispose
- ✅ **CLI Code Generator**: `fca` CLI for generating boilerplate code (AI-agent friendly)

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI Code Generator](#cli-code-generator)
- [Core Concepts](#core-concepts)
  - [Result Type](#result-type)
  - [AppFailure Hierarchy](#appfailure-hierarchy)
  - [UseCase](#usecase)
  - [StreamUseCase](#streamusecase)
  - [BackgroundUseCase](#backgroundusecase)
  - [Controller](#controller)
  - [CleanView](#cleanview)
  - [CancelToken](#canceltoken)
- [Project Structure](#project-structure)
- [Complete Example](#complete-example)
- [Migration from v6](#migration-from-v6)
- [API Reference](#api-reference)
- [AI Agents](#ai-agents)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_clean_architecture: ^7.0.0
```

Then run:

```bash
flutter pub get
```

Import in your Dart files:

```dart
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
```

## Quick Start

> 💡 **Tip**: Use the `fca` CLI to generate boilerplate code automatically. See [CLI Code Generator](#cli-code-generator).

### 1. Create a UseCase

```dart
class GetUserUseCase extends UseCase<User, String> {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  @override
  Future<User> execute(String userId, CancelToken? cancelToken) async {
    cancelToken?.throwIfCancelled();
    return _repository.getUser(userId);
  }
}
```

### 2. Create a Controller

```dart
class UserController extends Controller {
  final GetUserUseCase _getUser;

  UserState _viewState = const UserState();
  UserState get viewState => _viewState;

  UserController(UserRepository repo) : _getUser = GetUserUseCase(repo);

  Future<void> loadUser(String id) async {
    _setState(_viewState.copyWith(isLoading: true));

    final result = await execute(_getUser, id);

    result.fold(
      (user) => _setState(_viewState.copyWith(user: user, isLoading: false)),
      (failure) => _setState(_viewState.copyWith(error: failure, isLoading: false)),
    );
  }

  void _setState(UserState newState) {
    _viewState = newState;
    refreshUI();
  }
}
```

### 3. Create a View

```dart
class UserPage extends CleanView {
  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends CleanViewState<UserPage, UserController> {
  _UserPageState() : super(UserController(getIt<UserRepository>()));

  @override
  Widget get view {
    return Scaffold(
      key: globalKey,
      body: ControlledWidgetBuilder<UserController>(
        builder: (context, controller) {
          if (controller.viewState.isLoading) {
            return const CircularProgressIndicator();
          }
          return Text(controller.viewState.user?.name ?? 'No user');
        },
      ),
    );
  }
}
```

## CLI Code Generator

The `fca` CLI generates Clean Architecture boilerplate code from simple command-line flags.

### Quick Examples

```bash
# Generate UseCases + Repository for an entity
fca generate Product --methods=get,getList,create,update,delete --repository

# With VPC layer (View, Presenter, Controller)
fca generate Product --methods=get,getList,create --repository --vpc

# With Data layer (DataRepository + DataSource)
fca generate Product --methods=get,getList,create --repository --data

# Custom UseCase with multiple repositories
fca generate ProcessOrder --repos=OrderRepo,PaymentRepo --params=OrderRequest --returns=OrderResult

# AI-friendly JSON output
fca generate Product --methods=get,getList --format=json
```

### Available Methods

| Method | UseCase Type | Description |
|--------|--------------|-------------|
| `get` | `UseCase` | Get single entity by ID |
| `getList` | `UseCase` | Get all entities |
| `create` | `UseCase` | Create new entity |
| `update` | `UseCase` | Update existing entity |
| `delete` | `CompletableUseCase` | Delete entity by ID |
| `watch` | `StreamUseCase` | Watch single entity |
| `watchList` | `StreamUseCase` | Watch all entities |

### Full Documentation

See **[CLI_GUIDE.md](CLI_GUIDE.md)** for comprehensive CLI documentation including:
- All command-line options
- JSON configuration format
- AI agent integration
- Generated file structure
- Troubleshooting

## Core Concepts

### Result Type

All operations return `Result<T, AppFailure>` for type-safe error handling:

```dart
sealed class Result<S, F> {
  bool get isSuccess;
  bool get isFailure;
  
  T fold<T>(
    T Function(S value) onSuccess,
    T Function(F error) onFailure,
  );
  
  S? getOrNull();
  S getOrElse(S Function() defaultValue);
  Result<T, F> map<T>(T Function(S value) transform);
  // ... and more
}
```

**Usage:**

```dart
final result = await getUserUseCase('user-123');

// Pattern matching with fold
result.fold(
  (user) => showUser(user),
  (failure) => showError(failure),
);

// Or use getters
if (result.isSuccess) {
  final user = result.getOrNull()!;
  print('Got user: ${user.name}');
}

// Map transformations
final nameResult = result.map((user) => user.name);
```

### AppFailure Hierarchy

`AppFailure` is a sealed class enabling exhaustive pattern matching:

```dart
sealed class AppFailure implements Exception {
  final String message;
  final StackTrace? stackTrace;
  final Object? cause;
}

// Specific failure types
final class ServerFailure extends AppFailure { ... }
final class NetworkFailure extends AppFailure { ... }
final class ValidationFailure extends AppFailure { ... }
final class NotFoundFailure extends AppFailure { ... }
final class UnauthorizedFailure extends AppFailure { ... }
final class ForbiddenFailure extends AppFailure { ... }
final class TimeoutFailure extends AppFailure { ... }
final class CacheFailure extends AppFailure { ... }
final class ConflictFailure extends AppFailure { ... }
final class CancellationFailure extends AppFailure { ... }
final class UnknownFailure extends AppFailure { ... }
```

**Exhaustive handling with switch:**

```dart
String getErrorMessage(AppFailure failure) {
  return switch (failure) {
    ValidationFailure(:final fieldErrors) => 
      'Validation failed: ${fieldErrors?.keys.join(", ")}',
    NetworkFailure() => 
      'Please check your internet connection',
    NotFoundFailure(:final resourceType) => 
      '${resourceType ?? "Resource"} not found',
    UnauthorizedFailure() => 
      'Please log in to continue',
    TimeoutFailure(:final timeout) => 
      'Request timed out after ${timeout?.inSeconds}s',
    ServerFailure(:final statusCode) => 
      'Server error${statusCode != null ? " ($statusCode)" : ""}',
    CancellationFailure() => 
      'Operation cancelled',
    _ => 
      failure.message,
  };
}
```

**Automatic error classification:**

```dart
// AppFailure.from() intelligently classifies exceptions
try {
  await httpClient.get('/users');
} catch (e, stackTrace) {
  final failure = AppFailure.from(e, stackTrace);
  // Automatically detects NetworkFailure, TimeoutFailure, etc.
}
```

### UseCase

The default `UseCase` is for **single-shot operations** that return a `Result`:

```dart
abstract class UseCase<T, Params> {
  Future<Result<T, AppFailure>> call(Params params, {CancelToken? cancelToken});
  
  @protected
  Future<T> execute(Params params, CancelToken? cancelToken);
}
```

**Examples:**

```dart
// With parameters
class GetUserUseCase extends UseCase<User, String> {
  final UserRepository _repository;
  
  GetUserUseCase(this._repository);

  @override
  Future<User> execute(String userId, CancelToken? cancelToken) async {
    return _repository.getUser(userId);
  }
}

// Without parameters (use NoParams)
class GetAllUsersUseCase extends UseCase<List<User>, NoParams> {
  @override
  Future<List<User>> execute(NoParams params, CancelToken? cancelToken) async {
    return _repository.getAllUsers();
  }
}

// Usage
final result = await getAllUsersUseCase(const NoParams());
```

**CompletableUseCase** for operations that don't return a value:

```dart
class LogoutUseCase extends CompletableUseCase<NoParams> {
  @override
  Future<void> execute(NoParams params, CancelToken? cancelToken) async {
    await _authRepository.logout();
  }
}

// Returns Result<void, AppFailure>
final result = await logoutUseCase(const NoParams());
result.fold(
  (_) => navigateToLogin(),
  (failure) => showError(failure),
);
```

### StreamUseCase

For **reactive operations** that emit multiple values over time:

```dart
abstract class StreamUseCase<T, Params> {
  Stream<Result<T, AppFailure>> call(Params params, {CancelToken? cancelToken});
  
  @protected
  Stream<T> execute(Params params, CancelToken? cancelToken);
}
```

**Example:**

```dart
class WatchUserUseCase extends StreamUseCase<User, String> {
  final UserRepository _repository;
  
  WatchUserUseCase(this._repository);

  @override
  Stream<User> execute(String userId, CancelToken? cancelToken) {
    return _repository.watchUser(userId);
  }
}

// Usage - stream API
watchUserUseCase('user-123').listen((result) {
  result.fold(
    (user) => updateUI(user),
    (failure) => showError(failure),
  );
});

// Usage - callback API
final subscription = watchUserUseCase.listen(
  'user-123',
  onData: (user) => updateUI(user),
  onError: (failure) => showError(failure),
  onDone: () => print('Stream completed'),
);

// Don't forget to cancel!
subscription.cancel();
```

### BackgroundUseCase

For **CPU-intensive operations** that should run on a separate isolate:

```dart
abstract class BackgroundUseCase<T, Params> {
  Stream<Result<T, AppFailure>> call(Params params, {CancelToken? cancelToken});
  
  @protected
  BackgroundTask<Params> buildTask();
}
```

**Example:**

```dart
class ProcessImageUseCase extends BackgroundUseCase<ProcessedImage, ImageParams> {
  @override
  BackgroundTask<ImageParams> buildTask() => _processImage;

  // MUST be static or top-level function!
  static void _processImage(BackgroundTaskContext<ImageParams> context) {
    final params = context.params;
    
    // CPU-intensive work here
    final result = applyFilters(params.image, params.filters);
    
    context.sendData(result);
    context.sendDone();
  }
}

// Usage
processImageUseCase(ImageParams(image, filters)).listen((result) {
  result.fold(
    (processed) => displayImage(processed),
    (failure) => showError(failure),
  );
});
```

> ⚠️ **Important**: `BackgroundUseCase` is not supported on web platforms. The task function must be static or top-level.

### Controller

The `Controller` manages UI state and coordinates with UseCases:

```dart
abstract class Controller with ChangeNotifier, WidgetsBindingObserver, RouteAware {
  // Access Flutter context and state
  BuildContext? get context;
  State<StatefulWidget>? get state;
  GlobalKey<State<StatefulWidget>> get globalKey;
  
  // Execute use cases with automatic cancellation
  Future<Result<T, AppFailure>> execute<T, P>(UseCase<T, P> useCase, P params);
  
  // Create managed cancel tokens
  CancelToken createCancelToken();
  
  // Register subscriptions for cleanup
  void registerSubscription(StreamSubscription subscription);
  
  // Trigger UI rebuild
  void refreshUI();
  
  // Lifecycle hooks
  void onInitState();
  void onDidChangeDependencies();
  void onDisposed();
  void onResumed();
  void onPaused();
  // ... and more
}
```

**Example:**

```dart
class ProductController extends Controller {
  final GetProductUseCase _getProduct;
  final WatchInventoryUseCase _watchInventory;

  ProductState _viewState = const ProductState();
  ProductState get viewState => _viewState;

  ProductController({required ProductRepository repository})
      : _getProduct = GetProductUseCase(repository),
        _watchInventory = WatchInventoryUseCase(repository);

  @override
  void onInitState() {
    super.onInitState();
    _startWatchingInventory();
  }

  Future<void> loadProduct(String id) async {
    _setState(_viewState.copyWith(isLoading: true));

    final result = await execute(_getProduct, id);

    result.fold(
      (product) => _setState(_viewState.copyWith(
        product: product,
        isLoading: false,
      )),
      (failure) => _setState(_viewState.copyWith(
        error: failure,
        isLoading: false,
      )),
    );
  }

  void _startWatchingInventory() {
    final cancelToken = createCancelToken();
    
    final subscription = _watchInventory(
      const NoParams(),
      cancelToken: cancelToken,
    ).listen((result) {
      result.fold(
        (inventory) => _setState(_viewState.copyWith(inventory: inventory)),
        (failure) => logger.warning('Inventory watch failed: $failure'),
      );
    });

    registerSubscription(subscription);
  }

  void _setState(ProductState newState) {
    _viewState = newState;
    refreshUI();
  }
}
```

### CleanView

The `CleanView` and `CleanViewState` integrate with the Controller:

```dart
class ProductPage extends CleanView {
  final String productId;

  const ProductPage({required this.productId, super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends CleanViewState<ProductPage, ProductController> {
  _ProductPageState() : super(ProductController(repository: getIt()));

  @override
  void onInitState() {
    super.onInitState();
    controller.loadProduct(widget.productId);
  }

  @override
  Widget get view {
    return Scaffold(
      key: globalKey, // Important: use globalKey on root widget
      appBar: AppBar(title: const Text('Product')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Use ControlledWidgetBuilder for reactive updates
    return ControlledWidgetBuilder<ProductController>(
      builder: (context, controller) {
        final state = controller.viewState;

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return ErrorWidget(state.error!);
        }

        return ProductDetails(product: state.product!);
      },
    );
  }
}
```

**ControlledWidgetSelector** for fine-grained rebuilds:

```dart
// Only rebuilds when the specific value changes
ControlledWidgetSelector<ProductController, String?>(
  selector: (controller) => controller.viewState.product?.name,
  builder: (context, productName) {
    return Text(productName ?? 'Unknown');
  },
)
```

### CancelToken

Cooperative cancellation for long-running operations:

```dart
// Create a token
final cancelToken = CancelToken();

// Use with a use case
final result = await getUserUseCase(userId, cancelToken: cancelToken);

// Cancel when needed
cancelToken.cancel('User navigated away');

// Check cancellation in your code
cancelToken.throwIfCancelled();

// Create with timeout
final timeoutToken = CancelToken.timeout(const Duration(seconds: 30));

// Link tokens (child cancelled when parent is)
final childToken = parentToken.createChild();
```

**In Controllers**, use `createCancelToken()` for automatic cleanup:

```dart
class MyController extends Controller {
  Future<void> loadData() async {
    // This token is automatically cancelled when controller disposes
    final result = await execute(myUseCase, params);
  }
}
```

## Project Structure

Recommended folder structure for Clean Architecture:

```
lib/
├── main.dart
└── src/
    ├── core/                    # Shared utilities
    │   ├── error/               # Custom failures if needed
    │   ├── network/             # HTTP client, interceptors
    │   └── utils/               # Helpers, extensions
    │
    ├── data/                    # Data layer
    │   ├── datasources/         # Remote and local data sources
    │   ├── models/              # DTOs, JSON serialization
    │   └── repositories/        # Repository implementations
    │
    ├── domain/                  # Domain layer (pure Dart)
    │   ├── entities/            # Business objects
    │   ├── repositories/        # Repository interfaces
    │   └── usecases/            # Business logic
    │
    └── presentation/            # Presentation layer
        ├── pages/               # Full-screen views
        │   ├── home/
        │   │   ├── home_page.dart
        │   │   ├── home_controller.dart
        │   │   └── home_state.dart
        │   └── ...
        └── widgets/             # Reusable widgets
```

## Complete Example

See the [example](./example) directory for a complete working application that demonstrates:

- ✅ `UseCase` for CRUD operations
- ✅ `StreamUseCase` for real-time updates
- ✅ `BackgroundUseCase` for CPU-intensive calculations
- ✅ `Controller` with immutable state
- ✅ `CleanView` with `ControlledWidgetBuilder`
- ✅ `CancelToken` for cancellation
- ✅ Error handling with `AppFailure`

Run the example:

```bash
cd example
flutter run
```

## Migration from v6

### Key Changes

| v6 | v7 |
|----|----|
| `UseCase` emits stream by default | `UseCase` returns `Future<Result<T, AppFailure>>` |
| `Observer` required for callbacks | `Result.fold()` for handling success/failure |
| `Presenter` for use case orchestration | Optional, use Controller directly |
| Manual error handling | `AppFailure` sealed class with pattern matching |
| No cancellation support | `CancelToken` for cooperative cancellation |

### Migration Steps

**1. Update UseCase implementations:**

```dart
// v6
class GetUserUseCase extends UseCase<GetUserUseCaseResponse, GetUserUseCaseParams> {
  @override
  Future<Stream<GetUserUseCaseResponse?>> buildUseCaseStream(params) async* {
    final user = await _repository.getUser(params!.id);
    yield GetUserUseCaseResponse(user);
  }
}

// v7
class GetUserUseCase extends UseCase<User, String> {
  @override
  Future<User> execute(String userId, CancelToken? cancelToken) async {
    return _repository.getUser(userId);
  }
}
```

**2. Update Controller usage:**

```dart
// v6
class MyController extends Controller {
  late MyPresenter presenter;
  
  @override
  void initListeners() {
    presenter.getUserOnNext = (user) { ... };
    presenter.getUserOnError = (error) { ... };
  }
  
  void getUser(String id) {
    presenter.getUser(id);
  }
}

// v7
class MyController extends Controller {
  final GetUserUseCase _getUser;
  
  Future<void> getUser(String id) async {
    final result = await execute(_getUser, id);
    result.fold(
      (user) => _setState(_viewState.copyWith(user: user)),
      (failure) => _setState(_viewState.copyWith(error: failure)),
    );
  }
}
```

**3. Remove Presenter (optional in v7):**

The Presenter layer is now optional. For most cases, you can coordinate use cases directly in the Controller. Keep Presenter only for complex multi-use-case orchestration.

**4. Update error handling:**

```dart
// v6
void onError(dynamic error) {
  if (error is NetworkException) { ... }
  else if (error is AuthException) { ... }
}

// v7
result.fold(
  (success) => handleSuccess(success),
  (failure) => switch (failure) {
    NetworkFailure() => showOfflineMessage(),
    UnauthorizedFailure() => navigateToLogin(),
    _ => showError(failure.message),
  },
);
```

## API Reference

### Core Types

| Type | Description |
|------|-------------|
| `Result<S, F>` | Sealed class representing success or failure |
| `Success<S, F>` | Success case containing a value |
| `Failure<S, F>` | Failure case containing an error |
| `AppFailure` | Sealed failure hierarchy |
| `CancelToken` | Cooperative cancellation token |
| `NoParams` | Sentinel for parameterless use cases |

### Domain Layer

| Type | Description |
|------|-------------|
| `UseCase<T, Params>` | Single-shot operation returning `Result` |
| `CompletableUseCase<Params>` | Single-shot operation returning `Result<void, AppFailure>` |
| `StreamUseCase<T, Params>` | Streaming operation emitting `Result` values |
| `BackgroundUseCase<T, Params>` | Isolate-based operation for CPU-intensive work |
| `Observer<T>` | Optional callback-based stream listener |

### Presentation Layer

| Type | Description |
|------|-------------|
| `Controller` | State management and use case coordination |
| `CleanView` | StatefulWidget base class for views |
| `CleanViewState<V, C>` | State class integrating Controller lifecycle |
| `ControlledWidgetBuilder<C>` | Rebuilds when Controller calls `refreshUI()` |
| `ControlledWidgetSelector<C, T>` | Rebuilds only when selected value changes |
| `ResponsiveViewState<V, C>` | Responsive layouts with device-specific builders |

### Failure Types

| Type | Use Case |
|------|----------|
| `ServerFailure` | HTTP 5xx errors |
| `NetworkFailure` | Connection issues |
| `ValidationFailure` | Input validation errors |
| `NotFoundFailure` | HTTP 404 / resource not found |
| `UnauthorizedFailure` | HTTP 401 / auth required |
| `ForbiddenFailure` | HTTP 403 / access denied |
| `TimeoutFailure` | Request timeout |
| `CacheFailure` | Local storage errors |
| `ConflictFailure` | HTTP 409 / version conflicts |
| `CancellationFailure` | Operation cancelled |
| `UnknownFailure` | Catch-all for unclassified errors |

## AI Agents

This package is designed to work well with AI coding agents. See **[AGENTS.md](AGENTS.md)** for:

- Recommended content for your project's `AGENTS.md` or `CLAUDE.md`
- Architecture overview for AI understanding
- Common tasks and workflows
- CLI commands optimized for AI agents

### Quick Reference for AI Agents

```bash
# JSON output for parsing
fca generate Product --methods=get,getList --format=json

# Read from stdin
echo '{"name":"Product","methods":["get","getList"]}' | fca generate Product --from-stdin

# Get JSON schema for validation
fca schema

# Dry run (preview without writing)
fca generate Product --methods=get --dry-run --format=json
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

## License

MIT License - see [LICENSE](LICENSE) for details.

## CLI Tool
The `flutter_clean_architecture` package includes a command-line interface (CLI) tool that helps you quickly scaffold Clean Architecture components in your Flutter projects.

### Installation
The CLI is automatically available when you add the package to your project:

```yaml
dependencies:
  flutter_clean_architecture: ^6.1.0
```

### Usage
Run the CLI using Flutter's pub command:

```bash
flutter pub run flutter_clean_architecture:cli <command>
```

### Available Commands

#### Create Default Architecture Structure

Generate the complete Clean Architecture folder structure:

```bash
flutter pub run flutter_clean_architecture:cli create
```

This creates the following structure in your `lib/src/` directory:

```
lib/src/
├── app/                   # Application Layer
│   ├── pages/             # Page components
│   ├── widgets/           # Reusable UI components
│   ├── utils/             # Application utilities
│   └── navigator.dart     # Navigation configuration
├── data/                  # Data Layer
│   ├── repositories/      # Data access implementations
│   ├── helpers/           # Data processing helpers
│   └── constants.dart     # Data-related constants
├── device/                # Device Layer
│   ├── repositories/      # Platform-specific implementations
│   └── utils/             # Device utilities
└── domain/                # Domain Layer
    ├── entities/          # Business objects
    ├── usecases/          # Business logic
    └── repositories/      # Repository interfaces
```

#### Create a New Page
Generate a complete page with Controller, Presenter, and View files:

```bash
flutter pub run flutter_clean_architecture:cli create --page user_profile
```

This creates three files in `lib/src/app/pages/user_profile/`:

- `user_profile_view.dart` - UI implementation (View + ViewState)
- `user_profile_controller.dart` - Business logic controller
- `user_profile_presenter.dart` - Presentation logic and use case coordination

### Page Naming Convention
Page names must follow snake_case format:

- ✅ Valid: `user_profile`, `product_detail`, `login`, `home_page`
- ❌ Invalid: `UserProfile`, `user-profile`, `user_profile_`

### Help
Get help for the CLI tool:

```bash
flutter pub run flutter_clean_architecture:cli --help
```

Get help for specific commands:

```bash
flutter pub run flutter_clean_architecture:cli create --help
```

## Authors
- **Ahmet TOK** - [GitHub](https://github.com/arrrrny)
- **Shady Boukhary** - [GitHub](https://github.com/ShadyBoukhary)

---

Made with ⚡️ for the Flutter community
