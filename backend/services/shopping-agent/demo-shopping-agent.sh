#!/bin/bash

# Demo script to showcase Shopping Agent AI capabilities
# This demonstrates what happens when real emails come through the system

echo "======================================"
echo "Shopping Agent AI Demo"
echo "======================================"
echo ""

echo "1️⃣  Product Intelligence: Extracting product info from email..."
echo "----------------------------------------"
curl -s -X POST http://localhost:8084/products/resolve \
  -H 'Content-Type: application/json' \
  -d '{
    "emailContent": "Check out these Sony WH-1000XM5 Headphones on sale for 279.99 dollars, originally 399.99! Use code SAVE30 at checkout. Offer expires in 6 hours. Shop now at BestBuy.com",
    "emailSubject": "Flash Sale: Premium Noise Cancelling Headphones"
  }' | python3 -m json.tool

echo ""
echo ""
echo "2️⃣  AI Deal Analysis: Is this a good deal?"
echo "----------------------------------------"
curl -s -X POST http://localhost:8084/products/analyze \
  -H 'Content-Type: application/json' \
  -d '{
    "product": {
      "productName": "Sony WH-1000XM5 Headphones",
      "price": 279.99,
      "originalPrice": 399.99,
      "merchant": "Best Buy",
      "expiresAt": "2024-12-31T23:59:59Z"
    }
  }' | python3 -m json.tool

echo ""
echo ""
echo "3️⃣  Price Comparison: Which deal is better?"
echo "----------------------------------------"
curl -s -X POST http://localhost:8084/products/compare \
  -H 'Content-Type: application/json' \
  -d '{
    "products": [
      {
        "productName": "Sony WH-1000XM5 Headphones",
        "price": 279.99,
        "merchant": "Best Buy",
        "originalPrice": 399.99
      },
      {
        "productName": "Sony WH-1000XM5 Headphones",
        "price": 299.99,
        "merchant": "Amazon",
        "originalPrice": 399.99
      }
    ]
  }' | python3 -m json.tool

echo ""
echo ""
echo "4️⃣  Cart Management: Adding items to cart..."
echo "----------------------------------------"
curl -s -X POST http://localhost:8084/cart/add \
  -H 'Content-Type: application/json' \
  -d '{
    "userId": "demo-user",
    "emailId": "demo-email-1",
    "productName": "Sony WH-1000XM5 Headphones",
    "price": 279.99,
    "merchant": "Best Buy",
    "productImage": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400",
    "quantity": 1,
    "originalPrice": 399.99,
    "expiresAt": "2024-12-31T23:59:59Z"
  }' | python3 -m json.tool

echo ""
echo ""
echo "5️⃣  Cart Summary: Viewing cart with savings..."
echo "----------------------------------------"
curl -s http://localhost:8084/cart/demo-user/summary | python3 -m json.tool

echo ""
echo ""
echo "6️⃣  Checkout Link Generation: Deep links to merchant..."
echo "----------------------------------------"
curl -s -X POST http://localhost:8084/checkout/generate-link \
  -H 'Content-Type: application/json' \
  -d '{
    "merchant": "Amazon",
    "productUrl": "https://amazon.com/dp/B0BXMWXV6Y",
    "sku": "B0BXMWXV6Y"
  }' | python3 -m json.tool

echo ""
echo ""
echo "======================================"
echo "Demo Complete!"
echo "======================================"
echo ""
echo "This is what happens automatically when:"
echo "  - You authenticate with real Gmail"
echo "  - Shopping emails are classified as 'deal_stacker'"
echo "  - You swipe right to 'Claim Deal'"
echo ""
echo "The AI analyzes deals, compares prices, and helps you shop smarter!"
