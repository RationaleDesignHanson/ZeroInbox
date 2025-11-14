# Figma MCP Server

MCP server for inspecting Figma files through the Figma REST API.

## Setup

1. **Get your Figma Access Token:**
   - Go to https://www.figma.com/developers/api#access-tokens
   - Click "Get personal access token"
   - Copy the token

2. **Install dependencies:**
   ```bash
   cd /Users/matthanson/Zer0_Inbox/figma-mcp-server
   npm install
   ```

3. **Configure Claude Code:**

   Add this to your Claude Code MCP settings at `~/.config/claude-code/mcp_config.json`:

   ```json
   {
     "mcpServers": {
       "figma": {
         "command": "node",
         "args": ["/Users/matthanson/Zer0_Inbox/figma-mcp-server/index.js"],
         "env": {
           "FIGMA_ACCESS_TOKEN": "YOUR_FIGMA_TOKEN_HERE"
         }
       }
     }
   }
   ```

4. **Restart Claude Code** to load the MCP server

## Available Tools

- `get_figma_file` - Get full file information including all pages and nodes
- `get_figma_node` - Get detailed information about a specific node
- `list_figma_pages` - List all pages in a file
- `get_page_children` - Get all children nodes of a page
- `get_node_image` - Get a rendered image URL for a node

## Usage

Once configured, Claude can use these tools to inspect your Figma files:

```
# Get your file key from the Figma URL
# https://www.figma.com/design/FILE_KEY/...
#                              ^^^^^^^^

# Claude can now query your Figma file directly!
```
