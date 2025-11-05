/**
 * Test Script for Shopping Automation API
 *
 * Tests the new shopping automation endpoints without requiring Steel API
 * Verifies endpoint structure, validation, and fallback behavior
 */

const http = require('http');

const STEEL_AGENT_PORT = process.env.STEEL_AGENT_PORT || 8087;
const BASE_URL = `http://localhost:${STEEL_AGENT_PORT}`;

/**
 * Make HTTP request
 */
function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);

    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const response = JSON.parse(body);
          resolve({ status: res.statusCode, data: response });
        } catch (error) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

/**
 * Test cases
 */
async function runTests() {
  console.log('\n🧪 Testing Shopping Automation API\n');
  console.log('=' .repeat(60));

  let passed = 0;
  let failed = 0;

  // Test 1: Health check
  try {
    console.log('\n[Test 1] Health Check');
    const response = await makeRequest('GET', '/health');

    if (response.status === 200 && response.data.service === 'steel-agent-service') {
      console.log('✓ Health check passed');
      console.log(`  Status: ${response.data.status}`);
      console.log(`  Steel API: ${response.data.steelApiConfigured ? 'Configured' : 'Not configured'}`);
      passed++;
    } else {
      console.log('✗ Health check failed');
      console.log(`  Status: ${response.status}`);
      failed++;
    }
  } catch (error) {
    console.log('✗ Health check failed:', error.message);
    failed++;
  }

  // Test 2: Platform detection
  try {
    console.log('\n[Test 2] Platform Detection - Amazon');
    const response = await makeRequest(
      'GET',
      '/api/shopping/platform-info?url=https://www.amazon.com/product/B08N5WRWNW'
    );

    if (response.status === 200 && response.data.platform === 'Amazon') {
      console.log('✓ Amazon detection passed');
      console.log(`  Platform ID: ${response.data.platformId}`);
      console.log(`  Add to Cart selectors: ${response.data.addToCartSelectors.length} defined`);
      passed++;
    } else {
      console.log('✗ Amazon detection failed');
      console.log(`  Status: ${response.status}`);
      console.log(`  Data:`, response.data);
      failed++;
    }
  } catch (error) {
    console.log('✗ Platform detection failed:', error.message);
    failed++;
  }

  // Test 3: Platform detection - Shopify
  try {
    console.log('\n[Test 3] Platform Detection - Shopify');
    const response = await makeRequest(
      'GET',
      '/api/shopping/platform-info?url=https://example.myshopify.com/products/cool-shirt'
    );

    if (response.status === 200 && response.data.platform === 'Shopify') {
      console.log('✓ Shopify detection passed');
      console.log(`  Platform ID: ${response.data.platformId}`);
      passed++;
    } else {
      console.log('✗ Shopify detection failed');
      console.log(`  Expected: Shopify, Got: ${response.data.platform}`);
      failed++;
    }
  } catch (error) {
    console.log('✗ Platform detection failed:', error.message);
    failed++;
  }

  // Test 4: Missing URL parameter
  try {
    console.log('\n[Test 4] Platform Info - Missing URL');
    const response = await makeRequest('GET', '/api/shopping/platform-info');

    if (response.status === 400 && response.data.error) {
      console.log('✓ Validation error returned correctly');
      console.log(`  Error: ${response.data.error}`);
      passed++;
    } else {
      console.log('✗ Should have returned 400 error');
      failed++;
    }
  } catch (error) {
    console.log('✗ Test failed:', error.message);
    failed++;
  }

  // Test 5: Add to Cart - Missing productUrl
  try {
    console.log('\n[Test 5] Add to Cart - Missing productUrl');
    const response = await makeRequest('POST', '/api/shopping/add-to-cart', {
      productName: 'Cool Product'
    });

    if (response.status === 400 && response.data.field === 'productUrl') {
      console.log('✓ Validation error returned correctly');
      console.log(`  Error: ${response.data.error}`);
      passed++;
    } else {
      console.log('✗ Should have returned 400 error for missing productUrl');
      failed++;
    }
  } catch (error) {
    console.log('✗ Test failed:', error.message);
    failed++;
  }

  // Test 6: Add to Cart - Missing productName
  try {
    console.log('\n[Test 6] Add to Cart - Missing productName');
    const response = await makeRequest('POST', '/api/shopping/add-to-cart', {
      productUrl: 'https://www.amazon.com/product/123'
    });

    if (response.status === 400 && response.data.field === 'productName') {
      console.log('✓ Validation error returned correctly');
      console.log(`  Error: ${response.data.error}`);
      passed++;
    } else {
      console.log('✗ Should have returned 400 error for missing productName');
      failed++;
    }
  } catch (error) {
    console.log('✗ Test failed:', error.message);
    failed++;
  }

  // Test 7: Add to Cart - No Steel API (fallback mode)
  try {
    console.log('\n[Test 7] Add to Cart - Fallback Mode (No Steel API)');
    const response = await makeRequest('POST', '/api/shopping/add-to-cart', {
      productUrl: 'https://www.amazon.com/product/B08N5WRWNW',
      productName: 'Wireless Headphones',
      userSessionId: 'test-user-123'
    });

    // Should return 503 or 200 with fallbackMode: true
    if ((response.status === 503 || response.status === 200) && response.data.fallbackMode) {
      console.log('✓ Fallback mode activated correctly');
      console.log(`  Status: ${response.status}`);
      console.log(`  Message: ${response.data.message}`);
      console.log(`  Product URL provided: ${!!response.data.productUrl}`);
      passed++;
    } else {
      console.log('✗ Fallback mode not activated correctly');
      console.log(`  Status: ${response.status}`);
      console.log(`  Data:`, response.data);
      failed++;
    }
  } catch (error) {
    console.log('✗ Test failed:', error.message);
    failed++;
  }

  // Test Summary
  console.log('\n' + '='.repeat(60));
  console.log('\n📊 Test Results:');
  console.log(`   ✓ Passed: ${passed}`);
  console.log(`   ✗ Failed: ${failed}`);
  console.log(`   Total:  ${passed + failed}`);

  if (failed === 0) {
    console.log('\n🎉 All tests passed!\n');
  } else {
    console.log('\n⚠️  Some tests failed. Review output above.\n');
    process.exit(1);
  }
}

// Check if service is running
async function checkService() {
  try {
    const response = await makeRequest('GET', '/health');
    return response.status === 200;
  } catch (error) {
    return false;
  }
}

// Main execution
(async () => {
  console.log(`\n🔍 Checking if Steel Agent service is running on port ${STEEL_AGENT_PORT}...`);

  const isRunning = await checkService();

  if (!isRunning) {
    console.log(`\n❌ Steel Agent service is not running on port ${STEEL_AGENT_PORT}`);
    console.log('\nPlease start the service first:');
    console.log(`   cd /Users/matthanson/Zer0_Inbox/backend/services/steel-agent`);
    console.log(`   node server.js\n`);
    process.exit(1);
  }

  console.log('✓ Service is running!\n');

  await runTests();
})();
