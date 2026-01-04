#!/usr/bin/env node
/**
 * Run Baseline Classification on Enron Corpus
 * 
 * Processes the scrubbed Enron corpus through Zero's classifier
 * and generates baseline metrics.
 * 
 * Usage:
 *   node run_baseline.js [--input PATH] [--output PATH] [--limit N] [--sample N]
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Import the classifier
const classifierPath = path.join(__dirname, '../../backend/services/classifier/action-first-classifier.js');
let classifyEmailActionFirst;

try {
  const classifier = require(classifierPath);
  classifyEmailActionFirst = classifier.classifyEmailActionFirst;
  console.log('✅ Loaded classifier from:', classifierPath);
} catch (error) {
  console.error('❌ Failed to load classifier:', error.message);
  console.log('Using mock classifier for testing...');
  // Mock classifier for testing
  classifyEmailActionFirst = async (email) => ({
    intent: 'generic.transactional',
    confidence: 0.5,
    type: 'mail',
    suggestedActions: []
  });
}

// Configuration
const DEFAULT_INPUT = '/Users/matthanson/Zer0_Inbox/emailcorpus/enron/scrubbed/enron_corpus_scrubbed.json';
const DEFAULT_OUTPUT = '/Users/matthanson/Zer0_Inbox/emailcorpus/enron/baseline_results.json';
const BATCH_SIZE = 1000;
const PROGRESS_INTERVAL = 10000;

// Parse command line args
const args = process.argv.slice(2);
const getArg = (name, defaultVal) => {
  const idx = args.indexOf(`--${name}`);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : defaultVal;
};

const INPUT_PATH = getArg('input', DEFAULT_INPUT);
const OUTPUT_PATH = getArg('output', DEFAULT_OUTPUT);
const LIMIT = getArg('limit', null) ? parseInt(getArg('limit', null)) : null;
const SAMPLE_SIZE = getArg('sample', null) ? parseInt(getArg('sample', null)) : null;

// Stats tracking
const stats = {
  total: 0,
  processed: 0,
  errors: 0,
  startTime: null,
  endTime: null,
  intents: {},
  confidenceBuckets: {
    high: 0,      // >= 0.7
    medium: 0,    // >= 0.5 < 0.7
    low: 0        // < 0.5
  },
  types: {},
  fallbacks: 0,
  timings: []
};

/**
 * Stream-parse JSON array file line by line
 */
async function* streamJsonArray(filePath) {
  const fileStream = fs.createReadStream(filePath, { encoding: 'utf8' });
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });

  let buffer = '';
  let inObject = false;
  let braceCount = 0;

  for await (const line of rl) {
    const trimmed = line.trim();
    
    // Skip array brackets
    if (trimmed === '[' || trimmed === ']') continue;
    
    // Handle object start
    if (trimmed.startsWith('{')) {
      inObject = true;
      buffer = '';
    }
    
    if (inObject) {
      buffer += line;
      braceCount += (line.match(/{/g) || []).length;
      braceCount -= (line.match(/}/g) || []).length;
      
      // Complete object
      if (braceCount === 0 && buffer.trim()) {
        // Remove trailing comma if present
        let jsonStr = buffer.trim();
        if (jsonStr.endsWith(',')) {
          jsonStr = jsonStr.slice(0, -1);
        }
        
        try {
          const obj = JSON.parse(jsonStr);
          yield obj;
        } catch (e) {
          // Skip malformed JSON
        }
        
        buffer = '';
        inObject = false;
      }
    }
  }
}

/**
 * Classify a single email and update stats
 */
async function classifyEmail(email, index) {
  const startTime = Date.now();
  
  try {
    const result = await classifyEmailActionFirst(email);
    const duration = Date.now() - startTime;
    
    // Update stats
    stats.processed++;
    stats.timings.push(duration);
    
    // Track intent distribution
    const intent = result.intent || 'unknown';
    stats.intents[intent] = (stats.intents[intent] || 0) + 1;
    
    // Track confidence buckets
    const confidence = result.confidence || result.intentConfidence || 0;
    if (confidence >= 0.7) {
      stats.confidenceBuckets.high++;
    } else if (confidence >= 0.5) {
      stats.confidenceBuckets.medium++;
    } else {
      stats.confidenceBuckets.low++;
    }
    
    // Track types
    const type = result.type || 'unknown';
    stats.types[type] = (stats.types[type] || 0) + 1;
    
    // Track fallbacks
    if (intent === 'generic.transactional' || intent === 'unknown') {
      stats.fallbacks++;
    }
    
    return { success: true, result, duration };
  } catch (error) {
    stats.errors++;
    return { success: false, error: error.message };
  }
}

/**
 * Main processing function
 */
async function main() {
  console.log('\n📊 Enron Corpus Baseline Classification');
  console.log('='.repeat(50));
  console.log(`Input:  ${INPUT_PATH}`);
  console.log(`Output: ${OUTPUT_PATH}`);
  if (LIMIT) console.log(`Limit:  ${LIMIT.toLocaleString()} emails`);
  if (SAMPLE_SIZE) console.log(`Sample: ${SAMPLE_SIZE.toLocaleString()} emails`);
  console.log();
  
  // Verify input exists
  if (!fs.existsSync(INPUT_PATH)) {
    console.error('❌ Input file not found:', INPUT_PATH);
    process.exit(1);
  }
  
  stats.startTime = new Date();
  
  // If sampling, first count total and pick random indices
  let sampleIndices = null;
  if (SAMPLE_SIZE) {
    console.log('Counting emails for sampling...');
    let count = 0;
    for await (const _ of streamJsonArray(INPUT_PATH)) {
      count++;
      if (count % 100000 === 0) console.log(`  Counted ${count.toLocaleString()}...`);
    }
    console.log(`Total emails: ${count.toLocaleString()}`);
    
    // Generate random sample indices
    const allIndices = Array.from({ length: count }, (_, i) => i);
    for (let i = allIndices.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [allIndices[i], allIndices[j]] = [allIndices[j], allIndices[i]];
    }
    sampleIndices = new Set(allIndices.slice(0, SAMPLE_SIZE));
    console.log(`Selected ${sampleIndices.size.toLocaleString()} random samples`);
    console.log();
  }
  
  // Process emails
  console.log('Processing emails...');
  let index = 0;
  let lastProgress = 0;
  
  for await (const email of streamJsonArray(INPUT_PATH)) {
    stats.total++;
    
    // Check if we should process this email
    const shouldProcess = !sampleIndices || sampleIndices.has(index);
    
    if (shouldProcess) {
      await classifyEmail(email, index);
    }
    
    index++;
    
    // Progress logging
    if (stats.processed - lastProgress >= PROGRESS_INTERVAL || 
        (stats.processed > 0 && stats.processed === stats.total)) {
      const elapsed = (Date.now() - stats.startTime.getTime()) / 1000;
      const rate = stats.processed / elapsed;
      console.log(`  Processed ${stats.processed.toLocaleString()} emails (${rate.toFixed(0)}/sec)`);
      lastProgress = stats.processed;
    }
    
    // Check limit
    if (LIMIT && stats.processed >= LIMIT) {
      console.log(`  Reached limit of ${LIMIT.toLocaleString()} emails`);
      break;
    }
  }
  
  stats.endTime = new Date();
  const duration = (stats.endTime - stats.startTime) / 1000;
  
  // Calculate metrics
  const avgTiming = stats.timings.length > 0 
    ? stats.timings.reduce((a, b) => a + b, 0) / stats.timings.length 
    : 0;
  
  const nonFallbackRate = stats.processed > 0 
    ? ((stats.processed - stats.fallbacks) / stats.processed * 100).toFixed(2)
    : 0;
  
  const highConfidenceRate = stats.processed > 0
    ? (stats.confidenceBuckets.high / stats.processed * 100).toFixed(2)
    : 0;
  
  const fallbackRate = stats.processed > 0
    ? (stats.fallbacks / stats.processed * 100).toFixed(2)
    : 0;
  
  // Sort intents by count
  const sortedIntents = Object.entries(stats.intents)
    .sort((a, b) => b[1] - a[1]);
  
  // Generate report
  const report = {
    timestamp: stats.endTime.toISOString(),
    duration_seconds: duration,
    input_file: INPUT_PATH,
    summary: {
      total_in_corpus: stats.total,
      emails_processed: stats.processed,
      errors: stats.errors,
      non_fallback_rate: `${nonFallbackRate}%`,
      high_confidence_rate: `${highConfidenceRate}%`,
      fallback_rate: `${fallbackRate}%`,
      avg_processing_ms: avgTiming.toFixed(2)
    },
    confidence_distribution: {
      high_gte_0_7: stats.confidenceBuckets.high,
      medium_0_5_to_0_7: stats.confidenceBuckets.medium,
      low_lt_0_5: stats.confidenceBuckets.low
    },
    type_distribution: stats.types,
    top_20_intents: sortedIntents.slice(0, 20).map(([intent, count]) => ({
      intent,
      count,
      percentage: (count / stats.processed * 100).toFixed(2) + '%'
    })),
    all_intents: Object.fromEntries(sortedIntents)
  };
  
  // Write report
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(report, null, 2));
  
  // Print summary
  console.log();
  console.log('✅ Baseline Classification Complete!');
  console.log('='.repeat(50));
  console.log(`Duration: ${duration.toFixed(1)} seconds`);
  console.log(`Emails processed: ${stats.processed.toLocaleString()}`);
  console.log(`Errors: ${stats.errors.toLocaleString()}`);
  console.log();
  console.log('📈 Key Metrics:');
  console.log(`  Non-fallback rate: ${nonFallbackRate}%`);
  console.log(`  High confidence (≥0.7): ${highConfidenceRate}%`);
  console.log(`  Fallback rate: ${fallbackRate}%`);
  console.log(`  Avg processing time: ${avgTiming.toFixed(2)}ms`);
  console.log();
  console.log('📊 Top 10 Intents:');
  sortedIntents.slice(0, 10).forEach(([intent, count], i) => {
    const pct = (count / stats.processed * 100).toFixed(1);
    console.log(`  ${i + 1}. ${intent}: ${count.toLocaleString()} (${pct}%)`);
  });
  console.log();
  console.log(`Report written to: ${OUTPUT_PATH}`);
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});

