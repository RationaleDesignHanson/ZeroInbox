# AI-Powered Shopping Automation

Automate adding products to cart and navigating to checkout using Steel.dev browser automation.

## Overview

The shopping automation feature allows users to:
1. Receive an email with a product link
2. Trigger the "Add to Cart & Checkout" action
3. Watch as AI automatically:
   - Navigates to the product page
   - Finds and clicks "Add to Cart"
   - Navigates to checkout
4. Opens checkout page ready for purchase

## Architecture

### Components

1. **Action Catalog** (`services/actions/action-catalog.js`)
   - New action: `automated_add_to_cart`
   - Action type: `IN_APP` (shows progress modal)
   - Priority: 1 (high priority)
   - Required entities: `productUrl`, `productName`

2. **Shopping Automation Service** (`services/steel-agent/shopping-automation.js`)
   - Platform detection (Amazon, Shopify, Walmart, Target, Etsy, WooCommerce, Generic)
   - Natural language element finding using Steel AI
   - Multi-selector fallback mechanism
   - Screenshot capture for debugging
   - Detailed step tracking

3. **API Endpoint** (`services/steel-agent/server.js`)
   - `POST /api/shopping/add-to-cart` - Main automation endpoint
   - `GET /api/shopping/platform-info` - Platform detection diagnostic

## Supported Platforms

### Fully Supported (Tested)
- **Amazon** (amazon.com, amazon.ca, amazon.co.uk, etc.) - 37.6% market share, 390M monthly visitors
- **Walmart** (walmart.com) - 6.4% market share, 166M monthly visitors
- **Target** (target.com) - With modal confirmation handling
- **Etsy** (etsy.com) - 86M monthly visitors

### Supported (Best-Effort Selectors)
- **eBay** (ebay.com) - 106M monthly visitors
- **Best Buy** (bestbuy.com) - Major electronics retailer
- **Home Depot** (homedepot.com) - Home improvement
- **Lowe's** (lowes.com) - Home improvement
- **Costco** (costco.com) - Wholesale club
- **Wayfair** (wayfair.com) - Furniture and home goods
- **Temu** (temu.com) - 69M monthly visitors, rapidly growing

### Platform Support
- **Shopify stores** (*.myshopify.com and custom domains using Shopify)
- **WooCommerce stores** (WordPress-based e-commerce)

### Generic Support
- Any e-commerce site with standard "Add to Cart" buttons
- AI will attempt to find cart/checkout elements using natural language

## API Usage

### POST /api/shopping/add-to-cart

Automate adding product to cart and navigate to checkout.

**Request:**
```json
{
  "productUrl": "https://www.amazon.com/product/B08N5WRWNW",
  "productName": "Wireless Headphones",
  "userSessionId": "user-123" // optional
}
```

**Success Response (200):**
```json
{
  "success": true,
  "checkoutUrl": "https://www.amazon.com/cart",
  "cartUrl": "https://www.amazon.com/cart",
  "productName": "Wireless Headphones",
  "message": "Successfully added Wireless Headphones to cart!",
  "steps": [
    { "step": "detect_platform", "platform": "Amazon", "success": true },
    { "step": "create_session", "sessionId": "steel_xyz", "success": true },
    { "step": "navigate_to_product", "success": true },
    { "step": "click_add_to_cart", "selector": "Find the Add to Cart button", "success": true },
    { "step": "click_checkout", "selector": "Find the Proceed to checkout button", "success": true },
    { "step": "complete", "success": true, "finalUrl": "https://www.amazon.com/cart" }
  ],
  "screenshots": [
    {
      "step": "product_page",
      "data": "base64_encoded_screenshot",
      "timestamp": "2025-11-05T12:34:56.789Z"
    },
    {
      "step": "added_to_cart",
      "data": "base64_encoded_screenshot",
      "timestamp": "2025-11-05T12:34:58.789Z"
    },
    {
      "step": "checkout_page",
      "data": "base64_encoded_screenshot",
      "timestamp": "2025-11-05T12:35:00.789Z"
    }
  ]
}
```

**Fallback Response (200 with fallbackMode):**
```json
{
  "success": false,
  "error": "Could not find Add to Cart button",
  "fallbackMode": true,
  "productUrl": "https://www.amazon.com/product/B08N5WRWNW",
  "message": "Automation failed. Opening product page for manual checkout.",
  "steps": [...],
  "screenshots": [...]
}
```

**Validation Error (400):**
```json
{
  "error": "Product URL is required",
  "field": "productUrl"
}
```

**Service Unavailable (503):**
```json
{
  "success": false,
  "error": "Steel.dev API not configured",
  "fallbackMode": true,
  "productUrl": "https://www.amazon.com/product/B08N5WRWNW",
  "message": "AI shopping automation temporarily unavailable. Opening product page instead."
}
```

### GET /api/shopping/platform-info

Get platform detection info for diagnostic purposes.

**Request:**
```
GET /api/shopping/platform-info?url=https://www.amazon.com/product/B08N5WRWNW
```

**Response (200):**
```json
{
  "url": "https://www.amazon.com/product/B08N5WRWNW",
  "platform": "Amazon",
  "platformId": "AMAZON",
  "addToCartSelectors": [
    "Find the \"Add to Cart\" button",
    "Find the \"Add to Basket\" button",
    "Find the button with id \"add-to-cart-button\""
  ],
  "checkoutSelectors": [
    "Find the \"Proceed to checkout\" button",
    "Find the cart icon in the navigation",
    "Find the \"Go to Cart\" link"
  ]
}
```

## Testing

### Quick Test (No Steel API Required)

```bash
cd /Users/matthanson/Zer0_Inbox/backend/services/steel-agent

# Start service
node server.js

# In another terminal, run tests
node test-shopping-automation.js
```

Tests verify:
- Health check
- Platform detection (Amazon, Shopify)
- Input validation
- Fallback mode (when Steel API not configured)

### Full Integration Test (Requires Steel API)

Set up Steel.dev API key:
```bash
# Add to backend/.env
STEEL_API_KEY=your_steel_api_key_here
```

Test with real automation:
```bash
curl -X POST http://localhost:8087/api/shopping/add-to-cart \
  -H "Content-Type: application/json" \
  -d '{
    "productUrl": "https://www.amazon.com/product/B08N5WRWNW",
    "productName": "Test Product",
    "userSessionId": "test-123"
  }'
```

## iOS Integration

### Action Flow

1. **User receives email** with product link
2. **Classifier extracts** `productUrl` and `productName` entities
3. **Action catalog** suggests `automated_add_to_cart` action
4. **User taps action** → iOS shows progress modal
5. **iOS calls backend** → `POST /api/shopping/add-to-cart`
6. **Backend automates** cart addition with Steel
7. **Backend returns** checkout URL
8. **iOS opens** checkout page in web modal
9. **User completes** purchase manually

### iOS Action Handler Example

```swift
case "automated_add_to_cart":
    // Show progress modal
    showProgressModal(message: "Adding \(productName) to cart...")

    // Call backend
    let response = await callShoppingAutomation(
        productUrl: action.entities.productUrl,
        productName: action.entities.productName
    )

    // Hide progress modal
    hideProgressModal()

    if response.success {
        // Open checkout in web modal
        openWebModal(url: response.checkoutUrl)
        showToast("✓ Added to cart!")
    } else {
        // Fallback: open product page
        openWebModal(url: response.productUrl)
        showToast("Please add to cart manually")
    }
```

## Error Handling

### Graceful Degradation

The system has multiple fallback levels:

1. **Steel API not configured** → Return product URL (503 Service Unavailable)
2. **Platform not recognized** → Use generic selectors
3. **Add to Cart button not found** → Try multiple selectors
4. **Checkout button not found** → Construct cart URL from domain
5. **Automation fails** → Return product URL with fallback flag

All failures result in user being able to complete purchase manually.

### Debugging

Screenshots are captured at each step:
- `product_page` - Product page loaded
- `added_to_cart` - After clicking "Add to Cart"
- `checkout_page` - Final checkout/cart page
- `error` - If automation fails

Access screenshots from response:
```javascript
result.screenshots.forEach(screenshot => {
  console.log(`Step: ${screenshot.step}`);
  // screenshot.data is base64 encoded PNG
  fs.writeFileSync(`${screenshot.step}.png`, screenshot.data, 'base64');
});
```

## Configuration

### Environment Variables

```bash
# Required for automation to work
STEEL_API_KEY=your_steel_api_key_here

# Optional (has defaults)
STEEL_AGENT_PORT=8087
```

### Steel.dev Setup

1. Sign up at https://steel.dev
2. Get API key from dashboard
3. Add to `.env` file
4. Restart steel-agent service

## Platform-Specific Notes

### Amazon
- **Works best** - Well-structured HTML, consistent selectors
- **Handles** - Variations across international Amazon sites
- **Note** - May require login for checkout (user completes)

### Shopify
- **Good support** - Standard Shopify theme structure
- **Note** - Custom themes may vary, generic selectors used as fallback

### Walmart
- **Good support** - Consistent button structure
- **Note** - May show location picker before checkout

### Target
- **Good support** - Well-structured pages
- **Note** - May require store selection

### Etsy
- **Moderate support** - Seller customization affects consistency
- **Note** - Some sellers have custom cart flows

### Generic Sites
- **Best effort** - Uses natural language queries
- **Note** - Success depends on site structure adherence to conventions

## Future Enhancements

### Phase 1 (Current)
- [x] Platform detection
- [x] "Add to Cart" automation
- [x] Navigate to checkout
- [x] Screenshot capture
- [x] Multi-selector fallback

### Phase 2 (Future)
- [ ] Address autofill
- [ ] Payment method selection
- [ ] Apply promo codes automatically
- [ ] Store selector (Target, Walmart)
- [ ] Size/color selection for products with variants

### Phase 3 (Future)
- [ ] Complete checkout automation (with user approval)
- [ ] Save cart for later across emails
- [ ] Price comparison across platforms
- [ ] Track price drops and alert user

## Troubleshooting

### "Could not find Add to Cart button"

**Causes:**
- Site uses non-standard button text/structure
- Site requires selection (size, color) before adding
- Page loaded with JavaScript errors

**Solutions:**
- Check screenshots to see what AI saw
- Add platform-specific selector to `PLATFORMS` config
- Update generic selectors in `shopping-automation.js`

### "Steel.dev API not configured"

**Cause:** Missing `STEEL_API_KEY` in `.env`

**Solution:**
```bash
echo "STEEL_API_KEY=your_key_here" >> /Users/matthanson/Zer0_Inbox/backend/.env
```

### Automation slow

**Causes:**
- CAPTCHA solving (adds 5-10 seconds)
- Page load time
- Multiple selector attempts

**Expected timing:**
- Simple sites: 10-15 seconds
- Sites with CAPTCHA: 20-30 seconds
- Complex sites: 30-45 seconds

## API Rate Limits

Steel.dev has rate limits based on plan:
- **Free tier**: 100 requests/month
- **Pro tier**: 1,000 requests/month
- **Enterprise**: Custom limits

Implement client-side caching to avoid duplicate automation requests.

## Security

- ✅ **Never stores** user credentials
- ✅ **Never accesses** saved payment methods
- ✅ **Reads only** public product pages
- ✅ **User completes** final checkout manually
- ✅ **Sessions isolated** per user/request

## Support

For issues or feature requests:
1. Check screenshots in error response
2. Test with `/api/shopping/platform-info` endpoint
3. Review platform configuration in `shopping-automation.js`
4. Add custom selectors for problematic sites

---

**Version**: 1.0.0
**Last Updated**: November 5, 2025
**Dependencies**: Steel.dev API, Express.js, steel-client.js
