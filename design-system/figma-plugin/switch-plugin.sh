#!/bin/bash

# Switch between different Figma plugin manifests
# Usage: ./switch-plugin.sh [plugin-name]

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Zero Design System - Plugin Switcher"
echo "====================================="
echo ""

show_menu() {
    echo "Available plugins:"
    echo "  1) effects          - Component Generator with Visual Effects (uses tokens.json)"
    echo "  2) components       - Basic Component Generator (with UI)"
    echo "  3) modals-core      - Action Modals - Core (11 priority modals)"
    echo "  4) modals-secondary - Action Modals - Secondary"
    echo "  5) modal-components - Shared Modal Components"
    echo "  6) variants         - Component Variants Generator"
    echo "  7) sync             - Design Token Sync Plugin"
    echo ""
    echo "Current plugin:"
    grep '"name"' "$PLUGIN_DIR/manifest.json" | head -1 | sed 's/.*"name": "\(.*\)".*/  -> \1/'
    echo ""
}

switch_to() {
    local source="$1"
    local name="$2"
    
    if [ -f "$PLUGIN_DIR/$source" ]; then
        cp "$PLUGIN_DIR/$source" "$PLUGIN_DIR/manifest.json"
        echo "Switched to: $name"
        echo ""
        echo "Now in Figma:"
        echo "  1. Menu > Plugins > Development > Import plugin from manifest"
        echo "  2. Select: $PLUGIN_DIR"
        echo "  3. Run: Plugins > Development > $name"
    else
        echo "Error: $source not found"
        exit 1
    fi
}

case "${1:-}" in
    effects|1)
        switch_to "manifest-effects.json" "Zero Component Generator (With Visual Effects)"
        ;;
    components|2)
        switch_to "manifest-component-generator.json" "Zero Component Generator"
        ;;
    modals-core|3)
        switch_to "manifest-action-modals-core.json" "Zero Action Modals - Core"
        ;;
    modals-secondary|4)
        switch_to "manifest-action-modals-secondary.json" "Zero Action Modals - Secondary"
        ;;
    modal-components|5)
        switch_to "manifest-modal-components.json" "Zero Modal Components"
        ;;
    variants|6)
        switch_to "manifest-variants.json" "Zero Component Variants"
        ;;
    sync|7)
        switch_to "manifest-sync.json" "Zero Design Token Sync"
        ;;
    *)
        show_menu
        echo "Usage: ./switch-plugin.sh [plugin-name|number]"
        echo ""
        echo "Examples:"
        echo "  ./switch-plugin.sh effects"
        echo "  ./switch-plugin.sh 1"
        ;;
esac








