#!/bin/bash

# Rebuild and reinstall FCA MCP server
# This script clears the cached snapshots, reactivates the package,
# and creates wrapper scripts that bypass the noisy pub global run

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"
PUB_BIN="$HOME/.pub-cache/bin"

echo "🔄 Rebuilding FCA..."

# Deactivate if currently active
echo "📦 Deactivating current installation..."
dart pub global deactivate flutter_clean_architecture 2>/dev/null || true

# Clear the global package cache for this package
CACHE_DIR="$HOME/.pub-cache/global_packages/flutter_clean_architecture"
if [ -d "$CACHE_DIR" ]; then
    echo "🗑️  Clearing global package cache..."
    rm -rf "$CACHE_DIR"
fi

# Clear the .dart_tool snapshots (this is where JIT snapshots are cached)
SNAPSHOT_DIR="$PACKAGE_DIR/.dart_tool/pub/bin/flutter_clean_architecture"
if [ -d "$SNAPSHOT_DIR" ]; then
    echo "🗑️  Clearing JIT snapshots..."
    rm -rf "$SNAPSHOT_DIR"
fi

# Also clear any other cached bin snapshots
DART_TOOL_BIN="$PACKAGE_DIR/.dart_tool/pub/bin"
if [ -d "$DART_TOOL_BIN" ]; then
    echo "🗑️  Clearing all bin snapshots..."
    rm -rf "$DART_TOOL_BIN"
fi

# Clear build cache
BUILD_CACHE="$PACKAGE_DIR/.dart_tool/build_cache"
if [ -d "$BUILD_CACHE" ]; then
    echo "🗑️  Clearing build cache..."
    rm -rf "$BUILD_CACHE"
fi

# Clear any .dill and .snap files in .dart_tool
find "$PACKAGE_DIR/.dart_tool" -type f \( -name "*.dill" -o -name "*.snap" \) -delete 2>/dev/null || true

# Get dependencies
echo "📥 Getting dependencies..."
cd "$PACKAGE_DIR"
dart pub get

# Compile MCP server to executable
echo "🔨 Compiling fca_mcp_server to executable..."
mkdir -p "$PACKAGE_DIR/build"
dart compile exe bin/fca_mcp_server.dart -o "$PACKAGE_DIR/build/fca_mcp_server"

# Create the pub bin directory if it doesn't exist
mkdir -p "$PUB_BIN"

# Activate the package globally so it persists across IDE restarts
echo "🌍 Activating package globally..."
cd "$PACKAGE_DIR"
dart pub global activate --source=path .

# Now create our custom wrappers (after activation to override pub's wrappers)
echo "📝 Creating custom wrapper scripts..."

# Create fca wrapper (uses dart run for flexibility)
cat > "$PUB_BIN/fca" << 'WRAPPER_EOF'
#!/usr/bin/env bash
# FCA CLI wrapper - runs dart directly to avoid pub noise
exec dart run "PACKAGE_DIR_PLACEHOLDER/bin/fca.dart" "$@"
WRAPPER_EOF

# Replace placeholder with actual path
sed -i.bak "s|PACKAGE_DIR_PLACEHOLDER|$PACKAGE_DIR|g" "$PUB_BIN/fca"
rm -f "$PUB_BIN/fca.bak"
chmod +x "$PUB_BIN/fca"

# Create fca_mcp_server wrapper (uses dart run for better compatibility)
cat > "$PUB_BIN/fca_mcp_server" << 'WRAPPER_EOF'
#!/usr/bin/env bash
# FCA MCP Server wrapper - uses dart run for compatibility
exec dart run "PACKAGE_DIR_PLACEHOLDER/bin/fca_mcp_server.dart" "$@"
WRAPPER_EOF

# Replace placeholder with actual path
sed -i.bak "s|PACKAGE_DIR_PLACEHOLDER|$PACKAGE_DIR|g" "$PUB_BIN/fca_mcp_server"
rm -f "$PUB_BIN/fca_mcp_server.bak"
chmod +x "$PUB_BIN/fca_mcp_server"

echo ""
echo "✅ Rebuild complete!"
echo ""
echo "Installed executables:"
echo "  • fca"
echo "  • fca_mcp_server"
echo ""
echo "To verify:"
echo "  fca --version"
echo "  fca generate --help"
echo "  fca schema"
