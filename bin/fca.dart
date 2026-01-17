#!/usr/bin/env dart

/// FCA CLI - Flutter Clean Architecture Code Generator
///
/// Generates UseCases, Repositories, and VPC (View/Presenter/Controller) layers
/// from simple command-line flags or JSON input.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

const version = '1.0.0';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    _printHelp();
    exit(0);
  }

  final command = arguments[0];

  try {
    switch (command) {
      case 'generate':
        await _handleGenerate(arguments.skip(1).toList());
        break;
      case 'schema':
        _handleSchema();
        break;
      case 'validate':
        await _handleValidate(arguments.skip(1).toList());
        break;
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        break;
      case 'version':
      case '--version':
      case '-v':
        print('fca v$version');
        print('Flutter Clean Architecture Code Generator');
        break;
      default:
        print('❌ Unknown command: $command\n');
        _printHelp();
        exit(1);
    }
  } catch (e, stack) {
    print('❌ Error: $e');
    if (arguments.contains('--verbose') || arguments.contains('-v')) {
      print('\nStack trace:\n$stack');
    }
    exit(1);
  }
}

// ============================================================
// Command Handlers
// ============================================================

Future<void> _handleGenerate(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: fca generate <Name> [options]');
    print('\nRun: fca generate --help for more information');
    exit(1);
  }

  // Check for help
  if (args[0] == '--help' || args[0] == '-h') {
    _printGenerateHelp();
    exit(0);
  }

  // Parse name
  final name = args[0];
  if (name.startsWith('--')) {
    print('❌ Missing name');
    print('Usage: fca generate <Name> [options]');
    exit(1);
  }

  // Parse arguments
  final parser = ArgParser()
    ..addOption('from-json', abbr: 'j', help: 'JSON configuration file')
    ..addFlag('from-stdin', help: 'Read JSON from stdin', defaultsTo: false)
    ..addOption('methods',
        abbr: 'm',
        help:
            'Comma-separated methods: get,getList,create,update,delete,watch,watchList')
    ..addOption('repos', help: 'Comma-separated repositories to inject')
    ..addFlag('repository',
        abbr: 'r', help: 'Generate repository interface', defaultsTo: false)
    ..addFlag('data',
        abbr: 'd',
        help: 'Generate data repository implementation + data source',
        defaultsTo: false)
    ..addOption('type',
        help: 'UseCase type: usecase,stream,background,completable',
        defaultsTo: 'usecase')
    ..addOption('params', help: 'Params type for custom usecase')
    ..addOption('returns', help: 'Return type for custom usecase')
    ..addOption('id-type', help: 'ID type for entity', defaultsTo: 'String')
    ..addFlag('vpc',
        help: 'Generate View + Presenter + Controller', defaultsTo: false)
    ..addFlag('view', help: 'Generate View only', defaultsTo: false)
    ..addFlag('presenter', help: 'Generate Presenter only', defaultsTo: false)
    ..addFlag('controller', help: 'Generate Controller only', defaultsTo: false)
    ..addFlag('observer', help: 'Generate Observer', defaultsTo: false)
    ..addFlag('datasource', help: 'Generate DataSource only', defaultsTo: false)
    ..addOption('output',
        abbr: 'o', help: 'Output directory', defaultsTo: 'lib/src')
    ..addOption('format', help: 'Output format: json,text', defaultsTo: 'text')
    ..addFlag('dry-run',
        help: 'Preview without writing files', defaultsTo: false)
    ..addFlag('force', help: 'Overwrite existing files', defaultsTo: false)
    ..addFlag('verbose', abbr: 'v', help: 'Verbose output', defaultsTo: false)
    ..addFlag('quiet', abbr: 'q', help: 'Minimal output', defaultsTo: false);

  final results = parser.parse(args.skip(1).toList());

  // Build configuration
  GeneratorConfig config;

  if (results['from-stdin'] == true) {
    // Read JSON from stdin
    final input = stdin.readLineSync() ?? '';
    final json = jsonDecode(input) as Map<String, dynamic>;
    config = GeneratorConfig.fromJson(json, name);
  } else if (results['from-json'] != null) {
    // Read JSON from file
    final file = File(results['from-json']);
    if (!file.existsSync()) {
      print('❌ JSON file not found: ${results['from-json']}');
      exit(1);
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    config = GeneratorConfig.fromJson(json, name);
  } else {
    // Build from flags
    final methodsStr = results['methods'] as String?;
    final reposStr = results['repos'] as String?;
    config = GeneratorConfig(
      name: name,
      methods: methodsStr?.split(',').map((s) => s.trim()).toList() ?? [],
      repos: reposStr?.split(',').map((s) => s.trim()).toList() ?? [],
      generateRepository: results['repository'] == true,
      useCaseType: results['type'],
      paramsType: results['params'],
      returnsType: results['returns'],
      idType: results['id-type'],
      generateVpc: results['vpc'] == true,
      generateView: results['view'] == true,
      generatePresenter: results['presenter'] == true,
      generateController: results['controller'] == true,
      generateObserver: results['observer'] == true,
      generateData: results['data'] == true,
      generateDataSource: results['datasource'] == true,
    );
  }

  // Set output options
  final outputDir = results['output'] as String;
  final format = results['format'] as String;
  final dryRun = results['dry-run'] == true;
  final force = results['force'] == true;
  final verbose = results['verbose'] == true;
  final quiet = results['quiet'] == true;

  // Generate
  final generator = CodeGenerator(
    config: config,
    outputDir: outputDir,
    dryRun: dryRun,
    force: force,
    verbose: verbose,
  );

  final result = await generator.generate();

  // Output
  if (format == 'json') {
    print(jsonEncode(result.toJson()));
  } else if (!quiet) {
    _printTextResult(result);
  }

  exit(result.success ? 0 : 1);
}

void _handleSchema() {
  final schema = {
    '\$schema': 'http://json-schema.org/draft-07/schema#',
    'title': 'FCA Generator Configuration',
    'type': 'object',
    'properties': {
      'name': {
        'type': 'string',
        'description': 'Entity or UseCase name (PascalCase)',
      },
      'methods': {
        'type': 'array',
        'items': {
          'type': 'string',
          'enum': [
            'get',
            'getList',
            'create',
            'update',
            'delete',
            'watch',
            'watchList'
          ],
        },
        'description': 'Methods to generate for entity-based usecases',
      },
      'repos': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Repository names to inject',
      },
      'repository': {
        'type': 'boolean',
        'description': 'Generate repository interface',
      },
      'type': {
        'type': 'string',
        'enum': ['usecase', 'stream', 'background', 'completable'],
        'description': 'UseCase type for custom usecases',
      },
      'params': {
        'type': 'string',
        'description': 'Params type for custom usecase',
      },
      'returns': {
        'type': 'string',
        'description': 'Return type for custom usecase',
      },
      'id_type': {
        'type': 'string',
        'description': 'ID type for entity (default: String)',
      },
      'vpc': {
        'type': 'boolean',
        'description': 'Generate View + Presenter + Controller',
      },
    },
    'required': ['name'],
  };

  print(const JsonEncoder.withIndent('  ').convert(schema));
}

Future<void> _handleValidate(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Usage: fca validate <json-file>');
    exit(1);
  }

  final file = File(args[0]);
  if (!file.existsSync()) {
    print(jsonEncode({'valid': false, 'error': 'File not found: ${args[0]}'}));
    exit(1);
  }

  try {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final config = GeneratorConfig.fromJson(json, json['name'] ?? 'Unknown');
    print(jsonEncode({
      'valid': true,
      'name': config.name,
      'methods': config.methods,
      'repos': config.repos,
    }));
  } catch (e) {
    print(jsonEncode({'valid': false, 'error': e.toString()}));
    exit(1);
  }
}

// ============================================================
// Help Text
// ============================================================

void _printHelp() {
  print('''
fca - Flutter Clean Architecture Code Generator

USAGE:
  fca <command> [options]

COMMANDS:
  generate <Name>     Generate code for an entity or custom usecase
  schema              Output JSON schema for configuration
  validate <file>     Validate JSON configuration file
  help                Show this help message
  version             Show version

EXAMPLES:
  fca generate Product --methods=get,getAll,create --repository --vpc
  fca generate ProcessOrder --repos=OrderRepo,PaymentRepo --params=OrderRequest --returns=OrderResult
  echo '{"name":"Product","methods":["get","getAll"]}' | fca generate Product --from-stdin

Run 'fca generate --help' for more details on the generate command.
''');
}

void _printGenerateHelp() {
  print('''
fca generate - Generate Clean Architecture code

USAGE:
  fca generate <Name> [options]

ENTITY-BASED GENERATION:
  --methods=<list>      Comma-separated: get,getList,create,update,delete,watch,watchList
  -r, --repository      Generate repository interface
  -d, --data            Generate data repository + data source
  --datasource          Generate data source only
  --id-type=<type>      ID type for entity (default: String)

CUSTOM USECASE:
  --repos=<list>        Comma-separated repositories to inject
  --type=<type>         usecase|stream|background|completable (default: usecase)
  --params=<type>       Params type (default: NoParams)
  --returns=<type>      Return type (default: void)

VPC LAYER:
  --vpc                 Generate View + Presenter + Controller
  --view                Generate View only
  --presenter           Generate Presenter only
  --controller          Generate Controller only
  --observer            Generate Observer class

INPUT/OUTPUT:
  -j, --from-json       JSON configuration file
  --from-stdin          Read JSON from stdin
  -o, --output          Output directory (default: lib/src)
  --format=json|text    Output format (default: text)
  --dry-run             Preview without writing files
  --force               Overwrite existing files
  -v, --verbose         Verbose output
  -q, --quiet           Minimal output

EXAMPLES:
  # Entity-based CRUD with VPC
  fca generate Product --methods=get,getList,create,update,delete --repository --vpc

  # With data layer (repository impl + datasource)
  fca generate Product --methods=get,getList,create,update,delete --repository --data

  # Stream usecases
  fca generate Product --methods=watch,watchList --repository

  # Custom usecase with multiple repos
  fca generate ProcessOrder --repos=OrderRepo,PaymentRepo --params=OrderRequest --returns=OrderResult

  # Background usecase
  fca generate ProcessImages --type=background --params=ImageBatch --returns=ProcessedImage

  # From JSON
  fca generate Product -j product.json

  # From stdin (AI-friendly)
  echo '{"name":"Product","methods":["get","getList"]}' | fca generate Product --from-stdin --format=json
''');
}

void _printTextResult(GeneratorResult result) {
  if (result.success) {
    print('✅ Generated ${result.files.length} files for ${result.name}');
    print('');
    for (final file in result.files) {
      print('  ${file.action == 'created' ? '✓' : '⟳'} ${file.path}');
    }
    if (result.nextSteps.isNotEmpty) {
      print('');
      print('📝 Next steps:');
      for (final step in result.nextSteps) {
        print('   • $step');
      }
    }
  } else {
    print('❌ Generation failed');
    for (final error in result.errors) {
      print('   • $error');
    }
  }
}

// ============================================================
// Configuration
// ============================================================

class GeneratorConfig {
  final String name;
  final List<String> methods;
  final List<String> repos;
  final bool generateRepository;
  final String useCaseType;
  final String? paramsType;
  final String? returnsType;
  final String idType;
  final bool generateVpc;
  final bool generateView;
  final bool generatePresenter;
  final bool generateController;
  final bool generateObserver;
  final bool generateData;
  final bool generateDataSource;

  GeneratorConfig({
    required this.name,
    this.methods = const [],
    this.repos = const [],
    this.generateRepository = false,
    this.useCaseType = 'usecase',
    this.paramsType,
    this.returnsType,
    this.idType = 'String',
    this.generateVpc = false,
    this.generateView = false,
    this.generatePresenter = false,
    this.generateController = false,
    this.generateObserver = false,
    this.generateData = false,
    this.generateDataSource = false,
  });

  factory GeneratorConfig.fromJson(Map<String, dynamic> json, String name) {
    return GeneratorConfig(
      name: json['name'] ?? name,
      methods: (json['methods'] as List<dynamic>?)?.cast<String>() ?? [],
      repos: (json['repos'] as List<dynamic>?)?.cast<String>() ?? [],
      generateRepository: json['repository'] == true,
      useCaseType: json['type'] ?? 'usecase',
      paramsType: json['params'],
      returnsType: json['returns'],
      idType: json['id_type'] ?? 'String',
      generateVpc: json['vpc'] == true,
      generateView: json['view'] == true,
      generatePresenter: json['presenter'] == true,
      generateController: json['controller'] == true,
      generateObserver: json['observer'] == true,
      generateData: json['data'] == true,
      generateDataSource: json['datasource'] == true,
    );
  }

  /// Check if this is an entity-based generation (has methods)
  bool get isEntityBased => methods.isNotEmpty;

  /// Check if this is a custom usecase (no methods, has repos or params)
  bool get isCustomUseCase =>
      methods.isEmpty && (repos.isNotEmpty || paramsType != null);

  /// Get the list of repositories to use
  List<String> get effectiveRepos {
    if (repos.isNotEmpty) return repos;
    if (isEntityBased) return ['${name}Repository'];
    return [];
  }

  /// Get entity snake_case name
  String get nameSnake => _camelToSnake(name);

  /// Get entity camelCase name
  String get nameCamel => _pascalToCamel(name);
}

// ============================================================
// Code Generator
// ============================================================

class CodeGenerator {
  final GeneratorConfig config;
  final String outputDir;
  final bool dryRun;
  final bool force;
  final bool verbose;

  CodeGenerator({
    required this.config,
    required this.outputDir,
    this.dryRun = false,
    this.force = false,
    this.verbose = false,
  });

  Future<GeneratorResult> generate() async {
    final files = <GeneratedFile>[];
    final errors = <String>[];
    final nextSteps = <String>[];

    try {
      // Generate repository if requested
      if (config.generateRepository) {
        final file = await _generateRepository();
        files.add(file);
      }

      // Generate usecases
      if (config.isEntityBased) {
        // Entity-based: generate usecases for each method
        for (final method in config.methods) {
          final file = await _generateUseCaseForMethod(method);
          files.add(file);
        }
      } else if (config.isCustomUseCase) {
        // Custom usecase
        final file = await _generateCustomUseCase();
        files.add(file);
      }

      // Generate VPC layer
      if (config.generateVpc || config.generatePresenter) {
        final file = await _generatePresenter();
        files.add(file);
      }

      if (config.generateVpc || config.generateController) {
        final file = await _generateController();
        files.add(file);
      }

      if (config.generateVpc || config.generateView) {
        final file = await _generateView();
        files.add(file);
      }

      if (config.generateObserver) {
        final file = await _generateObserver();
        files.add(file);
      }

      // Generate data layer
      if (config.generateData || config.generateDataSource) {
        final file = await _generateDataSource();
        files.add(file);
      }

      if (config.generateData) {
        final file = await _generateDataRepository();
        files.add(file);
      }

      // Add next steps
      if (config.generateRepository) {
        nextSteps.add('Implement ${config.name}RepositoryImpl in data layer');
      }
      if (config.effectiveRepos.isNotEmpty) {
        nextSteps.add('Register repositories with DI container');
      }
      if (files.any((f) => f.type == 'usecase')) {
        nextSteps.add('Implement TODO sections in generated usecases');
      }

      return GeneratorResult(
        success: true,
        name: config.name,
        files: files,
        errors: [],
        nextSteps: nextSteps,
      );
    } catch (e) {
      errors.add(e.toString());
      return GeneratorResult(
        success: false,
        name: config.name,
        files: files,
        errors: errors,
        nextSteps: [],
      );
    }
  }

  // ============================================================
  // Repository Generation
  // ============================================================

  Future<GeneratedFile> _generateRepository() async {
    final repoName = '${config.name}Repository';
    final fileName = '${config.nameSnake}_repository.dart';
    final filePath = path.join(outputDir, 'domain', 'repositories', fileName);

    final methods = <String>[];

    for (final method in config.methods) {
      switch (method) {
        case 'get':
          methods.add('  Future<${config.name}> get(${config.idType} id);');
          break;
        case 'getList':
          methods.add('  Future<List<${config.name}>> getList();');
          break;
        case 'create':
          methods.add(
              '  Future<${config.name}> create(${config.name} ${config.nameCamel});');
          break;
        case 'update':
          methods.add(
              '  Future<${config.name}> update(${config.name} ${config.nameCamel});');
          break;
        case 'delete':
          methods.add('  Future<void> delete(${config.idType} id);');
          break;
        case 'watch':
          methods.add('  Stream<${config.name}> watch(${config.idType}? id);');
          break;
        case 'watchList':
          methods.add('  Stream<List<${config.name}>> watchList();');
          break;
      }
    }

    final content = '''
// Generated by fca
// fca generate ${config.name} --methods=${config.methods.join(',')} --repository

import '../entities/${config.nameSnake}/${config.nameSnake}.dart';

abstract class $repoName {
${methods.join('\n')}
}
''';

    return _writeFile(filePath, content, 'repository');
  }

  // ============================================================
  // UseCase Generation
  // ============================================================

  Future<GeneratedFile> _generateUseCaseForMethod(String method) async {
    final entityName = config.name;
    final entitySnake = config.nameSnake;
    final entityCamel = config.nameCamel;
    final repoName = config.effectiveRepos.first;

    String className;
    String baseClass;
    String paramsType;
    String returnType;
    String executeBody;
    bool isStream = false;
    bool isCompletable = false;
    bool needsEntityImport = true;

    switch (method) {
      case 'get':
        className = 'Get${entityName}UseCase';
        baseClass = 'UseCase<$entityName, ${config.idType}>';
        paramsType = config.idType;
        returnType = entityName;
        executeBody = 'return _repository.get(id);';
        break;
      case 'getList':
        className = 'Get${entityName}ListUseCase';
        baseClass = 'UseCase<List<$entityName>, NoParams>';
        paramsType = 'NoParams';
        returnType = 'List<$entityName>';
        executeBody = 'return _repository.getList();';
        break;
      case 'create':
        className = 'Create${entityName}UseCase';
        baseClass = 'UseCase<$entityName, $entityName>';
        paramsType = entityName;
        returnType = entityName;
        executeBody = 'return _repository.create($entityCamel);';
        break;
      case 'update':
        className = 'Update${entityName}UseCase';
        baseClass = 'UseCase<$entityName, $entityName>';
        paramsType = entityName;
        returnType = entityName;
        executeBody = 'return _repository.update($entityCamel);';
        break;
      case 'delete':
        className = 'Delete${entityName}UseCase';
        baseClass = 'CompletableUseCase<${config.idType}>';
        paramsType = config.idType;
        returnType = 'void';
        executeBody = 'return _repository.delete(id);';
        isCompletable = true;
        needsEntityImport = false;
        break;
      case 'watch':
        className = 'Watch${entityName}UseCase';
        baseClass = 'StreamUseCase<$entityName, ${config.idType}?>';
        paramsType = '${config.idType}?';
        returnType = entityName;
        executeBody = 'return _repository.watch(id);';
        isStream = true;
        break;
      case 'watchList':
        className = 'Watch${entityName}ListUseCase';
        baseClass = 'StreamUseCase<List<$entityName>, NoParams>';
        paramsType = 'NoParams';
        returnType = 'List<$entityName>';
        executeBody = 'return _repository.watchList();';
        isStream = true;
        break;
      default:
        throw ArgumentError('Unknown method: $method');
    }

    final paramName = _getParamName(method, entityCamel);
    final fileSnake = _camelToSnake(className.replaceAll('UseCase', ''));
    final fileName = '${fileSnake}_usecase.dart';
    final filePath =
        path.join(outputDir, 'domain', 'usecases', entitySnake, fileName);

    // Build imports
    final imports = <String>[
      "import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';",
    ];
    if (needsEntityImport) {
      imports.add("import '../../entities/$entitySnake/$entitySnake.dart';");
    }
    imports.add(
        "import '../../repositories/${_camelToSnake(repoName.replaceAll('Repository', ''))}_repository.dart';");

    // Build execute method based on type
    String executeMethod;
    if (isStream) {
      executeMethod = '''
  @override
  Stream<$returnType> execute($paramsType $paramName, CancelToken? cancelToken) {
    $executeBody
  }''';
    } else if (isCompletable) {
      executeMethod = '''
  @override
  Future<void> execute($paramsType $paramName, CancelToken? cancelToken) async {
    cancelToken?.throwIfCancelled();
    $executeBody
  }''';
    } else {
      executeMethod = '''
  @override
  Future<$returnType> execute($paramsType $paramName, CancelToken? cancelToken) async {
    cancelToken?.throwIfCancelled();
    $executeBody
  }''';
    }

    final content = '''
// Generated by fca

${imports.join('\n')}

class $className extends $baseClass {
  final $repoName _repository;

  $className(this._repository);

$executeMethod
}
''';

    return _writeFile(filePath, content, 'usecase');
  }

  Future<GeneratedFile> _generateCustomUseCase() async {
    final className = '${config.name}UseCase';
    final classSnake = _camelToSnake(config.name);
    final fileName = '${classSnake}_usecase.dart';
    final filePath = path.join(outputDir, 'domain', 'usecases', fileName);

    final paramsType = config.paramsType ?? 'NoParams';
    final returnsType = config.returnsType ?? 'void';

    String baseClass;
    switch (config.useCaseType) {
      case 'stream':
        baseClass = 'StreamUseCase<$returnsType, $paramsType>';
        break;
      case 'background':
        baseClass = 'BackgroundUseCase<$returnsType, $paramsType>';
        break;
      case 'completable':
        baseClass = 'CompletableUseCase<$paramsType>';
        break;
      default:
        baseClass = 'UseCase<$returnsType, $paramsType>';
    }

    // Generate repository imports and fields
    final repoImports = <String>[];
    final repoFields = <String>[];
    final repoParams = <String>[];

    for (final repo in config.effectiveRepos) {
      final repoSnake = _camelToSnake(repo.replaceAll('Repository', ''));
      repoImports.add("import '../repositories/${repoSnake}_repository.dart';");
      repoFields.add('  final $repo _${_pascalToCamel(repo)};');
      repoParams.add('this._${_pascalToCamel(repo)}');
    }

    String executeMethod;
    if (config.useCaseType == 'stream') {
      executeMethod = '''
  @override
  Stream<$returnsType> execute($paramsType params, CancelToken? cancelToken) {
    // TODO: Implement stream logic
    throw UnimplementedError();
  }''';
    } else if (config.useCaseType == 'background') {
      executeMethod = '''
  @override
  BackgroundTask<$paramsType> buildTask() => _process;

  static void _process(BackgroundTaskContext<$paramsType> context) {
    try {
      final params = context.params;

      // TODO: Implement background processing
      // context.sendData(result);

      context.sendDone();
    } catch (e, stackTrace) {
      context.sendError(e, stackTrace);
    }
  }''';
    } else {
      executeMethod = '''
  @override
  Future<$returnsType> execute($paramsType params, CancelToken? cancelToken) async {
    cancelToken?.throwIfCancelled();
    // TODO: Implement usecase logic
    throw UnimplementedError();
  }''';
    }

    final content = '''
// Generated by fca
// fca generate ${config.name} --repos=${config.repos.join(',')} --params=$paramsType --returns=$returnsType --type=${config.useCaseType}

import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
${repoImports.join('\n')}

class $className extends $baseClass {
${repoFields.join('\n')}

  $className(${repoParams.join(', ')});

$executeMethod
}
''';

    return _writeFile(filePath, content, 'usecase');
  }

  // ============================================================
  // VPC Generation
  // ============================================================

  Future<GeneratedFile> _generatePresenter() async {
    final entityName = config.name;
    final entitySnake = config.nameSnake;
    final entityCamel = config.nameCamel;
    final presenterName = '${entityName}Presenter';
    final fileName = '${entitySnake}_presenter.dart';
    final filePath =
        path.join(outputDir, 'presentation', entitySnake, fileName);

    // Generate imports
    final imports = <String>[
      "import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';",
      "import '../../domain/entities/$entitySnake/$entitySnake.dart';",
    ];

    // Repository imports and fields
    final repoFields = <String>[];
    final repoParams = <String>[];
    final repoParamsNamed = <String>[];

    for (final repo in config.effectiveRepos) {
      final repoSnake = _camelToSnake(repo.replaceAll('Repository', ''));
      final repoCamel = _pascalToCamel(repo);
      imports.add(
          "import '../../domain/repositories/${repoSnake}_repository.dart';");
      repoFields.add('  final $repo $repoCamel;');
      repoParams.add('required this.$repoCamel');
      repoParamsNamed.add(repoCamel);
    }

    // UseCase imports and fields
    final useCaseImports = <String>[];
    final useCaseFields = <String>[];
    final useCaseRegistrations = <String>[];
    final presenterMethods = <String>[];

    for (final method in config.methods) {
      final useCaseInfo = _getUseCaseInfo(method, entityName, entityCamel);
      final useCaseSnake =
          _camelToSnake(useCaseInfo.className.replaceAll('UseCase', ''));

      useCaseImports.add(
          "import '../../domain/usecases/$entitySnake/${useCaseSnake}_usecase.dart';");
      useCaseFields.add(
          '  late final ${useCaseInfo.className} _${useCaseInfo.fieldName};');

      final mainRepo = config.effectiveRepos.isNotEmpty
          ? _pascalToCamel(config.effectiveRepos.first)
          : 'repository';
      useCaseRegistrations.add(
          '    _${useCaseInfo.fieldName} = registerUseCase(${useCaseInfo.className}($mainRepo));');

      presenterMethods.add(useCaseInfo.presenterMethod);
    }

    final content = '''
// Generated by fca
// fca generate $entityName --methods=${config.methods.join(',')} --vpc

${imports.join('\n')}
${useCaseImports.join('\n')}

class $presenterName extends Presenter {
${repoFields.join('\n')}

${useCaseFields.join('\n')}

  $presenterName({
    ${repoParams.join(',\n    ')},
  }) {
${useCaseRegistrations.join('\n')}
  }

${presenterMethods.join('\n\n')}
}
''';

    return _writeFile(filePath, content, 'presenter');
  }

  Future<GeneratedFile> _generateController() async {
    final entityName = config.name;
    final entitySnake = config.nameSnake;
    final controllerName = '${entityName}Controller';
    final presenterName = '${entityName}Presenter';
    final fileName = '${entitySnake}_controller.dart';
    final filePath =
        path.join(outputDir, 'presentation', entitySnake, fileName);

    final content = '''
// Generated by fca
// fca generate $entityName --methods=${config.methods.join(',')} --vpc

import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '${entitySnake}_presenter.dart';

class $controllerName extends Controller {
  final $presenterName _presenter;

  $controllerName(this._presenter);

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
''';

    return _writeFile(filePath, content, 'controller');
  }

  Future<GeneratedFile> _generateView() async {
    final entityName = config.name;
    final entitySnake = config.nameSnake;
    final viewName = '${entityName}View';
    final controllerName = '${entityName}Controller';
    final presenterName = '${entityName}Presenter';
    final fileName = '${entitySnake}_view.dart';
    final filePath =
        path.join(outputDir, 'presentation', entitySnake, fileName);

    // Generate repository imports and constructor params
    final repoImports = <String>[];
    final repoFields = <String>[];
    final repoConstructorParams = <String>[];
    final repoPresenterParams = <String>[];

    for (final repo in config.effectiveRepos) {
      final repoSnake = _camelToSnake(repo.replaceAll('Repository', ''));
      final repoCamel = _pascalToCamel(repo);
      repoImports.add(
          "import '../../domain/repositories/${repoSnake}_repository.dart';");
      repoFields.add('  final $repo $repoCamel;');
      repoConstructorParams.add('required this.$repoCamel');
      repoPresenterParams.add('$repoCamel: $repoCamel');
    }

    final content = '''
// Generated by fca
// fca generate $entityName --methods=${config.methods.join(',')} --vpc
// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
${repoImports.join('\n')}
import '${entitySnake}_controller.dart';
import '${entitySnake}_presenter.dart';

class $viewName extends CleanView {
${repoFields.join('\n')}

  const $viewName({
    super.key,
    super.routeObserver,
    ${repoConstructorParams.join(',\n    ')},
  });

  @override
  State<$viewName> createState() => _${viewName}State(
        $controllerName(
          $presenterName(
            ${repoPresenterParams.join(',\n            ')},
          ),
        ),
      );
}

class _${viewName}State extends CleanViewState<$viewName, $controllerName> {
  _${viewName}State(super.controller);

  @override
  Widget get view {
    return Scaffold(
      key: globalKey,
      appBar: AppBar(
        title: const Text('$entityName'),
      ),
      body: ControlledWidgetBuilder<$controllerName>(
        builder: (context, controller) {
          return Container();
        },
      ),
    );
  }
}
''';

    return _writeFile(filePath, content, 'view');
  }

  Future<GeneratedFile> _generateObserver() async {
    final entityName = config.name;
    final entitySnake = config.nameSnake;
    final observerName = '${entityName}Observer';
    final fileName = '${entitySnake}_observer.dart';
    final filePath =
        path.join(outputDir, 'domain', 'usecases', entitySnake, fileName);

    final content = '''
// Generated by fca

import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../entities/$entitySnake/$entitySnake.dart';

class $observerName extends Observer<$entityName> {
  final void Function($entityName) onNext;
  final void Function(AppFailure) onError;
  final void Function() onComplete;

  $observerName({
    required this.onNext,
    required this.onError,
    required this.onComplete,
  });

  @override
  void onNextValue($entityName value) => onNext(value);

  @override
  void onFailure(AppFailure failure) => onError(failure);

  @override
  void onDone() => onComplete();
}
''';

    return _writeFile(filePath, content, 'observer');
  }

  // ============================================================
  // Data Layer Generation
  // ============================================================

  Future<GeneratedFile> _generateDataSource() async {
    final entityName = config.name;
    final entitySnake = config.nameSnake;
    final entityCamel = config.nameCamel;
    final dataSourceName = '${entityName}DataSource';
    final fileName = '${entitySnake}_data_source.dart';
    final filePath =
        path.join(outputDir, 'data', 'data_sources', entitySnake, fileName);

    final methods = <String>[];

    for (final method in config.methods) {
      switch (method) {
        case 'get':
          methods.add('  Future<${entityName}> get(${config.idType} id);');
          break;
        case 'getList':
          methods.add('  Future<List<${entityName}>> getList();');
          break;
        case 'create':
          methods.add(
              '  Future<${entityName}> create(${entityName} ${entityCamel});');
          break;
        case 'update':
          methods.add(
              '  Future<${entityName}> update(${entityName} ${entityCamel});');
          break;
        case 'delete':
          methods.add('  Future<void> delete(${config.idType} id);');
          break;
        case 'watch':
          methods.add('  Stream<${entityName}> watch(${config.idType}? id);');
          break;
        case 'watchList':
          methods.add('  Stream<List<${entityName}>> watchList();');
          break;
      }
    }

    final content = '''
// Generated by fca
// fca generate $entityName --methods=${config.methods.join(',')} --data

import '../../../domain/entities/$entitySnake/$entitySnake.dart';

abstract class $dataSourceName {
${methods.join('\n')}
}
''';

    return _writeFile(filePath, content, 'datasource');
  }

  Future<GeneratedFile> _generateDataRepository() async {
    final entityName = config.name;
    final entitySnake = config.nameSnake;
    final entityCamel = config.nameCamel;
    final repoName = '${entityName}Repository';
    final dataRepoName = 'Data${entityName}Repository';
    final dataSourceName = '${entityName}DataSource';
    final fileName = 'data_${entitySnake}_repository.dart';
    final filePath = path.join(outputDir, 'data', 'repositories', fileName);

    final methods = <String>[];

    for (final method in config.methods) {
      switch (method) {
        case 'get':
          methods.add('''
  @override
  Future<$entityName> get(${config.idType} id) {
    return _dataSource.get(id);
  }''');
          break;
        case 'getList':
          methods.add('''
  @override
  Future<List<$entityName>> getList() {
    return _dataSource.getList();
  }''');
          break;
        case 'create':
          methods.add('''
  @override
  Future<$entityName> create($entityName $entityCamel) {
    return _dataSource.create($entityCamel);
  }''');
          break;
        case 'update':
          methods.add('''
  @override
  Future<$entityName> update($entityName $entityCamel) {
    return _dataSource.update($entityCamel);
  }''');
          break;
        case 'delete':
          methods.add('''
  @override
  Future<void> delete(${config.idType} id) {
    return _dataSource.delete(id);
  }''');
          break;
        case 'watch':
          methods.add('''
  @override
  Stream<$entityName> watch(${config.idType}? id) {
    return _dataSource.watch(id);
  }''');
          break;
        case 'watchList':
          methods.add('''
  @override
  Stream<List<$entityName>> watchList() {
    return _dataSource.watchList();
  }''');
          break;
      }
    }

    final content = '''
// Generated by fca
// fca generate $entityName --methods=${config.methods.join(',')} --data

import '../../domain/entities/$entitySnake/$entitySnake.dart';
import '../../domain/repositories/${entitySnake}_repository.dart';
import '../data_sources/$entitySnake/${entitySnake}_data_source.dart';

class $dataRepoName implements $repoName {
  final $dataSourceName _dataSource;

  $dataRepoName(this._dataSource);

${methods.join('\n\n')}
}
''';

    return _writeFile(filePath, content, 'data_repository');
  }

  // ============================================================
  // Helpers
  // ============================================================

  Future<GeneratedFile> _writeFile(
      String filePath, String content, String type) async {
    final file = File(filePath);
    final exists = file.existsSync();

    if (exists && !force) {
      if (verbose) {
        print('  ⏭ Skipping existing file: $filePath');
      }
      return GeneratedFile(
        path: filePath,
        type: type,
        action: 'skipped',
      );
    }

    if (!dryRun) {
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    if (verbose) {
      final action = exists ? 'Overwriting' : 'Creating';
      print('  ✓ $action: $filePath');
    }

    return GeneratedFile(
      path: filePath,
      type: type,
      action: exists ? 'overwritten' : 'created',
    );
  }

  String _getParamName(String method, String entityCamel) {
    switch (method) {
      case 'get':
      case 'delete':
      case 'watch':
        return 'id';
      case 'getList':
      case 'watchList':
        return 'params';
      case 'create':
      case 'update':
        return entityCamel;
      default:
        return 'params';
    }
  }

  _UseCaseInfo _getUseCaseInfo(
      String method, String entityName, String entityCamel) {
    switch (method) {
      case 'get':
        return _UseCaseInfo(
          className: 'Get${entityName}UseCase',
          fieldName: 'get$entityName',
          presenterMethod:
              '''  Future<Result<$entityName, AppFailure>> get$entityName(String id) {
    return execute(_get$entityName, id);
  }''',
        );
      case 'getList':
        return _UseCaseInfo(
          className: 'Get${entityName}ListUseCase',
          fieldName: 'get${entityName}List',
          presenterMethod:
              '''  Future<Result<List<$entityName>, AppFailure>> get${entityName}List() {
    return execute(_get${entityName}List, const NoParams());
  }''',
        );
      case 'create':
        return _UseCaseInfo(
          className: 'Create${entityName}UseCase',
          fieldName: 'create$entityName',
          presenterMethod:
              '''  Future<Result<$entityName, AppFailure>> create$entityName($entityName $entityCamel) {
    return execute(_create$entityName, $entityCamel);
  }''',
        );
      case 'update':
        return _UseCaseInfo(
          className: 'Update${entityName}UseCase',
          fieldName: 'update$entityName',
          presenterMethod:
              '''  Future<Result<$entityName, AppFailure>> update$entityName($entityName $entityCamel) {
    return execute(_update$entityName, $entityCamel);
  }''',
        );
      case 'delete':
        return _UseCaseInfo(
          className: 'Delete${entityName}UseCase',
          fieldName: 'delete$entityName',
          presenterMethod:
              '''  Future<Result<void, AppFailure>> delete$entityName(String id) {
    return execute(_delete$entityName, id);
  }''',
        );
      case 'watch':
        return _UseCaseInfo(
          className: 'Watch${entityName}UseCase',
          fieldName: 'watch$entityName',
          presenterMethod:
              '''  Stream<Result<$entityName, AppFailure>> watch$entityName(String? id) {
    return executeStream(_watch$entityName, id);
  }''',
        );
      case 'watchList':
        return _UseCaseInfo(
          className: 'Watch${entityName}ListUseCase',
          fieldName: 'watch${entityName}List',
          presenterMethod:
              '''  Stream<Result<List<$entityName>, AppFailure>> watch${entityName}List() {
    return executeStream(_watch${entityName}List, const NoParams());
  }''',
        );
      default:
        throw ArgumentError('Unknown method: $method');
    }
  }
}

class _UseCaseInfo {
  final String className;
  final String fieldName;
  final String presenterMethod;

  _UseCaseInfo({
    required this.className,
    required this.fieldName,
    required this.presenterMethod,
  });
}

// ============================================================
// Result Types
// ============================================================

class GeneratorResult {
  final bool success;
  final String name;
  final List<GeneratedFile> files;
  final List<String> errors;
  final List<String> nextSteps;

  GeneratorResult({
    required this.success,
    required this.name,
    required this.files,
    required this.errors,
    required this.nextSteps,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'name': name,
        'generated': files.map((f) => f.toJson()).toList(),
        'errors': errors,
        'next_steps': nextSteps,
      };
}

class GeneratedFile {
  final String path;
  final String type;
  final String action;

  GeneratedFile({
    required this.path,
    required this.type,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'path': path,
        'action': action,
      };
}

// ============================================================
// String Utilities
// ============================================================

String _camelToSnake(String input) {
  if (input.isEmpty) return '';
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (i > 0 && char.toUpperCase() == char && char != '_') {
      buffer.write('_');
    }
    buffer.write(char.toLowerCase());
  }
  return buffer.toString();
}

String _pascalToCamel(String input) {
  if (input.isEmpty) return '';
  return input[0].toLowerCase() + input.substring(1);
}
