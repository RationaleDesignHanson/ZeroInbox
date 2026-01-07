#!/usr/bin/env ts-node
/**
 * Test Script: ZeroAIExpertAgent Integration
 *
 * This script demonstrates how to invoke the ZeroAIExpertAgent for:
 * 1. Email integration review (Gmail API best practices)
 * 2. AI tuning review (classification & summarization optimization)
 * 3. Classification audit (43 category accuracy analysis)
 * 4. Evaluation framework setup
 *
 * Usage:
 *   npx ts-node test-zero-ai-agent.ts [action]
 *
 * Actions:
 *   email-integration   - Review Gmail API integration
 *   ai-tuning          - Review AI classification/summarization
 *   classification     - Audit 43 category accuracy
 *   evaluation         - Setup testing framework
 *   all                - Run all reviews (default)
 */

import { ZeroAIExpertAgent } from './agents/zero-ai-expert.agent';
import { AgentMessage } from './types/agent.types';
import { generateId } from './utils/helpers';

// ============================================================================
// Helper Functions
// ============================================================================

function createAgentMessage(action: string, payload: unknown): AgentMessage {
  return {
    id: generateId(),
    from: 'test-script',
    to: 'zero-ai-expert-001',
    type: 'request',
    action,
    payload,
    priority: 'normal',
    timestamp: Date.now()
  };
}

function printResponse(title: string, response: any): void {
  console.log('\n' + '='.repeat(80));
  console.log(`📋 ${title}`);
  console.log('='.repeat(80));
  console.log(JSON.stringify(response, null, 2));
  console.log('');
}

// ============================================================================
// Test Functions
// ============================================================================

async function testEmailIntegrationReview(agent: ZeroAIExpertAgent): Promise<void> {
  console.log('\n🔍 Testing Email Integration Review...\n');

  const message = createAgentMessage('email-integration', {
    provider: 'gmail',
    focus: 'full'  // authentication, fetching, threading, actions, sync
  });

  const response = await agent.receiveMessage(message);
  printResponse('Email Integration Review', response);

  // Extract key recommendations
  if (response.success && response.data) {
    const data = response.data as any;

    console.log('📌 Key Recommendations for EmailAPIService.swift:');
    console.log('');

    if (data.recommendations) {
      data.recommendations.forEach((rec: any, idx: number) => {
        console.log(`${idx + 1}. ${rec.area}: ${rec.recommendation}`);
        console.log(`   Implementation: ${rec.implementation}`);
        console.log('');
      });
    }

    if (data.bestPractices) {
      console.log('✅ Best Practices from Gmail API:');
      data.bestPractices.forEach((practice: string) => {
        console.log(`   • ${practice}`);
      });
      console.log('');
    }

    if (data.commonPitfalls) {
      console.log('⚠️  Common Pitfalls to Avoid:');
      data.commonPitfalls.forEach((pitfall: string) => {
        console.log(`   • ${pitfall}`);
      });
      console.log('');
    }
  }
}

async function testAITuningReview(agent: ZeroAIExpertAgent): Promise<void> {
  console.log('\n🎯 Testing AI Tuning Review...\n');

  const message = createAgentMessage('ai-tuning-review', {
    type: 'full',
    currentMetrics: {
      accuracy: 92,
      hallucinationRate: 4,
      latency: 2500,  // ms
      costPerRequest: 0.02  // $
    },
    targetMetrics: {
      accuracy: 95,
      hallucinationRate: 2,
      latency: 1500,
      costPerRequest: 0.01
    }
  });

  const response = await agent.receiveMessage(message);
  printResponse('AI Tuning Review', response);

  // Extract action plan
  if (response.success && response.data) {
    const data = response.data as any;

    if (data.actionPlan) {
      console.log('🗓️  4-Phase Action Plan:');
      console.log('');
      data.actionPlan.forEach((phase: any) => {
        console.log(`Phase ${phase.phase}: ${phase.name}`);
        console.log(`Duration: ${phase.duration}`);
        console.log(`Impact: ${phase.impact}`);
        console.log('Tasks:');
        phase.tasks.forEach((task: string) => {
          console.log(`  • ${task}`);
        });
        console.log('');
      });
    }

    if (data.weeklyMilestones) {
      console.log('📅 Weekly Milestones:');
      Object.entries(data.weeklyMilestones).forEach(([week, milestone]) => {
        console.log(`  ${week}: ${milestone}`);
      });
      console.log('');
    }
  }
}

async function testClassificationAudit(agent: ZeroAIExpertAgent): Promise<void> {
  console.log('\n📊 Testing Classification Audit...\n');

  const message = createAgentMessage('classification-audit', {
    categories: []  // Will use Zero's 43 default categories
  });

  const response = await agent.receiveMessage(message);
  printResponse('Classification Audit', response);

  // Extract findings
  if (response.success && response.data) {
    const data = response.data as any;

    console.log(`📈 Total Categories: ${data.totalCategories}`);
    console.log('');

    if (data.auditFindings) {
      console.log('🔍 Audit Findings (Low Accuracy Categories):');
      console.log('');
      data.auditFindings.forEach((finding: any) => {
        console.log(`Category: ${finding.category}`);
        console.log(`  Issue: ${finding.issue}`);
        console.log(`  Accuracy: ${finding.accuracy}%`);
        console.log(`  Recommendation: ${finding.recommendation}`);
        console.log('');
      });
    }

    if (data.improvementPlan) {
      console.log('📋 Improvement Plan:');
      data.improvementPlan.forEach((step: string, idx: number) => {
        console.log(`  ${idx + 1}. ${step}`);
      });
      console.log('');
    }

    if (data.targetAccuracyByCategory) {
      console.log('🎯 Target Accuracy:');
      console.log(`  Critical categories (${data.targetAccuracyByCategory.critical.join(', ')}): ${data.targetAccuracyByCategory.targetForCritical}`);
      console.log(`  Standard categories: ${data.targetAccuracyByCategory.targetForStandard}`);
      console.log('');
    }
  }
}

async function testEvaluationFramework(agent: ZeroAIExpertAgent): Promise<void> {
  console.log('\n🧪 Testing Evaluation Framework Setup...\n');

  const message = createAgentMessage('evaluation-framework', {
    focus: 'classification'
  });

  const response = await agent.receiveMessage(message);
  printResponse('Evaluation Framework', response);

  // Extract implementation details
  if (response.success && response.data) {
    const data = response.data as any;

    if (data.implementation?.goldenTestSet) {
      const testSet = data.implementation.goldenTestSet;
      console.log('📝 Golden Test Set Specifications:');
      console.log(`  Size: ${testSet.size}`);
      console.log(`  Coverage: ${testSet.coverage}`);
      console.log(`  Labeled Fields: ${testSet.labeledFields.join(', ')}`);
      console.log(`  Storage: ${testSet.storage}`);
      console.log(`  Usage: ${testSet.usage}`);
      console.log('');
    }

    if (data.implementation?.automatedTesting) {
      const testing = data.implementation.automatedTesting;
      console.log('🤖 Automated Testing:');
      console.log(`  Unit Tests: ${testing.unitTests}`);
      console.log(`  Integration Tests: ${testing.integrationTests}`);
      console.log(`  Regression Tests: ${testing.regressionTests}`);
      console.log(`  Alerting: ${testing.alerting}`);
      console.log('');
    }

    if (data.weeklyReviewProcess) {
      console.log('🔄 Weekly Review Process:');
      data.weeklyReviewProcess.forEach((step: string, idx: number) => {
        console.log(`  ${idx + 1}. ${step}`);
      });
      console.log('');
    }
  }
}

async function testModelRecommendation(agent: ZeroAIExpertAgent): Promise<void> {
  console.log('\n🤖 Testing Model Recommendation...\n');

  const message = createAgentMessage('model-recommendation', {
    useCase: 'email-classification',
    constraints: {
      maxLatency: 1500,  // ms
      maxCostPerEmail: 0.01  // $
    }
  });

  const response = await agent.receiveMessage(message);
  printResponse('Model Recommendation', response);

  // Extract recommendations
  if (response.success && response.data) {
    const data = response.data as any;

    if (data.recommendations) {
      console.log('🎯 Recommended Models by Use Case:');
      console.log('');

      Object.entries(data.recommendations).forEach(([useCase, rec]: [string, any]) => {
        console.log(`${useCase}:`);
        console.log(`  Primary: ${rec.primary}`);
        console.log(`  Reasoning: ${rec.reasoning}`);
        console.log(`  Fallback: ${rec.fallback}`);
        console.log(`  Cost: ${rec.costEstimate}`);
        console.log('');
      });
    }

    if (data.tieredArchitecture) {
      console.log('🏗️  Tiered Architecture:');
      console.log('');

      Object.entries(data.tieredArchitecture).forEach(([tier, config]: [string, any]) => {
        console.log(`${tier.replace('_', ' - ')}:`);
        console.log(`  Models: ${config.models.join(', ')}`);
        console.log(`  Use For: ${config.useFor}`);
        console.log(`  Target Latency: ${config.targetLatency}`);
        console.log(`  Target Cost: ${config.targetCost}`);
        console.log('');
      });
    }
  }
}

async function testCostOptimization(agent: ZeroAIExpertAgent): Promise<void> {
  console.log('\n💰 Testing Cost Optimization...\n');

  const message = createAgentMessage('cost-optimization', {
    currentCost: 0.15,  // $ per user per month
    targetCost: 0.10
  });

  const response = await agent.receiveMessage(message);
  printResponse('Cost Optimization', response);

  // Extract strategies
  if (response.success && response.data) {
    const data = response.data as any;

    if (data.strategies) {
      console.log('💡 Cost Optimization Strategies:');
      console.log('');

      Object.entries(data.strategies).forEach(([name, strategy]: [string, any]) => {
        console.log(`${name}:`);
        console.log(`  Expected Savings: ${strategy.expectedSavings}`);
        console.log(`  Implementation Effort: ${strategy.implementationEffort}`);
        console.log(`  Priority: ${strategy.priority}`);
        console.log('');
      });
    }

    if (data.costBreakdown) {
      console.log('📊 Cost Breakdown:');
      console.log('');
      console.log('Current:');
      Object.entries(data.costBreakdown.current).forEach(([item, cost]) => {
        console.log(`  ${item}: ${cost}`);
      });
      console.log('');
      console.log('Optimized:');
      Object.entries(data.costBreakdown.optimized).forEach(([item, cost]) => {
        console.log(`  ${item}: ${cost}`);
      });
      console.log('');
    }
  }
}

// ============================================================================
// Main Test Runner
// ============================================================================

async function main(): Promise<void> {
  const action = process.argv[2] || 'all';

  console.log('╔' + '═'.repeat(78) + '╗');
  console.log('║' + ' '.repeat(20) + '🤖 ZeroAIExpertAgent Test Suite' + ' '.repeat(26) + '║');
  console.log('╚' + '═'.repeat(78) + '╝');

  // Initialize agent
  const agent = new ZeroAIExpertAgent();
  console.log(`\n✅ Agent initialized: ${agent.getMetadata().name} (v${agent.getMetadata().version})`);
  console.log(`   Role: ${agent.getMetadata().role}`);
  console.log(`   Capabilities: ${agent.getCapabilities().length}`);

  try {
    switch (action) {
      case 'email-integration':
        await testEmailIntegrationReview(agent);
        break;

      case 'ai-tuning':
        await testAITuningReview(agent);
        break;

      case 'classification':
        await testClassificationAudit(agent);
        break;

      case 'evaluation':
        await testEvaluationFramework(agent);
        break;

      case 'models':
        await testModelRecommendation(agent);
        break;

      case 'cost':
        await testCostOptimization(agent);
        break;

      case 'all':
        await testEmailIntegrationReview(agent);
        await testAITuningReview(agent);
        await testClassificationAudit(agent);
        await testEvaluationFramework(agent);
        await testModelRecommendation(agent);
        await testCostOptimization(agent);
        break;

      default:
        console.error(`\n❌ Unknown action: ${action}`);
        console.log('\nAvailable actions:');
        console.log('  email-integration   - Review Gmail API integration');
        console.log('  ai-tuning          - Review AI classification/summarization');
        console.log('  classification     - Audit 43 category accuracy');
        console.log('  evaluation         - Setup testing framework');
        console.log('  models             - Get model recommendations');
        console.log('  cost               - Get cost optimization strategies');
        console.log('  all                - Run all reviews (default)');
        process.exit(1);
    }

    console.log('\n✅ Test completed successfully!\n');

  } catch (error) {
    console.error('\n❌ Test failed:', error);
    process.exit(1);
  }
}

// Run tests
main().catch(console.error);
