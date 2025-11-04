const express = require('express');
const router = express.Router();
const OpenAI = require('openai');
const axios = require('axios');
const cheerio = require('cheerio');
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'shopping-agent-products' },
  transports: [new winston.transports.Console()]
});

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

/**
 * POST /products/resolve
 * Extract product details from email content/URL using OpenAI
 * Body: { emailContent, productUrl?, emailId? }
 */
router.post('/resolve', async (req, res) => {
  try {
    const { emailContent, productUrl, emailId } = req.body;

    if (!emailContent) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'emailContent is required'
      });
    }

    logger.info('Resolving product from email', { emailId, hasUrl: !!productUrl });

    // Scrape product page if URL provided
    let scrapedData = null;
    if (productUrl) {
      try {
        scrapedData = await scrapeProductPage(productUrl);
        logger.info('Product page scraped successfully', { productUrl });
      } catch (error) {
        logger.warn('Failed to scrape product page', {
          productUrl,
          error: error.message
        });
      }
    }

    // Use OpenAI to extract product details
    const prompt = `Extract product information from this email and optional scraped web data.

Email Content:
${emailContent}

${scrapedData ? `Scraped Product Data:
Title: ${scrapedData.title || 'N/A'}
Price: ${scrapedData.price || 'N/A'}
Description: ${scrapedData.description || 'N/A'}
Image: ${scrapedData.image || 'N/A'}
` : ''}

Extract and return a JSON object with these fields:
{
  "productName": "Clear product name",
  "productUrl": "Direct product URL",
  "price": numeric price value (e.g., 79.99),
  "originalPrice": original price if on sale (null if not on sale),
  "merchant": "Store name (Amazon, Target, etc.)",
  "productImage": "Main product image URL",
  "sku": "Product SKU if available",
  "category": "Product category",
  "expiresAt": "ISO 8601 date if deal expires (null if no expiration)",
  "description": "Brief product description",
  "promoCode": "Promo code if mentioned (null if none)"
}

Return ONLY valid JSON. If information is missing, use null.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a product information extraction assistant. Extract structured product data from emails and web content. Always return valid JSON.'
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3,
      response_format: { type: 'json_object' }
    });

    const productData = JSON.parse(completion.choices[0].message.content);

    logger.info('Product resolved successfully', {
      productName: productData.productName,
      merchant: productData.merchant
    });

    res.json({
      success: true,
      product: productData,
      metadata: {
        emailId,
        scrapedFromWeb: !!scrapedData,
        confidence: calculateConfidence(productData)
      }
    });

  } catch (error) {
    logger.error('Error resolving product', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * POST /products/compare
 * AI-powered price comparison across multiple product items
 * Body: { products: [{ productName, price, merchant, emailId }] }
 */
router.post('/compare', async (req, res) => {
  try {
    const { products } = req.body;

    if (!products || !Array.isArray(products) || products.length < 2) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'At least 2 products are required for comparison'
      });
    }

    logger.info('Comparing products', { productCount: products.length });

    const prompt = `Compare these products and provide shopping recommendations:

Products:
${products.map((p, i) => `
${i + 1}. ${p.productName}
   Price: $${p.price}
   Original Price: ${p.originalPrice ? '$' + p.originalPrice : 'N/A'}
   Merchant: ${p.merchant}
   Expires: ${p.expiresAt || 'No expiration'}
`).join('\n')}

Provide a JSON response with:
{
  "bestDeal": {
    "index": 0,
    "reason": "Why this is the best deal"
  },
  "recommendations": "Overall shopping recommendations",
  "priceComparison": [
    {
      "index": 0,
      "effectivePrice": price after discount,
      "savings": amount saved,
      "valueScore": 1-10 rating
    }
  ],
  "warnings": ["Any concerns about deals expiring soon, etc."]
}

Return ONLY valid JSON.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a smart shopping assistant that helps users find the best deals by comparing products across different merchants and emails.'
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.5,
      response_format: { type: 'json_object' }
    });

    const comparison = JSON.parse(completion.choices[0].message.content);

    logger.info('Products compared successfully', {
      bestDealIndex: comparison.bestDeal.index
    });

    res.json({
      success: true,
      comparison,
      products
    });

  } catch (error) {
    logger.error('Error comparing products', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * POST /products/analyze
 * GPT-4 analysis of deal quality
 * Body: { product: { productName, price, originalPrice, merchant, expiresAt } }
 */
router.post('/analyze', async (req, res) => {
  try {
    const { product } = req.body;

    if (!product || !product.productName) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'product object with productName is required'
      });
    }

    logger.info('Analyzing deal', { productName: product.productName });

    const prompt = `Analyze this product deal and provide insights:

Product: ${product.productName}
Current Price: $${product.price}
Original Price: ${product.originalPrice ? '$' + product.originalPrice : 'N/A'}
Merchant: ${product.merchant || 'Unknown'}
Expires: ${product.expiresAt || 'No expiration'}
${product.promoCode ? `Promo Code: ${product.promoCode}` : ''}

Provide a JSON response with:
{
  "dealQuality": "excellent|good|fair|poor",
  "qualityScore": 1-10 rating,
  "priceAnalysis": "Analysis of whether this is a good price",
  "recommendations": {
    "shouldBuy": true/false,
    "urgency": "high|medium|low",
    "reasoning": "Why or why not to buy"
  },
  "marketContext": "General market info about this product category",
  "alternativeSuggestions": ["Alternative products or strategies"],
  "warnings": ["Any concerns or red flags"]
}

Return ONLY valid JSON.`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a product deal analysis expert. Evaluate deals objectively and provide actionable shopping advice.'
        },
        { role: 'user', content: prompt }
      ],
      temperature: 0.5,
      response_format: { type: 'json_object' }
    });

    const analysis = JSON.parse(completion.choices[0].message.content);

    logger.info('Deal analyzed successfully', {
      dealQuality: analysis.dealQuality,
      shouldBuy: analysis.recommendations.shouldBuy
    });

    res.json({
      success: true,
      analysis,
      product
    });

  } catch (error) {
    logger.error('Error analyzing deal', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

/**
 * Helper: Scrape product page for additional data
 */
async function scrapeProductPage(url) {
  try {
    const response = await axios.get(url, {
      timeout: 5000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
      }
    });

    const $ = cheerio.load(response.data);

    // Generic selectors (works for many e-commerce sites)
    const title = $('h1').first().text().trim() ||
                  $('meta[property="og:title"]').attr('content') ||
                  $('title').text().trim();

    const price = $('[itemprop="price"]').attr('content') ||
                  $('.price').first().text().trim() ||
                  $('meta[property="product:price:amount"]').attr('content');

    const image = $('meta[property="og:image"]').attr('content') ||
                  $('[itemprop="image"]').attr('src') ||
                  $('img').first().attr('src');

    const description = $('meta[property="og:description"]').attr('content') ||
                       $('meta[name="description"]').attr('content') ||
                       $('[itemprop="description"]').text().trim();

    return {
      title: title || null,
      price: price ? parseFloat(price.replace(/[^0-9.]/g, '')) : null,
      image: image || null,
      description: description ? description.substring(0, 500) : null
    };

  } catch (error) {
    logger.warn('Scraping failed', { url, error: error.message });
    return null;
  }
}

/**
 * Helper: Calculate confidence score for extracted product data
 */
function calculateConfidence(productData) {
  let score = 0;
  let total = 0;

  const fields = ['productName', 'price', 'merchant', 'productUrl'];
  fields.forEach(field => {
    total++;
    if (productData[field]) score++;
  });

  return parseFloat((score / total).toFixed(2));
}

module.exports = router;
