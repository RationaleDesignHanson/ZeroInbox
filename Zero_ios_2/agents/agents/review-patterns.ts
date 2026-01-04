/**
 * Stack-specific review patterns for Systems Architect Agent
 * Tailored for Rationale Studio's tech stacks
 */

import { ReviewFinding, ReviewSeverity, ProjectContext } from '../types/agent.types';
import { generateId } from '../utils/helpers';

// ============================================================================
// Next.js 16 + App Router Patterns
// ============================================================================

export function reviewNextJsPatterns(context: ProjectContext): ReviewFinding[] {
  const findings: ReviewFinding[] = [];

  // App Router specific checks
  if (context.structure?.appRouter) {
    findings.push({
      id: generateId(),
      severity: 'info',
      category: 'Next.js App Router',
      title: 'Server Components as default',
      description: 'Ensure components are Server Components by default, only adding "use client" when needed for interactivity.',
      recommendation: 'Review components in /components for unnecessary "use client" directives. Keep data fetching in Server Components.',
      effort: 'small',
      impact: 'medium'
    });

    findings.push({
      id: generateId(),
      severity: 'suggestion',
      category: 'Next.js App Router',
      title: 'Route groups for organization',
      description: 'Using (public) route group is good practice. Consider adding (auth) or (dashboard) groups for protected routes.',
      recommendation: 'Group routes by access level: (public), (auth), (admin) for cleaner organization and shared layouts.',
      effort: 'small',
      impact: 'low'
    });

    findings.push({
      id: generateId(),
      severity: 'suggestion',
      category: 'Next.js Performance',
      title: 'Parallel routes for complex layouts',
      description: 'For pages with multiple independent data requirements, consider parallel routes (@slot) for streaming.',
      recommendation: 'Use parallel routes in dashboard/internal sections where multiple data sources load independently.',
      effort: 'medium',
      impact: 'medium'
    });
  }

  // React 19 specific
  if (context.techStack.frameworks.some(f => f.includes('React 19'))) {
    findings.push({
      id: generateId(),
      severity: 'info',
      category: 'React 19',
      title: 'Use new React 19 features',
      description: 'React 19 includes use() hook, Actions, and improved Suspense.',
      recommendation: 'Leverage use() for cleaner async data handling in Client Components. Consider Actions for form submissions.',
      effort: 'medium',
      impact: 'medium'
    });
  }

  return findings;
}

// ============================================================================
// Three.js / React Three Fiber Patterns
// ============================================================================

export function reviewThreeJsPatterns(context: ProjectContext): ReviewFinding[] {
  const findings: ReviewFinding[] = [];

  if (!context.techStack.threejs?.enabled) return findings;

  findings.push({
    id: generateId(),
    severity: 'warning',
    category: 'Three.js Performance',
    title: 'Canvas isolation required',
    description: 'R3F Canvas components must be isolated to prevent re-renders from affecting 3D performance.',
    recommendation: 'Wrap Canvas in React.memo or separate component. Use zustand/jotai for 3D state instead of React context.',
    effort: 'medium',
    impact: 'high'
  });

  findings.push({
    id: generateId(),
    severity: 'suggestion',
    category: 'Three.js',
    title: 'Use Drei abstractions',
    description: '@react-three/drei provides optimized implementations of common 3D patterns.',
    recommendation: 'Use Html, Text, useGLTF, useTexture from drei instead of raw Three.js equivalents.',
    effort: 'small',
    impact: 'medium'
  });

  findings.push({
    id: generateId(),
    severity: 'warning',
    category: 'Three.js Memory',
    title: 'Dispose resources on unmount',
    description: 'Three.js geometries, materials, and textures must be manually disposed to prevent memory leaks.',
    recommendation: 'Use useEffect cleanup or drei\'s useDisposable. Check for dispose() calls in custom hooks.',
    effort: 'medium',
    impact: 'high'
  });

  findings.push({
    id: generateId(),
    severity: 'suggestion',
    category: 'Three.js SSR',
    title: 'Dynamic import for Canvas',
    description: 'Three.js requires browser APIs and must be dynamically imported in Next.js.',
    recommendation: 'Use next/dynamic with ssr: false for all R3F components. Create a single dynamic wrapper.',
    effort: 'trivial',
    impact: 'high'
  });

  return findings;
}

// ============================================================================
// Microservices Patterns (ZeroInbox Backend)
// ============================================================================

export function reviewMicroservicesPatterns(context: ProjectContext): ReviewFinding[] {
  const findings: ReviewFinding[] = [];

  if (!context.services || context.services.length === 0) return findings;

  // Service mesh checks
  findings.push({
    id: generateId(),
    severity: 'suggestion',
    category: 'Microservices',
    title: 'Service discovery pattern',
    description: `${context.services.length} services detected. Consider service discovery for dynamic routing.`,
    recommendation: 'Implement service registry or use container orchestration (K8s) service discovery instead of hardcoded ports.',
    effort: 'large',
    impact: 'medium'
  });

  // Health check patterns
  const servicesWithHealth = context.services.filter(s => s.health);
  if (servicesWithHealth.length < context.services.length) {
    findings.push({
      id: generateId(),
      severity: 'warning',
      category: 'Microservices',
      title: 'Health endpoints missing',
      description: `Only ${servicesWithHealth.length}/${context.services.length} services have health endpoints defined.`,
      recommendation: 'Add /health endpoint to all services for load balancer and orchestrator health checks.',
      effort: 'small',
      impact: 'high'
    });
  }

  // Gateway pattern
  const gateway = context.services.find(s => s.type === 'gateway');
  if (gateway) {
    findings.push({
      id: generateId(),
      severity: 'info',
      category: 'Microservices',
      title: 'API Gateway pattern implemented',
      description: 'Gateway service handles auth and routing. Good foundation for rate limiting and request transformation.',
      recommendation: 'Consider adding request/response logging, rate limiting, and circuit breaker at gateway level.',
      effort: 'medium',
      impact: 'medium'
    });
  }

  // ML service patterns
  const mlServices = context.services.filter(s => s.type === 'ml');
  if (mlServices.length > 0) {
    findings.push({
      id: generateId(),
      severity: 'suggestion',
      category: 'ML Services',
      title: 'ML service scaling considerations',
      description: `${mlServices.length} ML services (${mlServices.map(s => s.name).join(', ')}) may have different scaling needs.`,
      recommendation: 'Consider GPU instances for ML services, separate scaling policies, and request queuing for burst handling.',
      effort: 'large',
      impact: 'high'
    });

    findings.push({
      id: generateId(),
      severity: 'suggestion',
      category: 'ML Services',
      title: 'Model versioning',
      description: 'ML services should support model versioning for A/B testing and rollback.',
      recommendation: 'Implement model registry pattern. Version models separately from code. Support concurrent model versions.',
      effort: 'medium',
      impact: 'medium'
    });
  }

  // Agent services
  const agentServices = context.services.filter(s => s.type === 'agent');
  if (agentServices.length > 0) {
    findings.push({
      id: generateId(),
      severity: 'info',
      category: 'Agent Services',
      title: 'Agent consolidation opportunity',
      description: `${agentServices.length} agent services could potentially be consolidated.`,
      recommendation: 'Consider merging shopping-agent, scheduled-purchase, and steel-agent into single "actions" service to reduce operational overhead.',
      effort: 'large',
      impact: 'medium'
    });
  }

  return findings;
}

// ============================================================================
// iOS/Swift Patterns (ZeroInbox iOS)
// ============================================================================

export function reviewiOSPatterns(context: ProjectContext): ReviewFinding[] {
  const findings: ReviewFinding[] = [];

  if (!context.structure?.iosApp) return findings;

  const { pattern, swiftVersion } = context.structure.iosApp;

  // MVVM specific
  if (pattern === 'mvvm') {
    findings.push({
      id: generateId(),
      severity: 'info',
      category: 'iOS Architecture',
      title: 'MVVM pattern detected',
      description: 'MVVM with SwiftUI is a solid choice. Ensure ViewModels are @Observable (iOS 17+) or ObservableObject.',
      recommendation: 'Migrate from ObservableObject to @Observable macro for better performance. Use @Bindable in views.',
      effort: 'medium',
      impact: 'medium'
    });
  }

  // Swift 6 concurrency
  if (swiftVersion?.startsWith('6')) {
    findings.push({
      id: generateId(),
      severity: 'warning',
      category: 'Swift Concurrency',
      title: 'Swift 6 strict concurrency',
      description: 'Swift 6 enforces strict concurrency checking. All data races are compile-time errors.',
      recommendation: 'Audit all shared mutable state. Use actors for shared state. Mark non-Sendable types explicitly.',
      effort: 'large',
      impact: 'high'
    });
  }

  // Service layer patterns
  findings.push({
    id: generateId(),
    severity: 'suggestion',
    category: 'iOS Architecture',
    title: 'Service dependency injection',
    description: 'Services should be injectable for testing. Current services appear to be singletons.',
    recommendation: 'Use @Environment or explicit DI container. Create protocols for services to enable mocking.',
    effort: 'medium',
    impact: 'medium'
  });

  // Action modals (35 types mentioned in README)
  findings.push({
    id: generateId(),
    severity: 'suggestion',
    category: 'iOS UI',
    title: 'Action modal consolidation',
    description: '35 action modal implementations could benefit from a unified pattern.',
    recommendation: 'Create ActionModalProtocol with common behavior. Use generics for type-safe action handling.',
    effort: 'large',
    impact: 'medium'
  });

  return findings;
}

// ============================================================================
// Tailwind CSS Patterns
// ============================================================================

export function reviewTailwindPatterns(context: ProjectContext): ReviewFinding[] {
  const findings: ReviewFinding[] = [];

  if (context.techStack.ui?.styling !== 'tailwind') return findings;

  findings.push({
    id: generateId(),
    severity: 'suggestion',
    category: 'Tailwind CSS',
    title: 'Design tokens via CSS variables',
    description: 'Tailwind 4 supports CSS-first configuration with native CSS variables.',
    recommendation: 'Define design tokens in globals.css using @theme. Use semantic color names (--color-primary) over literal values.',
    effort: 'medium',
    impact: 'medium'
  });

  findings.push({
    id: generateId(),
    severity: 'suggestion',
    category: 'Tailwind CSS',
    title: 'Component variants with CVA',
    description: 'Complex component variants can be cleaner with class-variance-authority.',
    recommendation: 'Consider cva() for buttons, cards, and other components with multiple variants. Pairs well with shadcn/ui.',
    effort: 'small',
    impact: 'low'
  });

  return findings;
}

// ============================================================================
// Combined Review Runner
// ============================================================================

export function runStackSpecificReview(context: ProjectContext): ReviewFinding[] {
  const findings: ReviewFinding[] = [];

  // Run applicable reviews based on project context
  if (context.techStack.frameworks.some(f => f.toLowerCase().includes('next'))) {
    findings.push(...reviewNextJsPatterns(context));
  }

  if (context.techStack.threejs?.enabled) {
    findings.push(...reviewThreeJsPatterns(context));
  }

  if (context.services && context.services.length > 0) {
    findings.push(...reviewMicroservicesPatterns(context));
  }

  if (context.structure?.iosApp) {
    findings.push(...reviewiOSPatterns(context));
  }

  if (context.techStack.ui?.styling === 'tailwind') {
    findings.push(...reviewTailwindPatterns(context));
  }

  return findings;
}
