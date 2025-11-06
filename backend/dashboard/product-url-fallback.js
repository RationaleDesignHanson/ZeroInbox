/**
 * Product URL Fallback System
 * Provides backup URLs when primary URLs fail
 * Can be integrated into shopping-cart.html demo
 */

const PRODUCT_FALLBACKS = {
    'apple': {
        primary: [
            {
                name: 'MacBook Air M2',
                url: 'https://www.apple.com/shop/buy-mac/macbook-air',
                price: 1199.99,
                category: 'Electronics'
            },
            {
                name: 'iPad Pro',
                url: 'https://www.apple.com/ipad-pro/',
                price: 999.99,
                category: 'Electronics'
            }
        ],
        fallback: 'https://www.apple.com/store'
    },
    'amazon': {
        primary: [
            {
                name: 'Fire TV Stick 4K',
                url: 'https://www.amazon.com/dp/B0BP9SNVH9',
                asin: 'B0BP9SNVH9',
                price: 49.99,
                category: 'Electronics'
            },
            {
                name: 'Echo Dot (5th Gen)',
                url: 'https://www.amazon.com/dp/B09B8V1LZ3',
                asin: 'B09B8V1LZ3',
                price: 49.99,
                category: 'Smart Home'
            },
            {
                name: 'Kindle Paperwhite',
                url: 'https://www.amazon.com/dp/B08KTZ8249',
                asin: 'B08KTZ8249',
                price: 139.99,
                category: 'Electronics'
            }
        ],
        fallback: 'https://www.amazon.com'
    },
    'target': {
        primary: [
            {
                name: 'AirPods Pro (2nd Gen)',
                url: 'https://www.target.com/p/airpods-pro-2nd-generation/-/A-85978622',
                sku: 'A-85978622',
                price: 249.99,
                category: 'Audio'
            },
            {
                name: 'Nintendo Switch OLED',
                url: 'https://www.target.com/p/nintendo-switch-oled-model-white/-/A-83887445',
                sku: 'A-83887445',
                price: 349.99,
                category: 'Gaming'
            }
        ],
        fallback: 'https://www.target.com'
    },
    'bestbuy': {
        primary: [
            {
                name: 'Apple AirTag 4 Pack',
                url: 'https://www.bestbuy.com/site/apple-airtag-4-pack/6461348.p',
                sku: '6461348',
                price: 99.99,
                category: 'Accessories'
            },
            {
                name: 'Sony WH-1000XM5',
                url: 'https://www.bestbuy.com/site/sony-wh-1000xm5-wireless-noise-canceling-over-the-ear-headphones-black/6505727.p',
                sku: '6505727',
                price: 399.99,
                category: 'Audio'
            }
        ],
        fallback: 'https://www.bestbuy.com'
    },
    'walmart': {
        primary: [
            {
                name: 'Duracell AA Batteries 20pk',
                url: 'https://www.walmart.com/ip/10535009',
                sku: '10535009',
                price: 19.97,
                category: 'Household'
            },
            {
                name: 'Great Value Paper Towels',
                url: 'https://www.walmart.com/ip/15724956',
                sku: '15724956',
                price: 12.98,
                category: 'Household'
            }
        ],
        fallback: 'https://www.walmart.com'
    }
};

/**
 * Get product URL with automatic fallback
 * @param {string} merchant - Merchant name (lowercase)
 * @param {number} index - Product index (0-based)
 * @returns {object} Product with URL and metadata
 */
function getProductWithFallback(merchant, index = 0) {
    const merchantData = PRODUCT_FALLBACKS[merchant.toLowerCase()];

    if (!merchantData) {
        throw new Error(`Unknown merchant: ${merchant}`);
    }

    // Try to get the requested product index
    if (index < merchantData.primary.length) {
        return {
            ...merchantData.primary[index],
            merchant: merchant,
            hasFallback: true,
            fallbackUrl: merchantData.fallback
        };
    }

    // If index out of range, return first product
    return {
        ...merchantData.primary[0],
        merchant: merchant,
        hasFallback: true,
        fallbackUrl: merchantData.fallback
    };
}

/**
 * Get all available products for a merchant
 * @param {string} merchant - Merchant name
 * @returns {array} Array of products
 */
function getAllProducts(merchant) {
    const merchantData = PRODUCT_FALLBACKS[merchant.toLowerCase()];

    if (!merchantData) {
        return [];
    }

    return merchantData.primary.map(product => ({
        ...product,
        merchant: merchant,
        hasFallback: true,
        fallbackUrl: merchantData.fallback
    }));
}

/**
 * Get random product for demo
 * @returns {object} Random product with fallback
 */
function getRandomProduct() {
    const merchants = Object.keys(PRODUCT_FALLBACKS);
    const randomMerchant = merchants[Math.floor(Math.random() * merchants.length)];
    const products = PRODUCT_FALLBACKS[randomMerchant].primary;
    const randomProduct = products[Math.floor(Math.random() * products.length)];

    return {
        ...randomProduct,
        merchant: randomMerchant,
        hasFallback: true,
        fallbackUrl: PRODUCT_FALLBACKS[randomMerchant].fallback
    };
}

/**
 * Handle failed product URL - return fallback
 * @param {string} failedUrl - The URL that failed
 * @param {string} merchant - Merchant name
 * @returns {string} Fallback URL
 */
function handleFailedUrl(failedUrl, merchant) {
    console.warn(`⚠️ Product URL failed: ${failedUrl}`);

    const merchantData = PRODUCT_FALLBACKS[merchant.toLowerCase()];

    if (!merchantData) {
        console.error(`❌ No fallback available for merchant: ${merchant}`);
        return null;
    }

    console.log(`✅ Using fallback: ${merchantData.fallback}`);
    return merchantData.fallback;
}

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        PRODUCT_FALLBACKS,
        getProductWithFallback,
        getAllProducts,
        getRandomProduct,
        handleFailedUrl
    };
}

// Export for browser
if (typeof window !== 'undefined') {
    window.ProductFallbackSystem = {
        PRODUCT_FALLBACKS,
        getProductWithFallback,
        getAllProducts,
        getRandomProduct,
        handleFailedUrl
    };
}
