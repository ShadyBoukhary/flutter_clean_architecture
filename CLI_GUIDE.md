# FCA CLI Guide

The `fca` (Flutter Clean Architecture) CLI is a powerful code generator that creates Clean Architecture boilerplate code from simple command-line flags or JSON input. It's designed to be **AI-agent friendly** with machine-readable output formats.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
  - [generate](#generate-command)
  - [schema](#schema-command)
  - [validate](#validate-command)
- [Entity-Based Generation](#entity-based-generation)
- [Custom UseCase Generation](#custom-usecase-generation)
- [VPC Layer Generation](#vpc-layer-generation)
- [Data Layer Generation](#data-layer-generation)
- [AI Agent Integration](#ai-agent-integration)
- [JSON Configuration](#json-configuration)
- [Examples](#examples)
- [Generated File Structure](#generated-file-structure)

## Installation

The CLI is included with the `flutter_clean_architecture` package. After adding it to your project:

```bash
# Add the package
flutter pub add flutter_clean_architecture

# Run the CLI
dart run flutter_clean_architecture:fca --help
```

Or if installed globally:

```bash
dart pub global activate flutter_clean_architecture
fca --help
```

## Quick Start

Generate a complete CRUD stack for an entity:

```bash
# Basic CRUD with repository
fca generate Product --methods=get,getList,create,update,delete --repository

# With VPC layer (View, Presenter, Controller)
fca generate Product --methods=get,getList,create,update,delete --repository --vpc

# With data layer (DataRepository + DataSource)
fca generate Product --methods=get,getList,create,update,delete --repository --data
```

## Commands

### generate Command

The primary command for generating Clean Architecture code.

```
fca generate <Name> [options]
```

#### Arguments

| Argument | Description |
|----------|-------------|
| `<Name>` | Entity or UseCase name in PascalCase (e.g., `Product`, `ProcessOrder`) |

#### Entity-Based Options

| Flag | Short | Description |
|------|-------|-------------|
| `--methods=<list>` | `-m` | Comma-separated methods to generate |
| `--repository` | `-r` | Generate repository interface |
| `--data` | `-d` | Generate data repository + data source |
| `--datasource` | | Generate data source only |
| `--id-type=<type>` | | ID type for entity (default: `String`) |

#### Supported Methods

| Method | UseCase Type | Generated Class | Description |
|--------|--------------|-----------------|-------------|
| `get` | `UseCase` | `GetProductUseCase` | Get single entity by ID |
| `getList` | `UseCase` | `GetProductListUseCase` | Get all entities |
| `create` | `UseCase` | `CreateProductUseCase` | Create new entity |
| `update` | `UseCase` | `UpdateProductUseCase` | Update existing entity |
| `delete` | `CompletableUseCase` | `DeleteProductUseCase` | Delete entity by ID |
| `watch` | `StreamUseCase` | `WatchProductUseCase` | Watch single entity |
| `watchList` | `StreamUseCase` | `WatchProductListUseCase` | Watch all entities |

#### Custom UseCase Options

| Flag | Description |
|------|-------------|
| `--repos=<list>` | Comma-separated repositories to inject |
| `--type=<type>` | UseCase type: `usecase`, `stream`, `background`, `completable` |
| `--params=<type>` | Params type (default: `NoParams`) |
| `--returns=<type>` | Return type (default: `void`) |

#### VPC Layer Options

| Flag | Description |
|------|-------------|
| `--vpc` | Generate View + Presenter + Controller |
| `--view` | Generate View only |
| `--presenter` | Generate Presenter only |
| `--controller` | Generate Controller only |
| `--observer` | Generate Observer class |

#### Input/Output Options

| Flag | Short | Description |
|------|-------|-------------|
| `--from-json=<file>` | `-j` | JSON configuration file |
| `--from-stdin` | | Read JSON from stdin (AI-friendly) |
| `--output=<dir>` | `-o` | Output directory (default: `lib/src`) |
| `--format=<type>` | | Output format: `json` or `text` (default: `text`) |
| `--dry-run` | | Preview without writing files |
| `--force` | | Overwrite existing files |
| `--verbose` | `-v` | Verbose output |
| `--quiet` | `-q` | Minimal output (errors only) |

### schema Command

Output the JSON schema for configuration validation. Useful for AI agents.

```bash
fca schema > fca-schema.json
```

### validate Command

Validate a JSON configuration file.

```bash
fca validate config.json
```

## Entity-Based Generation

Entity-based generation creates UseCases that operate on a specific entity type. The entity must already exist at:

```
lib/src/domain/entities/{entity_snake}/{entity_snake}.dart
```

### Example

Assuming you have a `Product` entity:

```bash
fca generate Product --methods=get,getList,create,update,delete,watchList --repository
```

This generates:

```
lib/src/
├── domain/
│   ├── repositories/
│   │   └── product_repository.dart
│   └── usecases/product/
│       ├── get_product_usecase.dart
│       ├── get_product_list_usecase.dart
│       ├── create_product_usecase.dart
│       ├── update_product_usecase.dart
│       ├── delete_product_usecase.dart
│       └── watch_product_list_usecase.dart
```

### Generated Repository Interface

```dart
abstract class ProductRepository {
  Future<Product> get(String id);
  Future<List<Product>> getList();
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> delete(String id);
  Stream<List<Product>> watchList();
}
```

### Generated UseCase Example

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
```

## Custom UseCase Generation

Create standalone UseCases without an entity, useful for complex business operations.

### Basic Custom UseCase

```bash
fca generate ProcessOrder \
  --repos=OrderRepository,PaymentRepository \
  --params=OrderRequest \
  --returns=OrderResult
```

Generates:

```dart
class ProcessOrderUseCase extends UseCase<OrderResult, OrderRequest> {
  final OrderRepository _orderRepository;
  final PaymentRepository _paymentRepository;

  ProcessOrderUseCase(this._orderRepository, this._paymentRepository);

  @override
  Future<OrderResult> execute(OrderRequest params, CancelToken? cancelToken) async {
    cancelToken?.throwIfCancelled();
    // TODO: Implement usecase logic
    throw UnimplementedError();
  }
}
```

### Stream UseCase

```bash
fca generate ListenToNotifications \
  --type=stream \
  --repos=NotificationRepository \
  --params=UserId \
  --returns=Notification
```

### Background UseCase

For CPU-intensive operations that run on a separate isolate:

```bash
fca generate ProcessImages \
  --type=background \
  --params=ImageBatch \
  --returns=ProcessedImage
```

Generates:

```dart
class ProcessImagesUseCase extends BackgroundUseCase<ProcessedImage, ImageBatch> {
  ProcessImagesUseCase();

  @override
  BackgroundTask<ImageBatch> buildTask() => _process;

  static void _process(BackgroundTaskContext<ImageBatch> context) {
    try {
      final params = context.params;

      // TODO: Implement background processing
      // context.sendData(result);

      context.sendDone();
    } catch (e, stackTrace) {
      context.sendError(e, stackTrace);
    }
  }
}
```

## VPC Layer Generation

Generate the presentation layer with View, Presenter, and Controller.

```bash
fca generate Product --methods=get,getList,create --repository --vpc
```

Generates:

```
lib/src/
├── domain/
│   └── ...
└── presentation/product/
    ├── product_view.dart
    ├── product_presenter.dart
    └── product_controller.dart
```

### With Multiple Repositories

```bash
fca generate Product \
  --repos=ProductRepository,CategoryRepository \
  --methods=get,getList \
  --vpc
```

### Generated View

```dart
class ProductView extends CleanView {
  final ProductRepository productRepository;

  const ProductView({
    super.key,
    super.routeObserver,
    required this.productRepository,
  });

  @override
  State<ProductView> createState() => _ProductViewState(
        ProductController(
          ProductPresenter(
            productRepository: productRepository,
          ),
        ),
      );
}

class _ProductViewState extends CleanViewState<ProductView, ProductController> {
  _ProductViewState(super.controller);

  @override
  Widget get view {
    return Scaffold(
      key: globalKey,
      appBar: AppBar(
        title: const Text('Product'),
      ),
      body: ControlledWidgetBuilder<ProductController>(
        builder: (context, controller) {
          return Container();
        },
      ),
    );
  }
}
```

### Generated Presenter

```dart
class ProductPresenter extends Presenter {
  final ProductRepository productRepository;

  late final GetProductUseCase _getProduct;
  late final GetProductListUseCase _getProductList;

  ProductPresenter({
    required this.productRepository,
  }) {
    _getProduct = registerUseCase(GetProductUseCase(productRepository));
    _getProductList = registerUseCase(GetProductListUseCase(productRepository));
  }

  Future<Result<Product, AppFailure>> getProduct(String id) {
    return execute(_getProduct, id);
  }

  Future<Result<List<Product>, AppFailure>> getProductList() {
    return execute(_getProductList, const NoParams());
  }
}
```

### Generated Controller

```dart
class ProductController extends Controller {
  final ProductPresenter _presenter;

  ProductController(this._presenter);

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
```

## Data Layer Generation

Generate the data layer with DataSource interface and DataRepository implementation.

```bash
fca generate Product --methods=get,getList,create,update,delete --repository --data
```

Generates:

```
lib/src/
├── domain/
│   └── repositories/
│       └── product_repository.dart      # Abstract interface
└── data/
    ├── data_sources/product/
    │   └── product_data_source.dart     # Abstract DataSource
    └── repositories/
        └── data_product_repository.dart # Implementation
```

### Generated DataSource

```dart
abstract class ProductDataSource {
  Future<Product> get(String id);
  Future<List<Product>> getList();
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> delete(String id);
}
```

### Generated DataRepository

```dart
class DataProductRepository implements ProductRepository {
  final ProductDataSource _dataSource;

  DataProductRepository(this._dataSource);

  @override
  Future<Product> get(String id) {
    return _dataSource.get(id);
  }

  @override
  Future<List<Product>> getList() {
    return _dataSource.getList();
  }

  // ... all methods delegate to _dataSource
}
```

## AI Agent Integration

The CLI is designed to be AI-agent friendly with machine-readable I/O.

### JSON Output Format

```bash
fca generate Product --methods=get,getList --repository --format=json
```

Output:

```json
{
  "success": true,
  "name": "Product",
  "generated": [
    {
      "type": "repository",
      "path": "lib/src/domain/repositories/product_repository.dart",
      "action": "created"
    },
    {
      "type": "usecase",
      "path": "lib/src/domain/usecases/product/get_product_usecase.dart",
      "action": "created"
    }
  ],
  "errors": [],
  "next_steps": [
    "Implement ProductRepositoryImpl in data layer",
    "Register repositories with DI container"
  ]
}
```

### Reading from stdin

AI agents can pipe JSON directly:

```bash
echo '{"name":"Product","methods":["get","getList"],"repository":true}' | \
  fca generate Product --from-stdin --format=json
```

### Getting the Schema

For validation before calling:

```bash
fca schema
```

### Dry Run

Preview what would be generated:

```bash
fca generate Product --methods=get,getList --dry-run --format=json
```

### Quiet Mode

For scripting, suppress all output except errors:

```bash
fca generate Product --methods=get,getList --quiet
```

## JSON Configuration

Instead of command-line flags, you can use a JSON configuration file.

### Entity-Based Configuration

```json
{
  "name": "Product",
  "methods": ["get", "getList", "create", "update", "delete", "watchList"],
  "repository": true,
  "vpc": true,
  "data": true,
  "id_type": "String"
}
```

```bash
fca generate Product -j product.json
```

### Custom UseCase Configuration

```json
{
  "name": "ProcessOrder",
  "type": "usecase",
  "repos": ["OrderRepository", "PaymentRepository"],
  "params": "OrderRequest",
  "returns": "OrderResult"
}
```

### Full Schema

Run `fca schema` to get the complete JSON schema.

## Examples

### Complete CRUD with Full Stack

```bash
fca generate Product \
  --methods=get,getList,create,update,delete,watchList \
  --repository \
  --data \
  --vpc
```

### Multiple Entities

```bash
# Generate Product stack
fca generate Product --methods=get,getList,create --repository --vpc

# Generate Order stack
fca generate Order --methods=get,getList,create,update --repository --vpc

# Generate shared UseCase
fca generate ProcessCheckout \
  --repos=ProductRepository,OrderRepository,PaymentRepository \
  --params=CheckoutRequest \
  --returns=CheckoutResult
```

### Overwrite Existing Files

```bash
fca generate Product --methods=get,getList --repository --force
```

### Custom Output Directory

```bash
fca generate Product --methods=get,getList --output=lib/features/product
```

### Custom ID Type

```bash
fca generate Product --methods=get,delete --id-type=int --repository
```

## Generated File Structure

After running all generation options, your project will have:

```
lib/src/
├── domain/
│   ├── entities/
│   │   └── product/
│   │       └── product.dart              # You create this
│   ├── repositories/
│   │   └── product_repository.dart       # Generated interface
│   └── usecases/
│       └── product/
│           ├── get_product_usecase.dart
│           ├── get_product_list_usecase.dart
│           ├── create_product_usecase.dart
│           ├── update_product_usecase.dart
│           ├── delete_product_usecase.dart
│           └── watch_product_list_usecase.dart
├── data/
│   ├── data_sources/
│   │   └── product/
│   │       └── product_data_source.dart  # Generated interface
│   └── repositories/
│       └── data_product_repository.dart  # Generated implementation
└── presentation/
    └── product/
        ├── product_view.dart
        ├── product_presenter.dart
        └── product_controller.dart
```

## Troubleshooting

### Entity Not Found Errors

Make sure your entity exists at the expected path:

```
lib/src/domain/entities/{entity_snake}/{entity_snake}.dart
```

For `Product`, the path should be:

```
lib/src/domain/entities/product/product.dart
```

### Import Errors

If you see import errors after generation, ensure:

1. The entity file exists and exports the entity class
2. Run `flutter pub get` if dependencies are missing
3. For `--data` flag, ensure the repository interface is generated first with `--repository`

### Overwriting Files

By default, the CLI skips existing files. Use `--force` to overwrite:

```bash
fca generate Product --methods=get,getList --force
```

## Next Steps

After generating code:

1. **Implement DataSource**: Create a concrete implementation of the DataSource (e.g., `RemoteProductDataSource`, `LocalProductDataSource`)
2. **Register with DI**: Register your repositories and data sources with your dependency injection container
3. **Customize Views**: Fill in the placeholder UI in generated views
4. **Add Business Logic**: Implement any TODO sections in generated UseCases