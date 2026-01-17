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
# Run from project
dart run flutter_clean_architecture:fca_mcp_server

# Or globally
fca_mcp_server
```

## Configuration

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

```json
{
  "mcpServers": {
    "flutter-clean-architecture": {
      "command": "dart",
      "args": ["run", "flutter_clean_architecture:fca_mcp_server"],
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
      "command": "dart",
      "args": ["run", "flutter_clean_architecture:fca_mcp_server"],
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

## Testing

Test the server directly:

```bash
# Test initialize
echo '{"jsonrpc":"2.0","method":"initialize","id":1}' | dart run flutter_clean_architecture:fca_mcp_server

# List tools
echo '{"jsonrpc":"2.0","method":"tools/list","id":2}' | dart run flutter_clean_architecture:fca_mcp_server

# Get schema
echo '{"jsonrpc":"2.0","method":"tools/call","id":3,"params":{"name":"fca_schema","arguments":{}}}' | dart run flutter_clean_architecture:fca_mcp_server
```

## Troubleshooting

- Ensure Dart is in your PATH
- Check the working directory in your MCP configuration
- Make sure the entity file exists at the expected path before generating

## Related Documentation

- [CLI Guide](./CLI_GUIDE.md) - Comprehensive CLI documentation
- [AGENTS.md](./AGENTS.md) - AI Agent integration guide
- [README](./README.md) - Package overview and API reference
