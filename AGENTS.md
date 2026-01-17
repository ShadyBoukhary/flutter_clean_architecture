# AI Agents Guide

This document provides guidance for AI agents working with Flutter Clean Architecture projects.

## Adding to Your Project's AGENTS.md

If you're using `flutter_clean_architecture` in your project, add the following to your `AGENTS.md` or `CLAUDE.md` file to help AI agents understand and work with your codebase effectively.

---

## Recommended AGENTS.md Content

```markdown
# Flutter Clean Architecture

This project uses `flutter_clean_architecture` v7 for Clean Architecture implementation.

## Architecture Overview

```
lib/src/
├── domain/                    # Business logic layer (pure Dart)
│   ├── entities/              # Business objects
│   ├── repositories/          # Repository interfaces (contracts)
│   └── usecases/              # Business operations
├── data/                      # Data layer (external dependencies)
│   ├── data_sources/          # Data source interfaces & implementations
│   └── repositories/          # Repository implementations
└── presentation/              # UI layer (Flutter)
    └── {feature}/
        ├── {feature}_view.dart
        ├── {feature}_presenter.dart
        └── {feature}_controller.dart
```

## Code Generation CLI

Use the `fca` CLI to generate boilerplate code:

### Entity-Based Generation

```bash
# Generate UseCases + Repository interface
fca generate <EntityName> --methods=get,getList,create,update,delete --repository

# With VPC layer (View, Presenter, Controller)
fca generate <EntityName> --methods=get,getList,create --repository --vpc

# With Data layer (DataRepository + DataSource)
fca generate <EntityName> --methods=get,getList,create --repository --data
```

### Available Methods

| Method | UseCase Type | Description |
|--------|--------------|-------------|
| `get` | `UseCase` | Get single entity by ID |
| `getList` | `UseCase` | Get all entities |
| `create` | `UseCase` | Create new entity |
| `update` | `UseCase` | Update existing entity |
| `delete` | `CompletableUseCase` | Delete entity by ID |
| `watch` | `StreamUseCase` | Watch single entity changes |
| `watchList` | `StreamUseCase` | Watch all entities changes |

### Custom UseCase Generation

```bash
# Create a custom UseCase with multiple repository dependencies
fca generate <UseCaseName> \
  --repos=Repo1,Repo2 \
  --params=ParamsType \
  --returns=ReturnType

# Background UseCase (runs on isolate)
fca generate <UseCaseName> --type=background --params=Params --returns=Result

# Stream UseCase
fca generate <UseCaseName> --type=stream --repos=SomeRepo --returns=DataType
```

### AI-Friendly Commands

```bash
# JSON output for parsing
fca generate Product --methods=get,getList --format=json

# From stdin (pipe JSON)
echo '{"name":"Product","methods":["get","getList"]}' | fca generate Product --from-stdin

# Get JSON schema
fca schema

# Dry run (preview)
fca generate Product --methods=get --dry-run --format=json
```

## Core Patterns

### UseCase Pattern

```dart
class GetProductUseCase extends UseCase<Product, String> {
  final ProductRepository _repository;

  GetProductUseCase(this._repository);

  @override
  Future<Product> execute(String id, CancelToken? cancelToken) async {
    cancelToken?.throwIfCancelled();
    return _repository.get(id);
  }
}

// Usage
final result = await getProductUseCase('id-123');
result.fold(
  (product) => print('Success: $product'),
  (failure) => print('Error: ${failure.message}'),
);
```

### Result Type

All UseCases return `Result<T, AppFailure>`:

```dart
// Pattern matching
switch (result) {
  case Success(:final value):
    print('Got: $value');
  case Failure(:final error):
    print('Error: ${error.message}');
}

// Fold
result.fold(
  (value) => handleSuccess(value),
  (failure) => handleError(failure),
);

// Get or default
final value = result.getOrElse(() => defaultValue);
```

### AppFailure Types

```dart
sealed class AppFailure {
  // Available subtypes:
  // - ServerFailure
  // - NetworkFailure
  // - ValidationFailure
  // - NotFoundFailure
  // - UnauthorizedFailure
  // - ForbiddenFailure
  // - TimeoutFailure
  // - CacheFailure
  // - ConflictFailure
  // - CancellationFailure
  // - UnknownFailure
}
```

### VPC Architecture

When `--vpc` is used:
- **View** → Pure UI, uses `ControlledWidgetBuilder`
- **Controller** → Manages state, calls Presenter methods
- **Presenter** → Contains UseCases, orchestrates business logic

```
View → Controller → Presenter → UseCase → Repository
```

### Repository injection pattern

```dart
class ProductView extends CleanView {
  final ProductRepository productRepository;

  const ProductView({required this.productRepository});

  @override
  State<ProductView> createState() => _ProductViewState(
    ProductController(
      ProductPresenter(productRepository: productRepository),
    ),
  );
}
```

## File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Entity | `{entity_snake}.dart` | `product.dart` |
| Repository | `{entity_snake}_repository.dart` | `product_repository.dart` |
| UseCase | `{action}_{entity_snake}_usecase.dart` | `get_product_usecase.dart` |
| DataSource | `{entity_snake}_data_source.dart` | `product_data_source.dart` |
| View | `{entity_snake}_view.dart` | `product_view.dart` |
| Presenter | `{entity_snake}_presenter.dart` | `product_presenter.dart` |
| Controller | `{entity_snake}_controller.dart` | `product_controller.dart` |

## Entity Location Convention

Entities MUST be at:
```
lib/src/domain/entities/{entity_snake}/{entity_snake}.dart
```

Example for `Product`:
```
lib/src/domain/entities/product/product.dart
```

## Workflow for Adding Features

1. **Create Entity** (manual or use your preferred generator like freezed/morphy)
   ```
   lib/src/domain/entities/product/product.dart
   ```

2. **Generate Domain + Data Layer**
   ```bash
   fca generate Product --methods=get,getList,create,update,delete --repository --data
   ```

3. **Generate Presentation Layer**
   ```bash
   fca generate Product --methods=get,getList,create --vpc --force
   ```

4. **Implement DataSource** (create concrete implementation)

5. **Register with DI** (get_it, riverpod, etc.)

6. **Customize View UI**
```

---

## Understanding the Architecture

### Layer Dependencies

```
┌─────────────────────────────────────────┐
│           PRESENTATION LAYER            │
│    (View, Controller, Presenter)        │
└──────────────────┬──────────────────────┘
                   │ depends on
┌──────────────────▼──────────────────────┐
│             DOMAIN LAYER                │
│  (UseCase, Repository Interface, Entity)│
└──────────────────┬──────────────────────┘
                   │ depends on (inverted)
┌──────────────────▼──────────────────────┐
│              DATA LAYER                 │
│  (DataRepository, DataSource, Models)   │
└─────────────────────────────────────────┘
```

### Key Principles

1. **Domain is pure Dart** - No Flutter imports in domain layer
2. **Dependency Inversion** - Domain defines interfaces, data implements them
3. **Single Responsibility** - Each UseCase does one thing
4. **Result-based errors** - No thrown exceptions, use `Result<T, AppFailure>`
5. **Cooperative cancellation** - Use `CancelToken` for long operations

### When to Use Each UseCase Type

| Type | Use When |
|------|----------|
| `UseCase` | Single request-response operations (CRUD, API calls) |
| `StreamUseCase` | Real-time data, WebSocket, Firebase listeners |
| `BackgroundUseCase` | CPU-intensive work (image processing, crypto) |
| `CompletableUseCase` | Operations that don't return a value (delete, logout) |

## Common Tasks for AI Agents

### Adding a New Entity

1. Create entity class at `lib/src/domain/entities/{name}/{name}.dart`
2. Run: `fca generate {Name} --methods=get,getList,create,update,delete --repository --data --vpc`
3. Implement concrete DataSource
4. Register with DI

### Adding a Method to Existing Entity

1. Run with only new methods and `--force`:
   ```bash
   fca generate Product --methods=watch,watchList --repository --force
   ```
2. Manually add new methods to Presenter if using VPC

### Creating Cross-Cutting UseCase

```bash
fca generate ProcessCheckout \
  --repos=CartRepository,OrderRepository,PaymentRepository \
  --params=CheckoutRequest \
  --returns=Order
```

### Debugging Generation Issues

```bash
# Dry run to see what would be generated
fca generate Product --methods=get --dry-run --format=json

# Verbose mode
fca generate Product --methods=get --verbose

# Validate JSON config
fca validate config.json
```

## Links

- [CLI Guide](./CLI_GUIDE.md) - Comprehensive CLI documentation
- [README](./README.md) - Package overview and API reference
- [Example](./example) - Working example application