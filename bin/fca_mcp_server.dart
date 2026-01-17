import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// MCP Server for Flutter Clean Architecture CLI
///
/// This server implements the Model Context Protocol to expose
/// fca CLI functionality as MCP tools.
///
/// Run with: dart run flutter_clean_architecture:fca_mcp_server
void main() async {
  final server = FcaMcpServer();
  await server.run();
}

class FcaMcpServer {
  // Cache for resource listings to avoid repeated filesystem scans
  List<Map<String, dynamic>>? _resourcesCache;
  DateTime? _resourcesCacheTime;
  static const _cacheDuration = Duration(minutes: 10);

  // Maximum files to return to prevent large responses
  static const _maxFiles = 100;

  /// Main server loop that handles JSON-RPC messages
  Future<void> run() async {
    // Enable stdin line reading
    // These settings may fail in non-TTY contexts (like when stdin is piped)
    try {
      stdin.echoMode = false;
    } catch (_) {
      // Ignore errors in piped context
    }
    try {
      stdin.lineMode = true;
    } catch (_) {
      // Ignore errors in piped context
    }

    // Process messages
    await for (final line
        in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.isEmpty) continue;

      try {
        final request = jsonDecode(line) as Map<String, dynamic>;
        final response = await handleRequest(request);
        stdout.writeln(jsonEncode(response));
        await stdout.flush();
      } catch (e, stackTrace) {
        stderr.writeln('Error processing request: $e\n$stackTrace');
        final errorResponse = {
          'jsonrpc': '2.0',
          'error': {
            'code': -32603,
            'message': 'Internal error: ${e.toString()}',
          },
          'id': null,
        };
        stdout.writeln(jsonEncode(errorResponse));
        await stdout.flush();
      }
    }
  }

  /// Handle incoming JSON-RPC requests
  Future<Map<String, dynamic>> handleRequest(
      Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final id = request['id'];

    switch (method) {
      case 'initialize':
        return _initialize(id);
      case 'tools/list':
        return _listTools(id);
      case 'tools/call':
        return await _callTool(
            id, request['params'] as Map<String, dynamic>? ?? {});
      case 'resources/list':
        return await _listResources(id);
      case 'resources/read':
        return await _readResource(
            id, request['params'] as Map<String, dynamic>? ?? {});
      case 'shutdown':
        // Graceful shutdown
        return _success(id, {});
      case 'ping':
        return _success(id, {'pong': true});
      default:
        return _error(id, -32601, 'Method not found: $method');
    }
  }

  /// Handle initialize request
  Map<String, dynamic> _initialize(dynamic id) {
    return {
      'jsonrpc': '2.0',
      'result': {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'tools': {'listChanged': true},
          'resources': {'subscribe': true, 'listChanged': true},
          'prompts': {},
        },
        'serverInfo': {
          'name': 'fca-mcp-server',
          'version': '1.0.0',
        },
      },
      'id': id,
    };
  }

  /// List available tools
  Map<String, dynamic> _listTools(dynamic id) {
    return {
      'jsonrpc': '2.0',
      'result': {
        'tools': [
          _generateToolDefinition(),
          _schemaToolDefinition(),
          _validateToolDefinition(),
        ],
      },
      'id': id,
    };
  }

  /// Generate tool definition
  Map<String, dynamic> _generateToolDefinition() {
    return {
      'name': 'fca_generate',
      'description':
          'Generate Clean Architecture code for Flutter projects including UseCases, Repositories, Views, Presenters, Controllers, and Data layers',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'name': {
            'type': 'string',
            'description':
                'Entity or UseCase name in PascalCase (e.g., Product, ProcessOrder)'
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
              ]
            },
            'description': 'Methods to generate for entity-based UseCases',
          },
          'repository': {
            'type': 'boolean',
            'description': 'Generate repository interface',
          },
          'vpc': {
            'type': 'boolean',
            'description':
                'Generate View, Presenter, and Controller (presentation layer)',
          },
          'data': {
            'type': 'boolean',
            'description': 'Generate data layer (DataRepository + DataSource)',
          },
          'datasource': {
            'type': 'boolean',
            'description': 'Generate DataSource only',
          },
          'id_type': {
            'type': 'string',
            'description': 'ID type for entity (default: String)',
          },
          'repos': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Repositories to inject (for custom UseCases)',
          },
          'params': {
            'type': 'string',
            'description': 'Params type for custom UseCase (default: NoParams)',
          },
          'returns': {
            'type': 'string',
            'description': 'Return type for custom UseCase (default: void)',
          },
          'type': {
            'type': 'string',
            'enum': ['usecase', 'stream', 'background', 'completable'],
            'description': 'UseCase type for custom UseCases',
          },
          'output': {
            'type': 'string',
            'description': 'Output directory (default: lib/src)',
          },
          'dry_run': {
            'type': 'boolean',
            'description': 'Preview without writing files',
          },
          'force': {
            'type': 'boolean',
            'description': 'Overwrite existing files',
          },
          'verbose': {
            'type': 'boolean',
            'description': 'Enable verbose output',
          },
        },
        'required': ['name'],
      },
    };
  }

  /// Schema tool definition
  Map<String, dynamic> _schemaToolDefinition() {
    return {
      'name': 'fca_schema',
      'description':
          'Get the JSON schema for FCA configuration validation. Useful for AI agents to validate configs before generation.',
      'inputSchema': {
        'type': 'object',
        'properties': {},
      },
    };
  }

  /// Validate tool definition
  Map<String, dynamic> _validateToolDefinition() {
    return {
      'name': 'fca_validate',
      'description':
          'Validate a JSON configuration file against the FCA schema',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'config': {
            'type': 'object',
            'description': 'The configuration object to validate',
          },
        },
        'required': ['config'],
      },
    };
  }

  /// Handle tool calls
  Future<Map<String, dynamic>> _callTool(
      dynamic id, Map<String, dynamic> params) async {
    final toolName = params['name'] as String;
    final args = params['arguments'] as Map<String, dynamic>? ?? {};

    try {
      String result;
      List<String> generatedFiles = [];

      switch (toolName) {
        case 'fca_generate':
          result = await _runGenerateCommand(args);
          // Parse generated files from result to send notifications
          generatedFiles = _extractGeneratedFiles(result);
          break;
        case 'fca_schema':
          result = await _runSchemaCommand();
          break;
        case 'fca_validate':
          result = await _runValidateCommand(args);
          break;
        default:
          return _error(id, -32602, 'Unknown tool: $toolName');
      }

      // Send resource change notifications for generated files
      for (final filePath in generatedFiles) {
        _sendResourceNotification('created', filePath);
      }

      return {
        'jsonrpc': '2.0',
        'result': {
          'content': [
            {
              'type': 'text',
              'text': result,
            }
          ]
        },
        'id': id,
      };
    } catch (e, stackTrace) {
      return {
        'jsonrpc': '2.0',
        'result': {
          'content': [
            {
              'type': 'text',
              'text':
                  'Error: ${e.toString()}\n\nStack trace:\n${stackTrace.toString()}',
            }
          ],
          'isError': true,
        },
        'id': id,
      };
    }
  }

  /// Run the generate command
  Future<String> _runGenerateCommand(Map<String, dynamic> args) async {
    final List<String> cliArgs = ['generate', args['name'] as String];

    // Entity-based options
    if (args['methods'] != null) {
      final methods = args['methods'] as List;
      if (methods.isNotEmpty) {
        cliArgs.add('--methods=${methods.join(',')}');
      }
    }
    if (args['repository'] == true) cliArgs.add('--repository');
    if (args['vpc'] == true) cliArgs.add('--vpc');
    if (args['data'] == true) cliArgs.add('--data');
    if (args['datasource'] == true) cliArgs.add('--datasource');
    if (args['id_type'] != null) cliArgs.add('--id-type=${args['id_type']}');

    // Custom UseCase options
    if (args['repos'] != null) {
      final repos = args['repos'] as List;
      if (repos.isNotEmpty) {
        cliArgs.add('--repos=${repos.join(',')}');
      }
    }
    if (args['params'] != null) cliArgs.add('--params=${args['params']}');
    if (args['returns'] != null) cliArgs.add('--returns=${args['returns']}');
    if (args['type'] != null) cliArgs.add('--type=${args['type']}');

    // Output options
    if (args['output'] != null) cliArgs.add('--output=${args['output']}');
    if (args['dry_run'] == true) cliArgs.add('--dry-run');
    if (args['force'] == true) cliArgs.add('--force');
    if (args['verbose'] == true) cliArgs.add('--verbose');

    // Always use JSON format for parsing
    cliArgs.add('--format=json');

    return await _runFcaProcess(cliArgs);
  }

  /// Run the schema command
  Future<String> _runSchemaCommand() async {
    return await _runFcaProcess(['schema']);
  }

  /// Run the validate command
  Future<String> _runValidateCommand(Map<String, dynamic> args) async {
    // Write config to temp file
    final tempFile = File('.fca_mcp_temp_config.json');
    try {
      await tempFile.writeAsString(jsonEncode(args['config']));

      final result = await _runFcaProcess(['validate', tempFile.path]);

      // Clean up
      try {
        await tempFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }

      return result;
    } catch (e) {
      // Clean up on error
      try {
        await tempFile.delete();
      } catch (_) {
        // Ignore cleanup errors
      }
      rethrow;
    }
  }

  /// Execute fca CLI process
  Future<String> _runFcaProcess(List<String> args) async {
    // Find the Dart executable
    final dartExecutable = Platform.executable;

    // Check if we're running from the package or need to call it globally
    // Try to use 'dart run' with the package first
    final process = await Process.run(
      dartExecutable,
      ['run', 'flutter_clean_architecture:fca', ...args],
      environment: {...Platform.environment},
      workingDirectory: Directory.current.path,
    );

    final stdoutStr = process.stdout as String;
    final stderrStr = process.stderr as String;

    if (process.exitCode != 0) {
      throw ProcessException(
        'fca',
        args,
        stderrStr.isNotEmpty ? stderrStr : stdoutStr,
        process.exitCode,
      );
    }

    // If the output looks like JSON, pretty-print it for readability
    try {
      final json = jsonDecode(stdoutStr) as Map<String, dynamic>;
      return jsonEncode(json);
    } catch (_) {
      // Not JSON, return as-is
      return stdoutStr;
    }
  }

  /// Create a success response
  Map<String, dynamic> _success(dynamic id, Map<String, dynamic> result) {
    return {
      'jsonrpc': '2.0',
      'result': result,
      'id': id,
    };
  }

  /// Create an error response
  Map<String, dynamic> _error(dynamic id, int code, String message) {
    return {
      'jsonrpc': '2.0',
      'error': {
        'code': code,
        'message': message,
      },
      'id': id,
    };
  }

  /// List available resources (generated files)
  Future<Map<String, dynamic>> _listResources(dynamic id) async {
    try {
      // Return cached results if available and fresh
      if (_resourcesCache != null &&
          _resourcesCacheTime != null &&
          DateTime.now().difference(_resourcesCacheTime!) < _cacheDuration) {
        return {
          'jsonrpc': '2.0',
          'result': {'resources': _resourcesCache!.take(_maxFiles).toList()},
          'id': id,
        };
      }

      final resources = <Map<String, dynamic>>[];

      // Add overall timeout for entire listing operation
      await Future.delayed(Duration.zero).timeout(
        Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Resource listing timed out');
        },
      );

      // Add overall timeout for entire listing operation
      final collected = <Map<String, dynamic>>[];
      final listingFuture = _doResourceListing(collected);

      final cached = await listingFuture.timeout(
        Duration(seconds: 3),
        onTimeout: () {
          // Return whatever we've collected so far
          return resources.take(_maxFiles).toList();
        },
      );

      _resourcesCache = cached;
      _resourcesCacheTime = DateTime.now();

      return {
        'jsonrpc': '2.0',
        'result': {'resources': _resourcesCache},
        'id': id,
      };
    } catch (e) {
      stderr.writeln('Error listing resources: $e');
      return _error(id, -32603, 'Failed to list resources: ${e.toString()}');
    }
  }

  /// Read a resource's contents
  Future<Map<String, dynamic>> _readResource(
      dynamic id, Map<String, dynamic> params) async {
    final uri = params['uri'] as String?;

    if (uri == null) {
      return _error(id, -32602, 'Missing uri parameter');
    }

    try {
      final file = File(uri.replaceFirst('file://', ''));
      if (!await file.exists()) {
        return _error(id, -32602, 'Resource not found: $uri');
      }

      final contents = await file.readAsString();

      return {
        'jsonrpc': '2.0',
        'result': {
          'contents': [
            {
              'uri': uri,
              'mimeType': 'text/dart',
              'text': contents,
            }
          ]
        },
        'id': id,
      };
    } catch (e) {
      return _error(id, -32603, 'Error reading resource: ${e.toString()}');
    }
  }

  /// Extract generated file paths from JSON response
  List<String> _extractGeneratedFiles(String jsonResponse) {
    try {
      final json = jsonDecode(jsonResponse) as Map<String, dynamic>;
      final generated = json['generated'] as List<dynamic>?;
      if (generated == null) return [];

      return generated
          .map((item) => item['path'] as String?)
          .whereType<String>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Scan a directory and add found Dart files to resources
  Future<void> _scanDirectory(
    String dirPath,
    List<Map<String, dynamic>> resources, {
    String prefix = '',
  }) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;

      // List with timeout - wrap in try-catch to skip slow directories
      try {
        final entities = await dir.list().toList().timeout(
              const Duration(milliseconds: 300),
              onTimeout: () => [],
            );

        for (final entity in entities) {
          try {
            if (entity is File && entity.path.endsWith('.dart')) {
              final relativePath = entity.path.replaceFirst('$dirPath/', '');
              final name =
                  relativePath.replaceAll('/', '.').replaceAll('.dart', '');

              resources.add({
                'uri': 'file://${entity.path}',
                'name': name,
                'description': '$prefix$relativePath',
                'mimeType': 'text/dart',
              });
            }
          } catch (_) {
            // Skip problematic files silently
          }
        }
      } catch (_) {
        // Skip slow or problematic directories silently
      }
    } catch (_) {
      // Skip problematic directories silently
    }
  }

  /// Send resource change notification
  void _sendResourceNotification(String changeType, String uri) {
    // Invalidate cache when files are modified
    _resourcesCache = null;
    _resourcesCacheTime = null;

    final notification = {
      'jsonrpc': '2.0',
      'method': 'notifications/resources/list_changed',
      'params': {
        'changes': [
          {
            'type': changeType,
            'uri': 'file://$uri',
          }
        ]
      },
    };
    stdout.writeln(jsonEncode(notification));
  }

  /// Perform actual resource listing with timeouts
  Future<List<Map<String, dynamic>>> _doResourceListing(
      List<Map<String, dynamic>> collected) async {
    // Scan common FCA directories for Dart files (single level only)
    final directories = [
      'lib/src/domain/repositories',
      'lib/src/domain/usecases',
      'lib/src/data/data_sources',
      'lib/src/data/repositories',
      'lib/src/presentation',
    ];

    // Scan directories sequentially to reduce overhead
    for (final dirPath in directories) {
      await _scanDirectory(dirPath, collected);
      if (collected.length >= _maxFiles) break;
    }

    // Scan entities directory if we haven't hit the limit
    if (collected.length < _maxFiles) {
      await _scanDirectory('lib/src/domain/entities', collected,
          prefix: 'entity/');
    }

    return collected.take(_maxFiles).toList();
  }
}
