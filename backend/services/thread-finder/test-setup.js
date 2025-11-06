/**
 * Thread Finder Setup Test
 * Verifies configuration and tests link classification
 */

require('dotenv').config({ path: '../../.env' });
const { classifyLink, processEmailWithLink } = require('./steel-integration');

console.log('\n🔍 Thread Finder Setup Test\n');
console.log('=' .repeat(60));

// Check environment variables
console.log('\n📋 Environment Configuration:\n');

const config = {
  'STEEL_API_KEY': process.env.STEEL_API_KEY || '❌ NOT SET',
  'CANVAS_API_TOKEN': process.env.CANVAS_API_TOKEN || '❌ NOT SET',
  'CANVAS_DOMAIN': process.env.CANVAS_DOMAIN || '❌ NOT SET (will use default)',
  'USE_THREAD_FINDER': process.env.USE_THREAD_FINDER || 'true (default)',
};

Object.entries(config).forEach(([key, value]) => {
  const status = value.includes('NOT SET') ? '❌' : '✅';
  const displayValue = key.includes('KEY') || key.includes('TOKEN')
    ? (value.includes('NOT SET') ? value : `${value.substring(0, 10)}...`)
    : value;
  console.log(`  ${status} ${key}: ${displayValue}`);
});

console.log('\n' + '='.repeat(60));
console.log('\n🧪 Testing Link Classification:\n');

// Test links
const testLinks = [
  {
    name: 'Canvas Assignment',
    url: 'https://canvas.instructure.com/courses/12345/assignments/67890',
    expected: 'LEARNING_PLATFORM - Canvas LMS (API available)'
  },
  {
    name: 'Google Classroom',
    url: 'https://classroom.google.com/c/12345',
    expected: 'LEARNING_PLATFORM - Google Classroom (API available)'
  },
  {
    name: 'School Portal',
    url: 'https://pascackvalley.org/announcements/123',
    expected: 'SCHOOL_PORTAL - Pascack Valley (requires Steel)'
  },
  {
    name: 'SportsEngine',
    url: 'https://www.sportsengine.com/team/123/schedule',
    expected: 'SPORTS_PLATFORM - SportsEngine (requires Steel)'
  },
  {
    name: 'Unknown Platform',
    url: 'https://example.com/page',
    expected: 'UNKNOWN'
  }
];

testLinks.forEach(test => {
  const result = classifyLink(test.url);
  const status = result.category !== 'UNKNOWN' ? '✅' : '⚠️';

  console.log(`  ${status} ${test.name}:`);
  console.log(`     Category: ${result.category}`);
  console.log(`     Platform: ${result.platform}`);
  console.log(`     Has API: ${result.hasAPI ? 'Yes' : 'No'}`);
  console.log(`     Requires Crawl: ${result.requiresCrawl ? 'Yes' : 'No'}`);
  console.log('');
});

console.log('='.repeat(60));
console.log('\n📝 Setup Instructions:\n');

if (!process.env.STEEL_API_KEY || process.env.STEEL_API_KEY === 'your-steel-api-key-here') {
  console.log('  ⚠️  Steel API Key Not Configured');
  console.log('  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  1. Sign up at https://steel.dev');
  console.log('  2. Get your API key from the dashboard');
  console.log('  3. Add to /Users/matthanson/Zer0_Inbox/backend/.env:');
  console.log('     STEEL_API_KEY=your-actual-steel-api-key');
  console.log('');
}

if (!process.env.CANVAS_API_TOKEN || process.env.CANVAS_API_TOKEN === 'your-canvas-api-token-here') {
  console.log('  ⚠️  Canvas API Token Not Configured (Optional but Recommended)');
  console.log('  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('  1. Go to https://canvas.instructure.com/profile/settings');
  console.log('  2. Click "+ New Access Token"');
  console.log('  3. Purpose: "Zero Inbox Thread Finder"');
  console.log('  4. Add to /Users/matthanson/Zer0_Inbox/backend/.env:');
  console.log('     CANVAS_API_TOKEN=your-canvas-token');
  console.log('     CANVAS_DOMAIN=your-school.instructure.com');
  console.log('');
}

console.log('  ✅ To test with a real email link:');
console.log('  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('  node test-setup.js --test-email');
console.log('');

console.log('='.repeat(60));
console.log('\n✅ Thread Finder Setup Test Complete!\n');

// If --test-email flag is provided, run end-to-end test
if (process.argv.includes('--test-email')) {
  console.log('\n🔬 Running End-to-End Test...\n');

  const testEmail = {
    subject: 'New Canvas Assignment',
    from: 'noreply@instructure.com',
    body: 'Check Canvas for assignment details. https://canvas.instructure.com/courses/12345/assignments/67890',
    snippet: 'Check Canvas for assignment details...'
  };

  const link = 'https://canvas.instructure.com/courses/12345/assignments/67890';

  processEmailWithLink(testEmail, link)
    .then(result => {
      console.log('  ✅ Test Result:');
      console.log(`     Summary: ${result.summary}`);
      console.log(`     Priority: ${result.priority}`);
      console.log(`     Manual Review: ${result.requiresManualReview}`);
      console.log(`     HPAs: ${result.hpa?.length || 0} actions`);
      if (result.hpa && result.hpa.length > 0) {
        result.hpa.forEach(hpa => console.log(`       - ${hpa}`));
      }
      console.log('');
    })
    .catch(error => {
      console.log('  ❌ Test Failed:');
      console.log(`     Error: ${error.message}`);
      console.log('');
    });
}
