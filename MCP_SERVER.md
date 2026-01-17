# FCA MCP Server

The `fca_mcp_server` is a Model Context Protocol (MCP) server that exposes the Flutter Clean Architecture CLI functionality as MCP tools, enabling seamless integration with AI-powered development environments like Claude Desktop, Cursor, and VS Code.

## Installation

The MCP server is included with the `flutter_clean_architecture` package:

```bash
# Add the package
flutter pub add flutter_clean_architecture

# Activate globally (optional)
dart pub global activate flutter_clean_architecture
```

The MCP server executable is available at:

```bash
# Run from project (compiles every time - may timeout)
dart run flutter_clean_architecture:fca_mcp_server

# Or globally (also compiles every time)
fca_mcp_server

# RECOMMENDED: Precompile once for faster startup
dart compile exe bin/fca_mcp_server.dart -o fca_mcp_server
```

**Important**: Use the precompiled `fca_mcp_server` binary in your MCP client configuration to avoid timeouts during connection. The `dart run` command compiles the package on every invocation, which can cause MCP clients to timeout.

## Configuration

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

```json
{
  "mcpServers": {
    "flutter-clean-architecture": {
      "command": "fca_mcp_server",
      "args": [],
      "cwd": "/path/to/your/flutter/project"
    }
  }
}
```

### Cursor / VS Code

Add to your workspace settings (`.vscode/settings.json`) or MCP configuration:

```json
{
  "mcp.servers": {
    "fca": {
      "command": "fca_mcp_server",
      "args": [],
      "cwd": "${workspaceFolder}"
    }
  }
}
```

## Available Tools

### fca_generate

Generate Clean Architecture code for your Flutter project.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | Entity or UseCase name in PascalCase |
| methods | array | No | Methods: get, getList, create, update, delete, watch, watchList |
| repository | boolean | No | Generate repository interface |
| vpc | boolean | No | Generate View, Presenter, Controller |
| data | boolean | No | Generate data layer (DataRepository + DataSource) |
| datasource | boolean | No | Generate DataSource only |
| id_type | string | No | ID type (default: String) |
| repos | array | No | Repository names to inject |
| params | string | No | Params type (default: NoParams) |
| returns | string | No | Return type (default: void) |
| type | string | No | UseCase type: usecase, stream, background, completable |
| output | string | No | Output directory (default: lib/src) |
| dry_run | boolean | No | Preview without writing files |
| force | boolean | No | Overwrite existing files |

**Example:**
```json
{
  "name": "fca_generate",
  "arguments": {
    "name": "Product",
    "methods": ["get", "getList", "create"],
    "repository": true,
    "vpc": true
  }
}
```

### fca_schema

Get the JSON schema for FCA configuration validation.

**Parameters:** None

### fca_validate

Validate a JSON configuration file.

**Parameters:**
- config (object, required): The configuration to validate

## Resources

The MCP server also provides access to generated project resources:

### resources/list

List all available files in the project's Clean Architecture directories. The server scans the following directories recursively for `.dart` files:

- `lib/src/domain/repositories` - Repository interfaces
- `lib/src/domain/usecases` - UseCase implementations
- `lib/src/data/data_sources` - Data source implementations
- `lib/src/data/repositories` - Data repository implementations
- `lib/src/presentation` - Views, Presenters, Controllers
- `lib/src/domain/entities` - Entity definitions

**Example response:**
```json
{
  "resources": [
    {
      "uri": "file://lib/src/domain/repositories/product_repository.dart",
      "name": "product_repository",
      "description": "product_repository.dart",
      "mimeType": "text/dart"
    },
    {
      "uri": "file://lib/src/domain/usecases/product/get_product_usecase.dart",
      "name": "product.get_product_usecase",
      "description": "product/get_product_usecase.dart",
      "mimeType": "text/dart"
    }
  ]
}
```

### resources/read

Read the contents of a specific file using its URI from `resources/list`.

**Parameters:**
- `uri` (string, required): File URI to read (from the `resources/list` response)

**Example:**
```json
{
  "jsonrpc": "2.0",
  "method": "resources/read",
  "id": 10,
  "params": {
    "uri": "file://lib/src/domain/repositories/product_repository.dart"
  }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "contents": [
      {
        "uri": "file://lib/src/domain/repositories/product_repository.dart",
        "mimeType": "text/dart",
        "text": "abstract class ProductRepository {\n  Future<Product> get(String id);\n  Future<List<Product>> getList();\n  Future<Product> create(Product product);\n  Future<Product> update(Product product);\n  Future<void> delete(String id);\n}"
      }
    ]
  },
  "id": 10
}
```

## Notifications

When the `fca_generate` tool creates new files, the MCP server automatically sends resource change notifications to the agent. This ensures the agent is aware of newly generated files without needing to explicitly query them.

**Example notification sent after generating code:**

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/resources/list_changed",
  "params": {
    "changes": [
      {
        "type": "created",
        "uri": "file://lib/src/domain/repositories/product_repository.dart"
      },
      {
        "type": "created",
        "uri": "file://lib/src/domain/usecases/product/get_product_usecase.dart"
      }
    ]
  }
}
```

This enables the agent to:
- Automatically become aware of new files as they are created
- Update its context with generated code without manual intervention
- Call `resources/list` to see all available files in the project
- Call `resources/read` to read the contents of specific files
- Continue working with the generated files seamlessly

## Testing

Test the server directly:

```bash
# Test initialize (using precompiled binary)
echo '{"jsonrpc":"2.0","method":"initialize","id":1}' | fca_mcp_server

# List tools
echo '{"jsonrpc":"2.0","method":"tools/list","id":2}' | fca_mcp_server

# Get schema
echo '{"jsonrpc":"2.0","method":"tools/call","id":3,"params":{"name":"fca_schema","arguments":{}}}' | fca_mcp_server
```

## Troubleshooting

### Timeout Issues

**Problem**: MCP client times out during connection or requests.

**Cause**: Using `dart run` compiles the package on every invocation, taking 10-30 seconds.

**Solution**: Use a precompiled executable:

```bash
# From flutter_clean_architecture directory
dart compile exe bin/fca_mcp_server.dart -o fca_mcp_server

# Then update your MCP configuration to use the precompiled binary:
"command": "fca_mcp_server"
```

**Alternative**: If you must use `dart run`, increase your MCP client timeout setting to at least 90 seconds.

### General Issues

- Ensure Dart is in your PATH (if using `dart run`)
- Check the working directory in your MCP configuration
- Make sure the entity file exists at the expected path before generating
- Recompile the executable if you've made code changes to `fca_mcp_server.dart`

## Related Documentation

- [CLI Guide](./CLI_GUIDE.md) - Comprehensive CLI documentation
- [AGENTS.md](./AGENTS.md) - AI Agent integration guide
- [README](./README.md) - Package overview and API reference
