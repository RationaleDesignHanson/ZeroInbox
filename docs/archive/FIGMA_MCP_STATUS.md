# Figma MCP Bridge - Current Status

**Date:** November 9, 2025
**Session:** Design System Generation for Zero Inbox

## 🎯 Project Goal

Building a Figma plugin/MCP bridge to:
1. Inspect Figma design files for Zero Inbox
2. Generate design system code from Figma components
3. Ensure proper design-to-code workflow

## ✅ Completed Steps

### 1. Figma MCP Server Built
- **Location:** `/Users/matthanson/Zer0_Inbox/figma-mcp-server/`
- **Status:** Fully implemented and tested
- **Dependencies:** Installed (`npm install` completed)

### 2. MCP Configuration Added
- **Config File:** `~/.config/claude-code/mcp_config.json`
- **Server Name:** `figma`
- **Figma Token:** Configured (token: `figd_8H4gCA...`)

### 3. Available Tools (Once Connected)
The MCP server provides 5 tools:
1. `get_figma_file` - Get full file info including pages and nodes
2. `get_figma_node` - Get detailed node information
3. `list_figma_pages` - List all pages in a file
4. `get_page_children` - Get all children nodes of a page
5. `get_node_image` - Get rendered image URLs for nodes

## 🔄 Current Status

**WAITING FOR:** Claude Code restart to load MCP server

The MCP server configuration is complete, but Claude Code needs a full restart (not just terminal) to:
- Load the MCP server configuration
- Make the Figma tools available as `mcp__figma__*` tools
- Enable direct Figma file inspection

## 📋 Next Steps (After Restart)

1. **Verify MCP Connection**
   - Check if `mcp__figma__*` tools are available
   - Test connection with a simple Figma file query

2. **Inspect Zero Inbox Design System**
   - Get Figma file key from Zero Inbox design file
   - List all pages and components
   - Identify design system components (colors, typography, spacing, components)

3. **Generate Design System Code**
   - Extract design tokens (colors, fonts, spacing)
   - Generate component code based on Figma components
   - Create design system documentation

4. **Integration**
   - Integrate generated code into Zero Inbox project
   - Test components in web-prototype or web-suite
   - Validate design consistency

## 📂 Project Structure

```
/Users/matthanson/Zer0_Inbox/
├── figma-mcp-server/          # MCP bridge server
│   ├── index.js               # Server implementation
│   ├── package.json           # Dependencies
│   └── README.md              # Setup docs
├── design-system/             # Design system output location
├── web-prototype/             # Web frontend
├── web-suite/                 # Web app suite
└── Zero_ios_2/                # iOS app
```

## 🔑 Important Files

- **MCP Server:** `/Users/matthanson/Zer0_Inbox/figma-mcp-server/index.js`
- **MCP Config:** `~/.config/claude-code/mcp_config.json`
- **This Status:** `/Users/matthanson/Zer0_Inbox/FIGMA_MCP_STATUS.md`

## 💡 Quick Start Command (After Restart)

Once Claude Code restarts, ask:
```
"Can you verify the Figma MCP tools are available? Let's inspect the Zero Inbox design file."
```

## 🔧 Troubleshooting

If tools aren't available after restart:
1. Check MCP config: `cat ~/.config/claude-code/mcp_config.json`
2. Test server manually: `cd /Users/matthanson/Zer0_Inbox/figma-mcp-server && node index.js`
3. Check Claude Code logs for MCP connection errors

---

**Ready to continue:** Just restart Claude Code and we'll start inspecting your Figma files!
