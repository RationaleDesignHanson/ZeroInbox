#!/usr/bin/env node
/**
 * Detailed Hallucination Analysis
 * 
 * Analyzes each flagged case to determine if it's a real hallucination
 * or a false positive from the automated detection.
 */

const fs = require('fs');
const path = require('path');
const axios = require('axios');

const SUMMARIZATION_SERVICE_URL = process.env.SUMMARIZATION_SERVICE_URL || 'http://localhost:8083';

// Load golden test set
const inputFile = path.join(__dirname, '..', 'golden_test_set', 'golden_test_set.json');
const emails = JSON.parse(fs.readFileSync(inputFile, 'utf-8'));

/**
 * Enhanced hallucination detection with context
 */
function checkHallucinations(email, summary) {
  const issues = [];
  const emailText = `${email.subject || ''} ${email.body || ''}`;
  const emailTextLower = emailText.toLowerCase();
  const summaryLower = summary.toLowerCase();
  
  // 1. Check for dates not in original
  const datePatterns = [
    /\b\d{1,2}\/\d{1,2}\/\d{2,4}\b/g,                    // 12/25/2024
    /\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2}/gi,  // January 25
    /\b\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*/gi,  // 25 January
  ];
  
  for (const pattern of datePatterns) {
    const matches = summary.match(pattern) || [];
    for (const date of matches) {
      // Check if date exists in original (case insensitive)
      if (!emailTextLower.includes(date.toLowerCase())) {
        // Check for partial match (e.g., "Oct 25" might be in "October 25")
        const dateWords = date.toLowerCase().split(/\s+/);
        const partialMatch = dateWords.some(w => emailTextLower.includes(w) && w.length > 2);
        
        issues.push({
          type: 'date_not_found',
          value: date,
          severity: partialMatch ? 'low' : 'medium',
          context: partialMatch ? 'Partial date match found' : 'Date may be hallucinated',
          likelyFalsePositive: partialMatch
        });
      }
    }
  }
  
  // 2. Check for dollar amounts not in original
  const amountPattern = /\$[\d,]+\.?\d*/g;
  const summaryAmounts = summary.match(amountPattern) || [];
  const originalAmounts = emailText.match(amountPattern) || [];
  
  for (const amount of summaryAmounts) {
    if (!originalAmounts.includes(amount)) {
      // Check if it's a reformatted version (e.g., "$1,000" vs "$1000")
      const numericValue = amount.replace(/[$,]/g, '');
      const isReformat = originalAmounts.some(a => a.replace(/[$,]/g, '') === numericValue);
      
      issues.push({
        type: 'amount_not_found',
        value: amount,
        severity: isReformat ? 'low' : 'high',
        context: isReformat ? 'Amount reformatted' : 'Dollar amount may be hallucinated',
        likelyFalsePositive: isReformat
      });
    }
  }
  
  // 3. Check for specific large numbers (order numbers, IDs)
  const largeNumberPattern = /\b\d{5,}\b/g;
  const summaryNumbers = summary.match(largeNumberPattern) || [];
  
  for (const num of summaryNumbers) {
    if (!emailText.includes(num)) {
      issues.push({
        type: 'number_not_found',
        value: num,
        severity: 'high',
        context: 'Large number (possibly order/ID) may be hallucinated',
        likelyFalsePositive: false
      });
    }
  }
  
  // 4. Check for time patterns
  const timePattern = /\b\d{1,2}:\d{2}\s*(am|pm|AM|PM)?\b/g;
  const summaryTimes = summary.match(timePattern) || [];
  
  for (const time of summaryTimes) {
    if (!emailTextLower.includes(time.toLowerCase())) {
      issues.push({
        type: 'time_not_found',
        value: time,
        severity: 'medium',
        context: 'Time may be hallucinated',
        likelyFalsePositive: false
      });
    }
  }
  
  // 5. Check for URLs/links in summary that aren't in original
  const urlPattern = /https?:\/\/[^\s]+/g;
  const summaryUrls = summary.match(urlPattern) || [];
  
  for (const url of summaryUrls) {
    if (!emailText.includes(url)) {
      // Check if domain is present
      const domain = url.match(/https?:\/\/([^\/]+)/)?.[1];
      const domainPresent = domain && emailTextLower.includes(domain.toLowerCase());
      
      issues.push({
        type: 'url_not_found',
        value: url.substring(0, 50) + '...',
        severity: domainPresent ? 'low' : 'high',
        context: domainPresent ? 'URL domain present, path may differ' : 'URL may be hallucinated',
        likelyFalsePositive: domainPresent
      });
    }
  }
  
  // Categorize issues
  const realIssues = issues.filter(i => !i.likelyFalsePositive);
  const falsePositives = issues.filter(i => i.likelyFalsePositive);
  
  return {
    hasIssues: issues.length > 0,
    hasRealIssues: realIssues.length > 0,
    issues,
    realIssues,
    falsePositives,
    summary: {
      total: issues.length,
      real: realIssues.length,
      falsePositives: falsePositives.length,
      highSeverity: issues.filter(i => i.severity === 'high').length,
      mediumSeverity: issues.filter(i => i.severity === 'medium').length,
      lowSeverity: issues.filter(i => i.severity === 'low').length
    }
  };
}

async function analyzeHallucinations() {
  console.log('='.repeat(70));
  console.log('🔍 Detailed Hallucination Analysis');
  console.log('='.repeat(70));
  console.log(`\nAnalyzing ${emails.length} emails from golden test set...`);
  
  // Check service
  try {
    await axios.get(`${SUMMARIZATION_SERVICE_URL}/health`, { timeout: 5000 });
    console.log('✅ Summarization service is running\n');
  } catch (e) {
    console.log('❌ Summarization service not available');
    process.exit(1);
  }
  
  const results = {
    total: 0,
    flagged: 0,
    realIssues: 0,
    falsePositives: 0,
    byType: {},
    cases: []
  };
  
  const sample = emails.slice(0, 200);  // Test all 200 emails
  
  for (let i = 0; i < sample.length; i++) {
    const email = sample[i];
    process.stdout.write(`\rProcessing ${i+1}/${sample.length}...`);
    
    try {
      const response = await axios.post(
        `${SUMMARIZATION_SERVICE_URL}/api/summarize`,
        { email },
        { timeout: 30000 }
      );
      
      const summary = response.data.summary || '';
      const analysis = checkHallucinations(email, summary);
      
      results.total++;
      
      if (analysis.hasIssues) {
        results.flagged++;
        results.realIssues += analysis.realIssues.length;
        results.falsePositives += analysis.falsePositives.length;
        
        // Track by type
        for (const issue of analysis.issues) {
          results.byType[issue.type] = (results.byType[issue.type] || 0) + 1;
        }
        
        results.cases.push({
          index: i + 1,
          subject: email.subject,
          from: email.from,
          analysis,
          summary: summary.substring(0, 500),
          originalSnippet: (email.body || '').substring(0, 500)
        });
      }
    } catch (e) {
      console.log(`\nError on email ${i + 1}: ${e.message}`);
    }
    
    await new Promise(r => setTimeout(r, 100));
  }
  
  // Print results
  console.log('\n\n' + '='.repeat(70));
  console.log('📊 SUMMARY');
  console.log('='.repeat(70));
  
  console.log(`\nTotal emails analyzed: ${results.total}`);
  console.log(`Emails with flags: ${results.flagged} (${(results.flagged/results.total*100).toFixed(1)}%)`);
  console.log(`\nFlag breakdown:`);
  console.log(`  • Likely false positives: ${results.falsePositives}`);
  console.log(`  • Potential real issues: ${results.realIssues}`);
  
  console.log(`\nFlags by type:`);
  for (const [type, count] of Object.entries(results.byType).sort((a, b) => b[1] - a[1])) {
    console.log(`  • ${type}: ${count}`);
  }
  
  // Print detailed cases
  if (results.cases.length > 0) {
    console.log('\n\n' + '='.repeat(70));
    console.log('📋 DETAILED FLAGGED CASES');
    console.log('='.repeat(70));
    
    for (const c of results.cases) {
      console.log('\n' + '-'.repeat(70));
      console.log(`📧 #${c.index}: ${c.subject?.substring(0, 60)}`);
      console.log(`   From: ${c.from?.substring(0, 40)}`);
      console.log('-'.repeat(70));
      
      console.log('\n🚩 FLAGS:');
      for (const issue of c.analysis.issues) {
        const fpTag = issue.likelyFalsePositive ? ' [LIKELY FALSE POSITIVE]' : '';
        const sevColor = issue.severity === 'high' ? '🔴' : issue.severity === 'medium' ? '🟡' : '🟢';
        console.log(`   ${sevColor} ${issue.type}: "${issue.value}"${fpTag}`);
        console.log(`      ${issue.context}`);
      }
      
      console.log('\n📝 SUMMARY:');
      console.log('   ' + c.summary.replace(/\n/g, '\n   '));
      
      console.log('\n📄 ORIGINAL EMAIL (first 300 chars):');
      console.log('   ' + c.originalSnippet.substring(0, 300).replace(/\n/g, '\n   '));
    }
  }
  
  // Calculate actual hallucination rate
  const actualHallucinationRate = results.total > 0 
    ? (results.cases.filter(c => c.analysis.hasRealIssues).length / results.total * 100)
    : 0;
  
  console.log('\n\n' + '='.repeat(70));
  console.log('🎯 HALLUCINATION RATE ANALYSIS');
  console.log('='.repeat(70));
  console.log(`\nRaw flag rate: ${(results.flagged/results.total*100).toFixed(1)}%`);
  console.log(`Estimated actual hallucination rate: ${actualHallucinationRate.toFixed(1)}%`);
  console.log(`Target: <2%`);
  console.log(`Status: ${actualHallucinationRate < 2 ? '✅ PASS' : '⚠️ NEEDS REVIEW'}`);
  
  // Save detailed results
  const outputFile = path.join(__dirname, '..', 'hallucination_analysis.json');
  fs.writeFileSync(outputFile, JSON.stringify(results, null, 2));
  console.log(`\n📁 Detailed results saved to: ${outputFile}`);
}

analyzeHallucinations().catch(console.error);

