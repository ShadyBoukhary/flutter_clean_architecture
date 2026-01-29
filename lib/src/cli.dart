// Flutter Clean Architecture CLI Tool
//
// This file contains the command-line interface for the Flutter Clean Architecture package.
// It provides developers with a convenient way to scaffold Clean Architecture components
// in their Flutter projects, following Uncle Bob's Clean Architecture principles.
//
// The CLI supports two main operations:
// 1. Creating the default Clean Architecture folder structure
// 2. Generating individual pages with their associated Controller, Presenter, and View files
//
// Usage examples:
// - flutter pub run flutter_clean_architecture:cli create
// - flutter pub run flutter_clean_architecture:cli create --page user_profile
// - flutter pub run flutter_clean_architecture:cli --help

import 'dart:io';

import 'package:args/args.dart';

/// Main entry point for the Flutter Clean Architecture CLI tool.
///
/// This function parses command-line arguments and executes the appropriate
/// operations based on the provided commands and options.
///
/// ## Supported Commands:
/// - `create`: Generates Clean Architecture components
///   - `--page <name>`: Creates a specific page with Controller, Presenter, and View
///   - No arguments: Creates the default folder structure
///
/// ## Supported Flags:
/// - `--help` or `-h`: Displays help information
///
/// ## Error Handling:
/// The function includes comprehensive error handling for:
/// - Invalid command formats (FormatException)
/// - File system errors (FileSystemException)
/// - Invalid arguments (ArgumentError)
/// - Unexpected errors
///
/// ## Exit Codes:
/// - `0`: Success
/// - `1`: Validation error (invalid page name, page already exists)
/// - `2`: Command line parsing error or missing arguments
///
/// @param args Command-line arguments passed to the CLI
/// @throws FormatException When command format is invalid
/// @throws FileSystemException When file operations fail
/// @throws ArgumentError When arguments are invalid
Future<void> run(List<String> args) async {
  // Create argument parser for the 'create' command
  var create = ArgParser();
  create.addOption('page', abbr: 'p', help: 'Creates page with given value.');

  // Create main argument parser with commands and flags
  var parser = ArgParser();
  parser.addCommand('create', create);
  parser.addFlag('help',
      abbr: 'h', help: 'Show this message and exit.', negatable: false);

  try {
    // Parse command-line arguments
    var results = parser.parse(args);

    // Handle help flag - show appropriate help content
    if (results['help']) {
      if (results.command != null && results.command!.name == 'create') {
        _printCreateCommandHelpContent(create);
        exit(0);
      } else {
        _printDefaultHelpContent(parser);
        exit(0);
      }
    }

    // Execute commands based on parsed arguments
    if (results.command != null) {
      if (results.command!.name == 'create' &&
          results.command!['page'] != null) {
        // Create a specific page with the given name
        await _createPage(results.command?['page']);
        exit(0);
      } else if (results.command!.arguments.isEmpty) {
        // Create default Clean Architecture folder structure
        await _createDefaultArchitectureFolders();
        exit(0);
      } else {
        // Invalid arguments provided
        CliLogger.error('Missing or invalid arguments.');
        _printDefaultHelpContent(parser);
        exit(2);
      }
    } else {
      // No command provided
      CliLogger.error('Missing or invalid arguments.');
      _printDefaultHelpContent(parser);
      exit(2);
    }
  } catch (e) {
    // Comprehensive error handling for different exception types
    if (e is FormatException) {
      CliLogger.error('Invalid command format: ${e.message}');
    } else if (e is FileSystemException) {
      CliLogger.error('File system error: ${e.message}');
    } else if (e is ArgumentError) {
      CliLogger.error('Invalid argument: ${e.message}');
    } else {
      CliLogger.error('Unexpected error: ${e.toString()}');
    }
    _printDefaultHelpContent(parser);
    exit(2);
  }
}

/// Creates the default Clean Architecture folder structure in the current project.
///
/// This function generates the complete folder hierarchy following Clean Architecture
/// principles, organizing code into four distinct layers:
///
/// ## Generated Structure:
/// ```
/// lib/src/
/// ├── app/                    # Application Layer (UI & Presentation)
/// │   ├── pages/             # Page-specific components (Controllers, Presenters, Views)
/// │   ├── widgets/           # Reusable UI components
/// │   ├── utils/             # Application utilities and helpers
/// │   └── navigator.dart     # Navigation configuration
/// ├── data/                  # Data Layer (External Data Sources)
/// │   ├── repositories/      # Data access implementations (API, Database)
/// │   ├── helpers/           # Data processing helpers (HTTP, JSON parsing)
/// │   └── constants.dart     # Data-related constants (API endpoints, keys)
/// ├── device/                # Device Layer (Platform-specific)
/// │   ├── repositories/      # Platform-specific implementations (GPS, Camera)
/// │   └── utils/             # Device utilities
/// └── domain/                # Domain Layer (Business Logic)
///     ├── entities/          # Business objects and models
///     ├── usecases/          # Business logic and application rules
///     └── repositories/      # Repository interfaces (abstractions)
/// ```
///
/// @throws FileSystemException If folder creation fails
/// @throws Exception If any unexpected error occurs during folder creation
Future<void> _createDefaultArchitectureFolders() async {
  CliLogger.info('Creating Architecture Folders...');
  var dir = '${Directory.current.path}/lib/src/';

  try {
    // Create all folders and files concurrently for better performance
    await Future.wait([
      // App Layer - UI and Presentation
      Directory('${dir}app/pages').create(recursive: true),
      Directory('${dir}app/widgets').create(recursive: true),
      Directory('${dir}app/utils').create(recursive: true),
      File('${dir}app/navigator.dart').create(recursive: true),

      // Data Layer - External Data Sources
      Directory('${dir}data/repositories').create(recursive: true),
      Directory('${dir}data/helpers').create(recursive: true),
      File('${dir}data/constants.dart').create(recursive: true),

      // Device Layer - Platform-specific Features
      Directory('${dir}device/repositories').create(recursive: true),
      Directory('${dir}device/utils').create(recursive: true),

      // Domain Layer - Business Logic
      Directory('${dir}domain/entities').create(recursive: true),
      Directory('${dir}domain/usecases').create(recursive: true),
      Directory('${dir}domain/repositories').create(recursive: true),
    ]);

    CliLogger.success('Architecture folders created successfully!');
  } catch (e) {
    CliLogger.error('Failed to create architecture folders: $e');
    rethrow;
  }
}

/// Creates a new page with Clean Architecture components.
///
/// This function generates a complete page structure following Clean Architecture
/// principles, creating three essential files for each page:
///
/// ## Generated Files:
/// ```
/// lib/src/app/pages/{page_name}/
/// ├── {page_name}_view.dart      # UI implementation (View + ViewState)
/// ├── {page_name}_controller.dart # Business logic controller
/// └── {page_name}_presenter.dart  # Presentation logic and use case coordination
/// ```
///
/// ## Validation:
/// - Page name must be in snake_case format (e.g., "user_profile", "product_detail")
/// - Page name must start with a lowercase letter
/// - Page name can contain lowercase letters, numbers, and underscores
/// - Page name must end with a letter or number (not underscore)
/// - Page must not already exist in the project
///
/// ## Example Usage:
/// ```bash
/// flutter pub run flutter_clean_architecture:cli create --page user_profile
/// ```
///
/// This creates:
/// - `user_profile_view.dart` with `UserProfileView` and `UserProfileViewState` classes
/// - `user_profile_controller.dart` with `UserProfileController` class
/// - `user_profile_presenter.dart` with `UserProfilePresenter` class
///
/// @param name The page name in snake_case format (e.g., "user_profile")
/// @throws ArgumentError If page name is invalid or page already exists
/// @throws FileSystemException If file creation fails
Future<void> _createPage(String name) async {
  // Validate page name format
  if (!_isValidPageName(name)) {
    CliLogger.error(
        'Invalid page name "$name". Use snake_case format (e.g., "user_profile")');
    exit(1);
  }

  // Check if page already exists
  if (await _pageExists(name)) {
    CliLogger.error('Page "$name" already exists.');
    exit(1);
  }

  CliLogger.info('Creating page: $name');
  final dir = '${Directory.current.path}/lib/src/app/pages/$name/$name';

  try {
    // Create all page files concurrently
    await Future.wait([
      _createFile('${dir}_presenter.dart', _presenterContent(name)),
      _createFile('${dir}_controller.dart', _controllerContent(name)),
      _createFile('${dir}_view.dart', _viewContent(name)),
    ]);

    CliLogger.success('Page "$name" created successfully!');
  } catch (e) {
    CliLogger.error('Error creating page: $e');
    rethrow;
  }
}

/// Generates the View template content for a Clean Architecture page.
///
/// This function creates the Dart code for the View component, which includes:
/// - A `CleanView` class that serves as the root widget
/// - A `CleanViewState` class that contains the actual UI implementation
/// - Proper imports and dependencies
/// - A placeholder widget as the initial UI
///
/// @param name The page name in snake_case format
/// @return The complete Dart code for the View component
String _viewContent(String name) {
  var pascalCaseName = _convertToPascalCase(name);

  return '''
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '${name}_controller.dart';

class ${pascalCaseName}View extends CleanView {
  const ${pascalCaseName}View({super.key});

  @override
  State<StatefulWidget> createState() {
    return _${pascalCaseName}ViewState(
      ${pascalCaseName}Controller(),
    );
  }
}

class _${pascalCaseName}ViewState extends CleanViewState<${pascalCaseName}View, ${pascalCaseName}Controller> {
  _${pascalCaseName}ViewState(${pascalCaseName}Controller controller) : super(controller);

  @override
  Widget get view {
    return const Placeholder();
  }
}
  ''';
}

/// Generates the Controller template content for a Clean Architecture page.
///
/// This function creates the Dart code for the Controller component, which includes:
/// - A `Controller` class that manages business logic and state
/// - Presenter dependency injection
/// - Required `initListeners()` method implementation
/// - Proper imports and dependencies
///
/// @param name The page name in snake_case format
/// @return The complete Dart code for the Controller component
String _controllerContent(String name) {
  var pascalCaseName = _convertToPascalCase(name);
  return '''
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '${name}_presenter.dart';

class ${pascalCaseName}Controller extends Controller {
  final ${pascalCaseName}Presenter _presenter;

  ${pascalCaseName}Controller() : _presenter = ${pascalCaseName}Presenter();

  @override
  void initListeners() {
    // TODO: Implement initListeners
  }
}
  ''';
}

/// Generates the Presenter template content for a Clean Architecture page.
///
/// This function creates the Dart code for the Presenter component, which includes:
/// - A `Presenter` class that coordinates use cases and data flow
/// - Required `dispose()` method implementation
/// - Proper imports with namespace alias to avoid conflicts
/// - Clean Architecture pattern compliance
///
/// @param name The page name in snake_case format
/// @return The complete Dart code for the Presenter component
String _presenterContent(String name) {
  var pascalCaseName = _convertToPascalCase(name);
  return '''
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart' as clean;

class ${pascalCaseName}Presenter extends clean.Presenter {
  @override
  void dispose() {
    // TODO: Implement dispose
  }
}
  ''';
}

/// Converts a snake_case string to PascalCase format.
///
/// This utility function transforms naming conventions from snake_case (used for
/// file names and page names) to PascalCase (used for class names in Dart).
///
/// ## Conversion Rules:
/// - Splits the input string by underscores
/// - Capitalizes the first letter of each word
/// - Concatenates all words without separators
///
/// ## Examples:
/// - `user_profile` → `UserProfile`
/// - `product_detail` → `ProductDetail`
/// - `login_page` → `LoginPage`
/// - `home` → `Home`
///
/// ## Use Cases:
/// - Converting page names to class names
/// - Generating proper Dart class naming conventions
/// - Maintaining consistency between file names and class names
///
/// @param text The snake_case string to convert
/// @return The PascalCase string
String _convertToPascalCase(String text) {
  var finalText = '';
  var words = text.split('_');

  for (var word in words) {
    finalText += word[0].toUpperCase() + word.substring(1, word.length);
  }

  return finalText;
}

/// Prints the default help content for the CLI tool.
///
/// This function displays comprehensive help information about the Flutter Clean
/// Architecture CLI tool, including usage instructions, available commands,
/// and examples.
///
/// @param parser The argument parser instance for generating usage information
void _printDefaultHelpContent(ArgParser parser) {
  print('''
🚀 Flutter Clean Architecture CLI

A command-line tool for generating Clean Architecture components in Flutter projects.

USAGE:
  ${parser.usage}

COMMANDS:
  create    Generate architecture components (pages, entities, use cases)

EXAMPLES:
  flutter pub run flutter_clean_architecture:cli create --page user_profile
  flutter pub run flutter_clean_architecture:cli create

For more information about a specific command, run:
  flutter pub run flutter_clean_architecture:cli <command> --help
''');
}

/// Prints the help content specifically for the 'create' command.
///
/// This function displays detailed help information about the create command,
/// including its specific options, usage patterns, and examples.
///
/// @param parser The argument parser instance for the create command
void _printCreateCommandHelpContent(ArgParser parser) {
  print('''
🚀 Flutter Clean Architecture CLI - Create Command

Creates architecture related folders and files.

USAGE:
  ${parser.usage}

OPTIONS:
  -p, --page <name>    Creates a page with the given name (snake_case format)

EXAMPLES:
  flutter pub run flutter_clean_architecture:cli create --page user_profile
  flutter pub run flutter_clean_architecture:cli create --page product_detail
  flutter pub run flutter_clean_architecture:cli create
''');
}

/// Creates a file with the specified content at the given path.
///
/// @param path The file path where the file should be created
/// @param content The content to write to the file
/// @throws FileSystemException If file creation or writing fails
Future<void> _createFile(String path, String content) async {
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsString(content);
  final fileName = path.split('/').last;
  CliLogger.info('Created $fileName');
}

/// Validates if a page name follows the required snake_case format.
///
/// This function ensures that page names conform to Dart naming conventions
/// and Clean Architecture best practices. It uses a regular expression to
/// validate the format.
///
/// ## Validation Rules:
/// - Must start with a lowercase letter
/// - Can contain lowercase letters, numbers, and underscores
/// - Must end with a letter or number (not underscore)
/// - Must not be empty
///
/// ## Valid Examples:
/// - `user_profile` ✅
/// - `product_detail` ✅
/// - `login` ✅
/// - `home_page` ✅
/// - `user123` ✅
///
/// ## Invalid Examples:
/// - `UserProfile` ❌ (contains uppercase)
/// - `user-profile` ❌ (contains hyphen)
/// - `user_profile_` ❌ (ends with underscore)
/// - `_user_profile` ❌ (starts with underscore)
/// - `123user` ❌ (starts with number)
/// - `user profile` ❌ (contains space)
///
/// @param name The page name to validate
/// @return `true` if the name is valid, `false` otherwise
bool _isValidPageName(String name) {
  return RegExp(r'^[a-z][a-z0-9_]*[a-z0-9]$').hasMatch(name);
}

/// Checks if a page with the given name already exists in the project.
///
/// This function verifies whether a page directory already exists in the
/// standard Clean Architecture folder structure to prevent overwriting
/// existing pages.
///
/// @param name The page name to check for existence
/// @return `true` if the page directory exists, `false` otherwise
Future<bool> _pageExists(String name) {
  final dir = Directory('${Directory.current.path}/lib/src/app/pages/$name');
  return dir.exists();
}

/// A utility class for logging messages to the console with appropriate formatting.
///
/// The `CliLogger` class provides a simple and consistent way to display
/// different types of messages to users during CLI operations. It uses
/// emoji icons to make the output more visually appealing and easier to
/// distinguish between different message types.
///
class CliLogger {
  /// Logs an informational message to the console.
  ///
  /// This method is used for general information, progress updates,
  /// and status messages that inform the user about ongoing operations.
  ///
  /// @param message The informational message to display
  static void info(String message) {
    print('ℹ️  $message');
  }

  /// Logs a success message to the console.
  ///
  /// This method is used to indicate successful completion of operations,
  /// such as successful file creation, folder generation, or other
  /// completed tasks.
  ///
  /// @param message The success message to display
  static void success(String message) {
    print('✅ $message');
  }

  /// Logs an error message to the console.
  ///
  /// This method is used to display error messages, failures, and
  /// issues that prevent operations from completing successfully.
  ///
  /// @param message The error message to display
  static void error(String message) {
    print('❌ $message');
  }

  /// Logs a warning message to the console.
  ///
  /// This method is used to display warning messages about potential
  /// issues, deprecated features, or situations that require user
  /// attention but don't prevent the operation from continuing.
  ///
  /// @param message The warning message to display
  static void warning(String message) {
    print('⚠️  $message');
  }
}
