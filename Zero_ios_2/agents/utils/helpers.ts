import * as crypto from 'crypto';

export function generateId(): string {
  return crypto.randomUUID();
}

export function generateShortId(): string {
  return crypto.randomBytes(6).toString('hex');
}

export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str;
  return str.slice(0, maxLength - 3) + '...';
}

export function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

export function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(2)}s`;
  return `${(ms / 60000).toFixed(2)}m`;
}

export function extractFileExtension(filename: string): string {
  const lastDot = filename.lastIndexOf('.');
  if (lastDot === -1) return '';
  return filename.slice(lastDot + 1).toLowerCase();
}

export function isCodeFile(filename: string): boolean {
  const codeExtensions = [
    'ts', 'tsx', 'js', 'jsx', 'mjs', 'cjs',
    'py', 'rb', 'go', 'rs', 'java', 'kt',
    'swift', 'c', 'cpp', 'h', 'hpp',
    'cs', 'php', 'vue', 'svelte'
  ];
  const ext = extractFileExtension(filename);
  return codeExtensions.includes(ext);
}

export function isConfigFile(filename: string): boolean {
  const configPatterns = [
    'package.json', 'tsconfig.json', 'next.config',
    '.env', 'dockerfile', 'docker-compose',
    'webpack.config', 'vite.config', 'tailwind.config',
    '.eslintrc', '.prettierrc', 'jest.config'
  ];
  const lower = filename.toLowerCase();
  return configPatterns.some(p => lower.includes(p));
}

export function groupBy<T>(array: T[], keyFn: (item: T) => string): Record<string, T[]> {
  return array.reduce((acc, item) => {
    const key = keyFn(item);
    if (!acc[key]) acc[key] = [];
    acc[key].push(item);
    return acc;
  }, {} as Record<string, T[]>);
}
