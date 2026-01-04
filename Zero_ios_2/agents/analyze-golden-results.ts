#!/usr/bin/env ts-node
/**
 * Golden Test Set Results Analyzer
 * Analyzes classification results from testing
 */

import * as fs from 'fs';
import * as path from 'path';

interface GoldenEmail {
  id: string;
  category: string;
  priority: 'critical' | 'high' | 'medium' | 'low';
  subject: string;
  from: string;
  from_name: string;
  body: string;
  summary: string;
  suggested_action: string;
  metadata: {
    known_accuracy?: number;
    generated_with: string;
  };
}

interface TestResult {
  id: string;
  expected_category: string;
  predicted_category: string;
  correct: boolean;
  priority: string;
  confidence?: number;
  response_time_ms?: number;
}

interface CategoryStats {
  category: string;
  total: number;
  correct: number;
  accuracy: number;
  known_baseline?: number;
}

const GOLDEN_SET_PATH = './golden-test-set/llm-golden-test-set.json';

function loadGoldenSet(): GoldenEmail[] {
  const data = fs.readFileSync(GOLDEN_SET_PATH, 'utf8');
  const parsed = JSON.parse(data);
  return parsed.emails || [];
}

function analyzeResults(results: TestResult[], goldenEmails: GoldenEmail[]): void {
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║   📊 Golden Test Set Results Analysis              ║');
  console.log('╚══════════════════════════════════════════════════════╝\n');

  // Overall stats
  const total = results.length;
  const correct = results.filter(r => r.correct).length;
  const accuracy = (correct / total) * 100;

  console.log('📈 Overall Performance:');
  console.log(`   Total: ${total} emails`);
  console.log(`   Correct: ${correct} (${accuracy.toFixed(1)}%)`);
  console.log(`   Incorrect: ${total - correct} (${(100 - accuracy).toFixed(1)}%)`);

  if (results[0]?.response_time_ms) {
    const avgTime = results.reduce((sum, r) => sum + (r.response_time_ms || 0), 0) / total;
    console.log(`   Avg response time: ${avgTime.toFixed(0)}ms`);
  }

  console.log();

  // By category
  const byCategory = new Map<string, TestResult[]>();
  results.forEach(r => {
    if (!byCategory.has(r.expected_category)) {
      byCategory.set(r.expected_category, []);
    }
    byCategory.get(r.expected_category)!.push(r);
  });

  const categoryStats: CategoryStats[] = [];
  byCategory.forEach((results, category) => {
    const total = results.length;
    const correct = results.filter(r => r.correct).length;
    const accuracy = (correct / total) * 100;

    // Find baseline accuracy
    const email = goldenEmails.find(e => e.category === category);
    const known_baseline = email?.metadata.known_accuracy;

    categoryStats.push({
      category,
      total,
      correct,
      accuracy,
      known_baseline
    });
  });

  // Sort by accuracy (worst first)
  categoryStats.sort((a, b) => a.accuracy - b.accuracy);

  console.log('📋 By Category (sorted by accuracy):');
  console.log();
  console.log('Category                 Count  Correct  Accuracy  Baseline  Status');
  console.log('─────────────────────────────────────────────────────────────────────');

  categoryStats.forEach(stat => {
    const baseline = stat.known_baseline ? `${stat.known_baseline}%` : 'N/A';
    let status = '';

    if (stat.accuracy >= 98) {
      status = '✅ Excellent';
    } else if (stat.accuracy >= 95) {
      status = '✅ Good';
    } else if (stat.accuracy >= 90) {
      status = '⚠️  Needs improvement';
    } else {
      status = '❌ Poor';
    }

    // Check if improved over baseline
    if (stat.known_baseline && stat.accuracy > stat.known_baseline) {
      status += ` (↑${(stat.accuracy - stat.known_baseline).toFixed(0)}%)`;
    }

    const name = stat.category.padEnd(24);
    const count = stat.total.toString().padStart(5);
    const correct = stat.correct.toString().padStart(7);
    const accuracy = `${stat.accuracy.toFixed(1)}%`.padStart(9);
    const baselineStr = baseline.padStart(9);

    console.log(`${name} ${count} ${correct}  ${accuracy} ${baselineStr}  ${status}`);
  });

  console.log();

  // By priority
  const byPriority = new Map<string, TestResult[]>();
  results.forEach(r => {
    if (!byPriority.has(r.priority)) {
      byPriority.set(r.priority, []);
    }
    byPriority.get(r.priority)!.push(r);
  });

  console.log('🎯 By Priority:');
  console.log();

  ['critical', 'high', 'medium', 'low'].forEach(priority => {
    const results = byPriority.get(priority) || [];
    if (results.length === 0) return;

    const total = results.length;
    const correct = results.filter(r => r.correct).length;
    const accuracy = (correct / total) * 100;

    let target = 0;
    let status = '';
    if (priority === 'critical') {
      target = 98;
      status = accuracy >= 98 ? '✅' : '❌';
    } else if (priority === 'high') {
      target = 95;
      status = accuracy >= 95 ? '✅' : '⚠️ ';
    } else if (priority === 'medium') {
      target = 95;
      status = accuracy >= 95 ? '✅' : '⚠️ ';
    } else {
      target = 90;
      status = accuracy >= 90 ? '✅' : '⚠️ ';
    }

    console.log(`   ${status} ${priority.toUpperCase().padEnd(8)} ${correct}/${total} (${accuracy.toFixed(1)}%)  Target: ${target}%`);
  });

  console.log();

  // Misclassified emails
  const misclassified = results.filter(r => !r.correct);
  if (misclassified.length > 0) {
    console.log('❌ Misclassified Emails:');
    console.log();

    misclassified.forEach(result => {
      const email = goldenEmails.find(e => e.id === result.id);
      if (!email) return;

      console.log(`   ID: ${result.id}`);
      console.log(`   Subject: ${email.subject}`);
      console.log(`   Expected: ${result.expected_category}`);
      console.log(`   Predicted: ${result.predicted_category}`);
      if (result.confidence) {
        console.log(`   Confidence: ${(result.confidence * 100).toFixed(1)}%`);
      }
      console.log();
    });
  }

  // Success criteria check
  console.log('✅ Success Criteria:');
  console.log();

  const criticalAccuracy = byPriority.get('critical')
    ? (byPriority.get('critical')!.filter(r => r.correct).length / byPriority.get('critical')!.length) * 100
    : 100;

  console.log(`   Overall accuracy ≥95%:        ${accuracy >= 95 ? '✅' : '❌'} ${accuracy.toFixed(1)}%`);
  console.log(`   Critical accuracy ≥98%:       ${criticalAccuracy >= 98 ? '✅' : '❌'} ${criticalAccuracy.toFixed(1)}%`);
  console.log(`   No fatal errors:              ✅ (assumed)`);
  console.log(`   Average response <500ms:      ✅ (assumed)`);
  console.log();

  // Next steps
  if (accuracy >= 95 && criticalAccuracy >= 98) {
    console.log('🎉 READY FOR PRODUCTION TESTING!');
    console.log('   Next: Test with 3-5 real user accounts');
  } else {
    console.log('⚠️  NEEDS IMPROVEMENT');
    console.log('   Next: Analyze misclassified emails and improve classifier');
  }

  console.log();
}

// Example usage with mock data
function generateMockResults(emails: GoldenEmail[]): TestResult[] {
  // Simulate 95% accuracy
  return emails.map(email => ({
    id: email.id,
    expected_category: email.category,
    predicted_category: Math.random() > 0.05 ? email.category : 'promotional', // 95% correct
    correct: Math.random() > 0.05,
    priority: email.priority,
    confidence: Math.random() * 0.3 + 0.7, // 70-100% confidence
    response_time_ms: Math.random() * 300 + 200 // 200-500ms
  }));
}

// Main
const emails = loadGoldenSet();
console.log(`Loaded ${emails.length} test emails\n`);

// For demonstration, generate mock results
// In real testing, these would come from actual classification
const mockResults = generateMockResults(emails);

analyzeResults(mockResults, emails);

// Export for testing
export { analyzeResults, loadGoldenSet };
