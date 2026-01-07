/**
 * Pre-configured project contexts for Rationale Studio repos
 */

import { ProjectContext, ServiceDefinition } from '../types/agent.types';

// ============================================================================
// ZeroInbox Configuration
// ============================================================================

const zeroInboxServices: ServiceDefinition[] = [
  {
    name: 'gateway',
    port: 3001,
    type: 'gateway',
    endpoints: ['/api/auth/gmail/callback', '/api/auth/refresh', '/health'],
    health: '/health'
  },
  {
    name: 'email',
    port: 8081,
    type: 'api',
    endpoints: ['/api/emails', '/api/emails/:id', '/api/emails/send', '/api/emails/archive', '/api/corpus/store'],
    dependencies: ['gateway'],
    health: '/health'
  },
  {
    name: 'classifier',
    port: 8082,
    type: 'ml',
    endpoints: ['/api/classify'],
    dependencies: ['gateway', 'email'],
    health: '/health'
  },
  {
    name: 'summarization',
    port: 8083,
    type: 'ml',
    endpoints: ['/api/summarize', '/api/summarize/thread'],
    dependencies: ['gateway', 'email'],
    health: '/health'
  },
  {
    name: 'shopping-agent',
    port: 8084,
    type: 'agent',
    endpoints: ['/api/shopping/search', '/api/shopping/track'],
    dependencies: ['gateway'],
    health: '/health'
  },
  {
    name: 'scheduled-purchase',
    port: 8085,
    type: 'agent',
    endpoints: ['/api/scheduled-purchase/create', '/api/scheduled-purchase/list'],
    dependencies: ['gateway'],
    health: '/health'
  },
  {
    name: 'smart-replies',
    port: 8086,
    type: 'ml',
    endpoints: ['/api/smart-replies/generate'],
    dependencies: ['gateway', 'email'],
    health: '/health'
  },
  {
    name: 'steel-agent',
    port: 8087,
    type: 'agent',
    endpoints: ['/api/subscription/info', '/api/subscription/cancel'],
    dependencies: ['gateway'],
    health: '/health'
  }
];

export const ZERO_INBOX_PROJECT: ProjectContext = {
  name: 'ZeroInbox',
  rootPath: '/Users/matthanson/Zer0_Inbox',
  repoUrl: 'https://github.com/RationaleDesignHanson/ZeroInbox',
  techStack: {
    languages: ['TypeScript', 'JavaScript', 'Swift'],
    frameworks: ['Node.js', 'Express', 'SwiftUI'],
    databases: ['PostgreSQL', 'Redis'],
    infrastructure: ['Google Cloud Run', 'Docker'],
    tools: ['Gmail API', 'Gemini API']
  },
  structure: {
    type: 'hybrid-ios-web',
    appRouter: false,
    iosApp: {
      path: 'ios-app/Zero',
      pattern: 'mvvm',
      swiftVersion: '6.0'
    },
    directories: [
      { path: 'ios-app/', purpose: 'iOS client (Swift, MVVM)', patterns: ['SwiftUI', 'Combine'] },
      { path: 'backend/gateway/', purpose: 'API Gateway - Auth, routing', patterns: ['Express', 'JWT'] },
      { path: 'backend/services/', purpose: '8 microservices', patterns: ['REST'] },
      { path: 'backend/shared/', purpose: 'Shared libs (auth, logging, db)', patterns: ['Middleware'] },
      { path: 'backend/database/', purpose: 'PostgreSQL schemas & migrations' },
      { path: 'web-prototype/', purpose: 'Original swipe demo (vanilla JS)' },
      { path: 'admin-tools/', purpose: 'Admin dashboards (HTML)' },
      { path: 'docs/', purpose: 'Architecture & API documentation' }
    ]
  },
  services: zeroInboxServices,
  conventions: {
    naming: {
      files: 'kebab-case',
      components: 'PascalCase',
      functions: 'camelCase',
      constants: 'SCREAMING_SNAKE_CASE'
    },
    architecture: {
      stateManagement: 'SwiftUI @State/@Published',
      dataFetching: 'async/await',
      styling: 'SwiftUI native',
      routing: 'NavigationStack'
    },
    testing: {
      framework: 'XCTest',
      location: 'separate',
      naming: '*Tests.swift'
    }
  }
};

// ============================================================================
// RationaleSite Configuration
// ============================================================================

export const RATIONALE_SITE_PROJECT: ProjectContext = {
  name: 'RationaleSite_V01',
  rootPath: '/Users/matthanson/RationaleSite_V01',
  repoUrl: 'https://github.com/RationaleDesignHanson/RationaleSite_V01',
  techStack: {
    languages: ['TypeScript'],
    frameworks: ['Next.js 16', 'React 19'],
    databases: [],
    infrastructure: ['Vercel'],
    tools: ['Playwright'],
    ui: {
      styling: 'tailwind',
      animation: 'framer-motion',
      icons: 'lucide-react',
      charts: 'mermaid'
    },
    threejs: {
      enabled: true,
      libraries: ['@react-three/fiber', '@react-three/drei', 'three']
    }
  },
  structure: {
    type: 'single-app',
    appRouter: true,
    directories: [
      { path: 'app/(public)/', purpose: 'Public marketing pages' },
      { path: 'app/api/', purpose: 'API routes' },
      { path: 'app/auth/', purpose: 'Authentication flows' },
      { path: 'app/client/', purpose: 'Client portal (singular)' },
      { path: 'app/clients/', purpose: 'Client case studies' },
      { path: 'app/internal/', purpose: 'Internal dashboard' },
      { path: 'app/pitch/', purpose: 'Pitch/investor pages' },
      { path: 'components/ui/', purpose: 'Base UI components' },
      { path: 'components/layout/', purpose: 'Layout components' },
      { path: 'components/navigation/', purpose: 'Nav components' },
      { path: 'components/sections/', purpose: 'Page sections' },
      { path: 'components/visual/', purpose: 'Visual/3D components' },
      { path: 'components/cards/', purpose: 'Card components' },
      { path: 'components/features/', purpose: 'Feature showcases' },
      { path: 'components/athletes-first/', purpose: 'Athletes First client components' },
      { path: 'components/creait/', purpose: 'CREaiT platform components' },
      { path: 'components/zero/', purpose: 'Zero/email app components' },
      { path: 'components/invest/', purpose: 'Investor page components' },
      { path: 'components/conversion/', purpose: 'CTA/conversion components' },
      { path: 'components/social-proof/', purpose: 'Testimonials/logos' },
      { path: 'components/loading/', purpose: 'Loading states' },
      { path: 'components/accessibility/', purpose: 'A11y utilities' }
    ]
  },
  conventions: {
    naming: {
      files: 'kebab-case',
      components: 'PascalCase',
      functions: 'camelCase',
      constants: 'SCREAMING_SNAKE_CASE'
    },
    architecture: {
      stateManagement: 'React hooks + context',
      dataFetching: 'Server Components + fetch',
      styling: 'Tailwind CSS',
      routing: 'Next.js App Router'
    },
    testing: {
      framework: 'Playwright',
      location: 'separate',
      naming: '*.spec.ts'
    }
  }
};

// ============================================================================
// Project Registry
// ============================================================================

export const RATIONALE_PROJECTS: Record<string, ProjectContext> = {
  'zeroinbox': ZERO_INBOX_PROJECT,
  'zero-inbox': ZERO_INBOX_PROJECT,
  'zero': ZERO_INBOX_PROJECT,
  'rationale-site': RATIONALE_SITE_PROJECT,
  'rationalesite': RATIONALE_SITE_PROJECT,
  'site': RATIONALE_SITE_PROJECT
};

export function getProjectByName(name: string): ProjectContext | undefined {
  const key = name.toLowerCase().replace(/[_\s]/g, '-');
  return RATIONALE_PROJECTS[key];
}

export function getAllProjects(): ProjectContext[] {
  return [ZERO_INBOX_PROJECT, RATIONALE_SITE_PROJECT];
}
