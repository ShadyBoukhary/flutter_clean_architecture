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

    // Set up the stream first to ensure it's ready
    final stream =
        stdin.transform(utf8.decoder).transform(const LineSplitter());

    // Keep the process alive indefinitely
    // Use a completer that never completes to prevent exit
    final keepAlive = Completer<void>();

    // Start processing messages IMMEDIATELY before any delays
    // This ensures we don't miss any early messages from Zed
    _processStream(stream).catchError((e) {
      stderr.writeln('Message processor error: $e');
      // Don't exit - keep the process alive
    });

    // Wait forever - this keeps the process alive even if stdin closes
    await keepAlive.future;
  }

  /// Process stdin messages from the provided stream
  Future<void> _processStream(Stream<String> stream) async {
    final completer = Completer<void>();

    // Use subscription instead of await-for to prevent early exit
    stream.listen(
      (line) async {
        if (line.isEmpty) return;

        try {
          final request = jsonDecode(line) as Map<String, dynamic>;
          final response = await handleRequest(request);
          stdout.writeln(jsonEncode(response));
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
        }
      },
      onError: (e) {
        stderr.writeln('Stream error: $e');
        // Don't complete - keep listening
      },
      onDone: () {
        // Stdin closed - but don't log anything to avoid confusing Zed
        // Just keep the process alive silently
        // Don't complete the completer - process stays alive forever
      },
      cancelOnError: false,
    );

    // Wait forever - never complete this future
    await completer.future;
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
          'state': {
            'type': 'boolean',
            'description': 'Generate State object',
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
            'description':
                'ID type for entity - ONLY include if user explicitly specifies (default: String)',
          },
          'repos': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Repositories to inject (for custom UseCases)',
          },
          'params': {
            'type': 'string',
            'description':
                'Params type for custom UseCase - ONLY include if user explicitly specifies (default: NoParams)',
          },
          'returns': {
            'type': 'string',
            'description':
                'Return type for custom UseCase - ONLY include if user explicitly specifies (default: void)',
          },
          'type': {
            'type': 'string',
            'enum': ['usecase', 'stream', 'background', 'completable'],
            'description': 'UseCase type for custom UseCases',
          },
          'output': {
            'type': 'string',
            'description':
                'Output directory - ONLY include if user explicitly specifies a custom path. Do NOT guess or include default value.',
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

      switch (toolName) {
        case 'fca_generate':
          result = await _runGenerateCommand(args);
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
    if (args['state'] == true) cliArgs.add('--state');
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

      final collected = <Map<String, dynamic>>[];
      final listingFuture = _doResourceListing(collected);

      // Use a longer timeout for IDE restart scenarios, but return partial results
      final cached = await listingFuture.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          // Return whatever we've collected so far (partial results)
          stderr.writeln(
              'Resource listing timeout, returning ${collected.length} partial results');
          return collected.take(_maxFiles).toList();
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
