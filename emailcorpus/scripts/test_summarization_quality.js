#!/usr/bin/env node
/**
 * Week 2: Summarization Quality Testing Framework
 * 
 * Tests:
 * 1. Latency (<2 seconds target)
 * 2. Cost estimation (<$0.015 per summary)
 * 3. Accuracy evaluation samples (manual review)
 * 4. Hallucination detection (automated checks)
 * 
 * Usage:
 *   node test_summarization_quality.js --sample 50
 *   node test_summarization_quality.js --input path/to/emails.json --limit 100
 */

const fs = require('fs');
const path = require('path');
const axios = require('axios');

// Configuration
const SUMMARIZATION_SERVICE_URL = process.env.SUMMARIZATION_SERVICE_URL || 'http://localhost:8083';
const DEFAULT_SAMPLE_SIZE = 50;

// Cost estimates (Gemini 2.0 Flash pricing)
const COST_PER_1K_INPUT_TOKENS = 0.000075;  // $0.075 per 1M input tokens
const COST_PER_1K_OUTPUT_TOKENS = 0.0003;   // $0.30 per 1M output tokens
const AVG_INPUT_TOKENS = 500;  // Average email length in tokens
const AVG_OUTPUT_TOKENS = 150; // Average summary length in tokens

// Parse arguments
const args = process.argv.slice(2);
let inputFile = null;
let sampleSize = DEFAULT_SAMPLE_SIZE;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--input' && args[i + 1]) {
    inputFile = args[i + 1];
    i++;
  } else if (args[i] === '--sample' && args[i + 1]) {
    sampleSize = parseInt(args[i + 1], 10);
    i++;
  } else if (args[i] === '--limit' && args[i + 1]) {
    sampleSize = parseInt(args[i + 1], 10);
    i++;
  }
}

// Default to golden test set
if (!inputFile) {
  inputFile = path.join(__dirname, '..', 'golden_test_set', 'golden_test_set.json');
}

/**
 * Load emails from JSON file
 */
function loadEmails(filePath) {
  const data = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(data);
}

/**
 * Estimate token count (rough approximation)
 */
function estimateTokens(text) {
  if (!text) return 0;
  // Rough estimate: 1 token ≈ 4 characters for English
  return Math.ceil(text.length / 4);
}

/**
 * Calculate estimated cost for a summary
 */
function calculateCost(inputText, outputText) {
  const inputTokens = estimateTokens(inputText);
  const outputTokens = estimateTokens(outputText);
  
  const inputCost = (inputTokens / 1000) * COST_PER_1K_INPUT_TOKENS;
  const outputCost = (outputTokens / 1000) * COST_PER_1K_OUTPUT_TOKENS;
  
  return {
    inputTokens,
    outputTokens,
    inputCost,
    outputCost,
    totalCost: inputCost + outputCost
  };
}

/**
 * Check for potential hallucinations
 */
function checkHallucinations(email, summary) {
  const issues = [];
  
  // Check for dates not in original
  const summaryDates = summary.match(/\b\d{1,2}\/\d{1,2}\/\d{2,4}\b|\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+\d{1,2}/gi) || [];
  const emailText = `${email.subject} ${email.body}`;
  
  for (const date of summaryDates) {
    if (!emailText.toLowerCase().includes(date.toLowerCase())) {
      issues.push({ type: 'date_not_found', value: date });
    }
  }
  
  // Check for dollar amounts not in original
  const summaryAmounts = summary.match(/\$[\d,]+\.?\d*/g) || [];
  for (const amount of summaryAmounts) {
    if (!emailText.includes(amount)) {
      issues.push({ type: 'amount_not_found', value: amount });
    }
  }
  
  // Check for names/companies that might be hallucinated
  // (Basic check - look for capitalized words not in original)
  const summaryNames = summary.match(/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b/g) || [];
  const commonWords = ['The', 'This', 'Action', 'Actions', 'Why', 'Context', 'Email', 'Summary', 'Please', 'Important'];
  
  for (const name of summaryNames) {
    if (!commonWords.includes(name) && !emailText.includes(name)) {
      // Only flag if it looks like a proper noun
      if (name.length > 3) {
        issues.push({ type: 'potential_name_hallucination', value: name });
      }
    }
  }
  
  return {
    hasIssues: issues.length > 0,
    issues
  };
}

/**
 * Call summarization service
 */
async function summarizeEmail(email) {
  const startTime = Date.now();
  
  try {
    const response = await axios.post(
      `${SUMMARIZATION_SERVICE_URL}/api/summarize`,
      { email },
      { timeout: 30000 }
    );
    
    const latencyMs = Date.now() - startTime;
    
    return {
      success: true,
      summary: response.data.summary,
      source: response.data.source || 'ai',
      latencyMs,
      raw: response.data
    };
  } catch (error) {
    const latencyMs = Date.now() - startTime;
    return {
      success: false,
      error: error.message,
      latencyMs
    };
  }
}

/**
 * Run summarization quality tests
 */
async function runTests() {
  console.log('=' .repeat(70));
  console.log('📊 Week 2: Summarization Quality Testing');
  console.log('=' .repeat(70));
  console.log(`\nInput file: ${inputFile}`);
  console.log(`Sample size: ${sampleSize}`);
  console.log(`Summarization service: ${SUMMARIZATION_SERVICE_URL}`);
  
  // Check if service is available
  console.log('\n🔍 Checking summarization service...');
  try {
    const health = await axios.get(`${SUMMARIZATION_SERVICE_URL}/health`, { timeout: 5000 });
    console.log(`   ✅ Service is running: ${health.data.vertexAI?.model || 'unknown model'}`);
  } catch (error) {
    console.log(`   ❌ Service not available: ${error.message}`);
    console.log('\n   To start the summarization service:');
    console.log('   cd backend/services/summarization && npm start');
    console.log('\n   Or run without AI (fallback mode):');
    console.log('   This test will use fallback summarization if service unavailable.\n');
  }
  
  // Load emails
  console.log('\n📂 Loading emails...');
  let emails;
  try {
    emails = loadEmails(inputFile);
    console.log(`   Loaded ${emails.length} emails`);
  } catch (error) {
    console.error(`   ❌ Error loading emails: ${error.message}`);
    process.exit(1);
  }
  
  // Sample emails
  const sample = emails.slice(0, sampleSize);
  console.log(`   Testing ${sample.length} emails`);
  
  // Run tests
  console.log('\n🧪 Running summarization tests...\n');
  
  const results = {
    total: sample.length,
    successful: 0,
    failed: 0,
    latencies: [],
    costs: [],
    hallucinationFlags: 0,
    summaries: []
  };
  
  for (let i = 0; i < sample.length; i++) {
    const email = sample[i];
    const subject = email.subject || '(No Subject)';
    
    process.stdout.write(`   [${i + 1}/${sample.length}] ${subject.substring(0, 40)}...`);
    
    const result = await summarizeEmail(email);
    
    if (result.success) {
      results.successful++;
      results.latencies.push(result.latencyMs);
      
      // Calculate cost
      const inputText = `${email.subject} ${email.body || ''}`;
      const cost = calculateCost(inputText, result.summary);
      results.costs.push(cost.totalCost);
      
      // Check hallucinations
      const hallCheck = checkHallucinations(email, result.summary);
      if (hallCheck.hasIssues) {
        results.hallucinationFlags++;
      }
      
      results.summaries.push({
        email: {
          subject: email.subject,
          from: email.from,
          bodyPreview: (email.body || '').substring(0, 200)
        },
        summary: result.summary,
        latencyMs: result.latencyMs,
        cost: cost.totalCost,
        hallucinations: hallCheck
      });
      
      process.stdout.write(` ✅ ${result.latencyMs}ms\n`);
    } else {
      results.failed++;
      process.stdout.write(` ❌ ${result.error}\n`);
    }
    
    // Small delay to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  // Calculate metrics
  const avgLatency = results.latencies.length > 0 
    ? results.latencies.reduce((a, b) => a + b, 0) / results.latencies.length 
    : 0;
  const maxLatency = results.latencies.length > 0 
    ? Math.max(...results.latencies) 
    : 0;
  const p95Latency = results.latencies.length > 0
    ? results.latencies.sort((a, b) => a - b)[Math.floor(results.latencies.length * 0.95)]
    : 0;
  
  const avgCost = results.costs.length > 0
    ? results.costs.reduce((a, b) => a + b, 0) / results.costs.length
    : 0;
  
  const hallucinationRate = results.successful > 0
    ? (results.hallucinationFlags / results.successful) * 100
    : 0;
  
  // Print results
  console.log('\n' + '=' .repeat(70));
  console.log('📈 RESULTS');
  console.log('=' .repeat(70));
  
  console.log('\n📊 Success Rate:');
  console.log(`   Successful: ${results.successful}/${results.total} (${(results.successful/results.total*100).toFixed(1)}%)`);
  console.log(`   Failed: ${results.failed}/${results.total}`);
  
  console.log('\n⏱️  Latency Metrics:');
  console.log(`   Average: ${avgLatency.toFixed(0)}ms ${avgLatency < 2000 ? '✅' : '❌'} (target: <2000ms)`);
  console.log(`   P95: ${p95Latency}ms`);
  console.log(`   Max: ${maxLatency}ms`);
  
  console.log('\n💰 Cost Metrics:');
  console.log(`   Avg per summary: $${avgCost.toFixed(6)} ${avgCost < 0.015 ? '✅' : '❌'} (target: <$0.015)`);
  console.log(`   Est. 1000 summaries: $${(avgCost * 1000).toFixed(2)}`);
  
  console.log('\n🔍 Hallucination Flags:');
  console.log(`   Flagged: ${results.hallucinationFlags}/${results.successful} (${hallucinationRate.toFixed(1)}%) ${hallucinationRate < 2 ? '✅' : '⚠️'} (target: <2%)`);
  console.log(`   Note: Flags require manual review - not all are actual hallucinations`);
  
  // Target summary
  console.log('\n' + '=' .repeat(70));
  console.log('🎯 WEEK 2 TARGETS');
  console.log('=' .repeat(70));
  console.log(`   Latency <2s:        ${avgLatency < 2000 ? '✅ PASS' : '❌ FAIL'} (${avgLatency.toFixed(0)}ms)`);
  console.log(`   Cost <$0.015:       ${avgCost < 0.015 ? '✅ PASS' : '❌ FAIL'} ($${avgCost.toFixed(6)})`);
  console.log(`   Hallucination <2%:  ${hallucinationRate < 2 ? '✅ PASS' : '⚠️  REVIEW'} (${hallucinationRate.toFixed(1)}% flagged)`);
  console.log(`   Accuracy >95%:      ⏳ Manual review required`);
  
  // Save results
  const outputFile = path.join(__dirname, '..', 'summarization_test_results.json');
  const report = {
    timestamp: new Date().toISOString(),
    config: {
      inputFile,
      sampleSize,
      serviceUrl: SUMMARIZATION_SERVICE_URL
    },
    metrics: {
      total: results.total,
      successful: results.successful,
      failed: results.failed,
      avgLatencyMs: avgLatency,
      p95LatencyMs: p95Latency,
      maxLatencyMs: maxLatency,
      avgCostPerSummary: avgCost,
      hallucinationFlagRate: hallucinationRate
    },
    targets: {
      latency: { target: '<2000ms', actual: `${avgLatency.toFixed(0)}ms`, pass: avgLatency < 2000 },
      cost: { target: '<$0.015', actual: `$${avgCost.toFixed(6)}`, pass: avgCost < 0.015 },
      hallucination: { target: '<2%', actual: `${hallucinationRate.toFixed(1)}%`, pass: hallucinationRate < 2 }
    },
    summaries: results.summaries.slice(0, 20) // Save first 20 for manual review
  };
  
  fs.writeFileSync(outputFile, JSON.stringify(report, null, 2));
  console.log(`\n📁 Results saved to: ${outputFile}`);
  
  // Create manual review file
  const reviewFile = path.join(__dirname, '..', 'summarization_manual_review.md');
  let reviewContent = `# Summarization Manual Review

Generated: ${new Date().toISOString()}

## Instructions
Review each summary for:
1. **Accuracy**: Does the summary correctly capture the email's main points?
2. **Hallucinations**: Does the summary contain information not in the original?
3. **Quality**: Is the summary useful for quick triage?

Mark each as: ✅ Good | ⚠️ Minor Issues | ❌ Major Issues

---

`;

  for (let i = 0; i < Math.min(20, results.summaries.length); i++) {
    const s = results.summaries[i];
    reviewContent += `## Sample ${i + 1}

**Subject:** ${s.email.subject}
**From:** ${s.email.from}

**Original (first 200 chars):**
\`\`\`
${s.email.bodyPreview}
\`\`\`

**Summary:**
\`\`\`
${s.summary}
\`\`\`

**Auto-flags:** ${s.hallucinations.hasIssues ? s.hallucinations.issues.map(i => `${i.type}: ${i.value}`).join(', ') : 'None'}
**Latency:** ${s.latencyMs}ms
**Cost:** $${s.cost.toFixed(6)}

**Manual Review:** [ ] ✅ Good  [ ] ⚠️ Minor Issues  [ ] ❌ Major Issues

**Notes:**


---

`;
  }
  
  fs.writeFileSync(reviewFile, reviewContent);
  console.log(`📝 Manual review template: ${reviewFile}`);
}

// Run
runTests().catch(console.error);

