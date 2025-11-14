#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import fetch from 'node-fetch';

// Figma API configuration
const FIGMA_API_TOKEN = process.env.FIGMA_ACCESS_TOKEN;
const FIGMA_API_BASE = 'https://api.figma.com/v1';

if (!FIGMA_API_TOKEN) {
  console.error('Error: FIGMA_ACCESS_TOKEN environment variable is required');
  process.exit(1);
}

// Helper function to make Figma API requests
async function figmaApiRequest(endpoint) {
  const response = await fetch(`${FIGMA_API_BASE}${endpoint}`, {
    headers: {
      'X-Figma-Token': FIGMA_API_TOKEN,
    },
  });

  if (!response.ok) {
    throw new Error(`Figma API error: ${response.status} ${response.statusText}`);
  }

  return response.json();
}

// Create MCP server
const server = new Server(
  {
    name: 'figma-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'get_figma_file',
        description: 'Get information about a Figma file including all pages and top-level nodes',
        inputSchema: {
          type: 'object',
          properties: {
            file_key: {
              type: 'string',
              description: 'The Figma file key (from the URL)',
            },
          },
          required: ['file_key'],
        },
      },
      {
        name: 'get_figma_node',
        description: 'Get detailed information about a specific node in a Figma file',
        inputSchema: {
          type: 'object',
          properties: {
            file_key: {
              type: 'string',
              description: 'The Figma file key',
            },
            node_id: {
              type: 'string',
              description: 'The node ID to inspect',
            },
          },
          required: ['file_key', 'node_id'],
        },
      },
      {
        name: 'list_figma_pages',
        description: 'List all pages in a Figma file with their IDs and children count',
        inputSchema: {
          type: 'object',
          properties: {
            file_key: {
              type: 'string',
              description: 'The Figma file key',
            },
          },
          required: ['file_key'],
        },
      },
      {
        name: 'get_page_children',
        description: 'Get all children nodes of a specific page',
        inputSchema: {
          type: 'object',
          properties: {
            file_key: {
              type: 'string',
              description: 'The Figma file key',
            },
            page_id: {
              type: 'string',
              description: 'The page node ID',
            },
          },
          required: ['file_key', 'page_id'],
        },
      },
      {
        name: 'get_node_image',
        description: 'Get a rendered image URL for a specific node',
        inputSchema: {
          type: 'object',
          properties: {
            file_key: {
              type: 'string',
              description: 'The Figma file key',
            },
            node_id: {
              type: 'string',
              description: 'The node ID to render',
            },
            scale: {
              type: 'number',
              description: 'Image scale (1-4, default 2)',
              default: 2,
            },
          },
          required: ['file_key', 'node_id'],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'get_figma_file': {
        const data = await figmaApiRequest(`/files/${args.file_key}`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(data, null, 2),
            },
          ],
        };
      }

      case 'get_figma_node': {
        const data = await figmaApiRequest(`/files/${args.file_key}/nodes?ids=${args.node_id}`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(data, null, 2),
            },
          ],
        };
      }

      case 'list_figma_pages': {
        const data = await figmaApiRequest(`/files/${args.file_key}`);
        const pages = data.document.children.map(page => ({
          id: page.id,
          name: page.name,
          type: page.type,
          childrenCount: page.children?.length || 0,
        }));
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(pages, null, 2),
            },
          ],
        };
      }

      case 'get_page_children': {
        const data = await figmaApiRequest(`/files/${args.file_key}/nodes?ids=${args.page_id}`);
        const node = data.nodes[args.page_id];
        if (!node || !node.document) {
          throw new Error('Page not found or no children');
        }
        const children = node.document.children || [];
        const childrenSummary = children.map(child => ({
          id: child.id,
          name: child.name,
          type: child.type,
          visible: child.visible !== false,
          childrenCount: child.children?.length || 0,
        }));
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(childrenSummary, null, 2),
            },
          ],
        };
      }

      case 'get_node_image': {
        const scale = args.scale || 2;
        const data = await figmaApiRequest(
          `/images/${args.file_key}?ids=${args.node_id}&scale=${scale}&format=png`
        );
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(data, null, 2),
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Figma MCP server running on stdio');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});
