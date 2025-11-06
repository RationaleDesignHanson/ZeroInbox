#!/usr/bin/env node

/**
 * Product URL Health Check Script
 * Tests all product URLs in shopping-cart.html demo
 * Runs periodically to detect broken/outdated links
 */

const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

// Product URLs to test
const PRODUCTS = [
    {
        name: 'iPhone 15 Pro Max',
        merchant: 'Apple',
        url: 'https://www.apple.com/shop/buy-iphone/iphone-15-pro',
        expectedStatus: 200,
        allowRedirect: false
    },
    {
        name: 'Sony WH-1000XM5 Headphones',
        merchant: 'Amazon',
        url: 'https://www.amazon.com/dp/B0BSHF7WHW',
        expectedStatus: 200,
        allowRedirect: true
    },
    {
        name: 'AirPods Pro (2nd Gen)',
        merchant: 'Target',
        url: 'https://www.target.com/p/airpods-pro-2nd-generation/-/A-85978622',
        expectedStatus: 200,
        allowRedirect: true
    },
    {
        name: 'Samsung 55" OLED TV',
        merchant: 'Best Buy',
        url: 'https://www.bestbuy.com/site/samsung-55-class-s90c-oled-4k-uhd-smart-tizen-tv/6536965.p',
        expectedStatus: 200,
        allowRedirect: true
    },
    {
        name: 'Nintendo Switch OLED',
        merchant: 'Walmart',
        url: 'https://www.walmart.com/ip/Nintendo-Switch-OLED-Model-White/1381101779',
        expectedStatus: 200,
        allowRedirect: true
    }
];

// Results
const results = {
    timestamp: new Date().toISOString(),
    totalUrls: PRODUCTS.length,
    working: 0,
    broken: 0,
    warnings: 0,
    tests: []
};

// Test a single URL
function testUrl(product) {
    return new Promise((resolve) => {
        const urlObj = new URL(product.url);
        const protocol = urlObj.protocol === 'https:' ? https : http;

        const options = {
            method: 'HEAD',
            hostname: urlObj.hostname,
            path: urlObj.pathname + urlObj.search,
            headers: {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
            },
            timeout: 10000
        };

        const req = protocol.request(options, (res) => {
            const result = {
                product: product.name,
                merchant: product.merchant,
                url: product.url,
                status: res.statusCode,
                redirect: res.headers.location || null,
                healthy: false,
                issues: []
            };

            // Check status code
            if (res.statusCode === product.expectedStatus) {
                result.healthy = true;
            } else if (res.statusCode >= 300 && res.statusCode < 400) {
                result.issues.push(`Redirects to: ${res.headers.location}`);
                if (!product.allowRedirect) {
                    result.healthy = false;
                } else {
                    result.healthy = true; // Redirects are OK if allowed
                }
            } else if (res.statusCode >= 400) {
                result.issues.push(`HTTP ${res.statusCode} error`);
                result.healthy = false;
            }

            // Warn about redirects even if allowed
            if (res.statusCode >= 300 && res.statusCode < 400) {
                results.warnings++;
            }

            if (result.healthy) {
                results.working++;
            } else {
                results.broken++;
            }

            results.tests.push(result);
            resolve(result);
        });

        req.on('error', (error) => {
            const result = {
                product: product.name,
                merchant: product.merchant,
                url: product.url,
                status: 0,
                redirect: null,
                healthy: false,
                issues: [`Connection error: ${error.message}`]
            };
            results.broken++;
            results.tests.push(result);
            resolve(result);
        });

        req.on('timeout', () => {
            req.destroy();
            const result = {
                product: product.name,
                merchant: product.merchant,
                url: product.url,
                status: 0,
                redirect: null,
                healthy: false,
                issues: ['Request timeout (>10s)']
            };
            results.broken++;
            results.tests.push(result);
            resolve(result);
        });

        req.end();
    });
}

// Run all tests
async function runHealthCheck() {
    console.log('🔍 Product URL Health Check\n');
    console.log(`Testing ${PRODUCTS.length} product URLs...\n`);

    for (const product of PRODUCTS) {
        const result = await testUrl(product);

        const icon = result.healthy ? '✅' : '❌';
        const status = result.status || 'ERR';

        console.log(`${icon} ${result.merchant.padEnd(10)} | ${status} | ${result.product}`);

        if (result.issues.length > 0) {
            result.issues.forEach(issue => {
                console.log(`   └─ ⚠️  ${issue}`);
            });
        }
    }

    // Summary
    console.log('\n' + '─'.repeat(60));
    console.log(`\n📊 Summary:`);
    console.log(`   ✅ Working: ${results.working}/${results.totalUrls}`);
    console.log(`   ❌ Broken:  ${results.broken}/${results.totalUrls}`);
    console.log(`   ⚠️  Warnings: ${results.warnings}`);

    const healthPercentage = Math.round((results.working / results.totalUrls) * 100);
    console.log(`   📈 Health: ${healthPercentage}%`);

    // Save results to JSON
    const outputPath = path.join(__dirname, 'url-health-results.json');
    fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));
    console.log(`\n💾 Results saved to: ${outputPath}`);

    // Exit with error code if any URLs are broken
    if (results.broken > 0) {
        console.log('\n⚠️  Some URLs are broken! Consider updating the demo products.');
        process.exit(1);
    } else {
        console.log('\n✨ All URLs are healthy!');
        process.exit(0);
    }
}

// Run the health check
runHealthCheck().catch(error => {
    console.error('❌ Health check failed:', error);
    process.exit(1);
});
