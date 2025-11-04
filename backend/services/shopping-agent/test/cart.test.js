/**
 * Shopping Agent - Cart Service Unit Tests
 * Tests all cart API endpoints with success cases, validation, and edge cases
 */

const request = require('supertest');
const express = require('express');
const cartRouter = require('../routes/cart');

// Create test app
const app = express();
app.use(express.json());
app.use('/cart', cartRouter);

describe('Shopping Agent - Cart API', () => {

  // Test user ID for consistency
  const TEST_USER_ID = 'test-user-123';

  // Clear cart before each test
  beforeEach(async () => {
    await request(app)
      .delete(`/cart/${TEST_USER_ID}`)
      .expect(200);
  });

  describe('POST /cart/add', () => {
    it('should add item to cart successfully', async () => {
      const item = {
        userId: TEST_USER_ID,
        productName: 'Test Product',
        price: 29.99,
        quantity: 1
      };

      const res = await request(app)
        .post('/cart/add')
        .send(item)
        .expect(200);

      expect(res.body).toHaveProperty('item');
      expect(res.body.item).toMatchObject({
        productName: 'Test Product',
        price: 29.99,
        quantity: 1
      });
      expect(res.body.item).toHaveProperty('id');
      expect(res.body).toHaveProperty('summary');
      expect(res.body.summary.totalItems).toBe(1);
      expect(res.body.summary.totalPrice).toBe(29.99);
    });

    it('should add multiple items to cart', async () => {
      const item1 = {
        userId: TEST_USER_ID,
        productName: 'Product 1',
        price: 10.00,
        quantity: 2
      };

      const item2 = {
        userId: TEST_USER_ID,
        productName: 'Product 2',
        price: 15.50,
        quantity: 1
      };

      // Add first item
      await request(app)
        .post('/cart/add')
        .send(item1)
        .expect(200);

      // Add second item
      const res = await request(app)
        .post('/cart/add')
        .send(item2)
        .expect(200);

      expect(res.body.summary.totalItems).toBe(3); // 2 + 1
      expect(res.body.summary.totalPrice).toBe(35.50); // (10 * 2) + 15.50
    });

    it('should add item with optional fields', async () => {
      const item = {
        userId: TEST_USER_ID,
        productName: 'Product with Options',
        price: 99.99,
        quantity: 1,
        productUrl: 'https://example.com/product',
        imageUrl: 'https://example.com/image.jpg',
        variant: 'Size: Large, Color: Blue'
      };

      const res = await request(app)
        .post('/cart/add')
        .send(item)
        .expect(200);

      expect(res.body.item).toMatchObject({
        productName: 'Product with Options',
        price: 99.99,
        productUrl: 'https://example.com/product',
        imageUrl: 'https://example.com/image.jpg',
        variant: 'Size: Large, Color: Blue'
      });
    });

    it('should fail without userId', async () => {
      const item = {
        productName: 'Test Product',
        price: 29.99
      };

      const res = await request(app)
        .post('/cart/add')
        .send(item)
        .expect(400);

      expect(res.body.error).toMatch(/userId.*required/i);
    });

    it('should fail without productName', async () => {
      const item = {
        userId: TEST_USER_ID,
        price: 29.99
      };

      const res = await request(app)
        .post('/cart/add')
        .send(item)
        .expect(400);

      expect(res.body.error).toMatch(/productName.*required/i);
    });

    it('should fail without price', async () => {
      const item = {
        userId: TEST_USER_ID,
        productName: 'Test Product'
      };

      const res = await request(app)
        .post('/cart/add')
        .send(item)
        .expect(400);

      expect(res.body.error).toMatch(/price.*required/i);
    });

    it('should fail with invalid price', async () => {
      const item = {
        userId: TEST_USER_ID,
        productName: 'Test Product',
        price: -10
      };

      const res = await request(app)
        .post('/cart/add')
        .send(item)
        .expect(400);

      expect(res.body.error).toMatch(/price.*positive/i);
    });

    it('should fail with invalid quantity', async () => {
      const item = {
        userId: TEST_USER_ID,
        productName: 'Test Product',
        price: 29.99,
        quantity: 0
      };

      const res = await request(app)
        .post('/cart/add')
        .send(item)
        .expect(400);

      expect(res.body.error).toMatch(/quantity.*least 1/i);
    });

    it('should default quantity to 1 if not provided', async () => {
      const item = {
        userId: TEST_USER_ID,
        productName: 'Test Product',
        price: 29.99
      };

      const res = await request(app)
        .post('/cart/add')
        .send(item)
        .expect(200);

      expect(res.body.item.quantity).toBe(1);
    });
  });

  describe('GET /cart/:userId', () => {
    it('should return empty cart for new user', async () => {
      const res = await request(app)
        .get(`/cart/${TEST_USER_ID}`)
        .expect(200);

      expect(res.body.cart).toEqual([]);
      expect(res.body.summary.totalItems).toBe(0);
      expect(res.body.summary.totalPrice).toBe(0);
    });

    it('should return cart with items', async () => {
      // Add items
      await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product 1',
          price: 10.00,
          quantity: 2
        });

      await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product 2',
          price: 20.00,
          quantity: 1
        });

      // Get cart
      const res = await request(app)
        .get(`/cart/${TEST_USER_ID}`)
        .expect(200);

      expect(res.body.cart).toHaveLength(2);
      expect(res.body.summary.totalItems).toBe(3);
      expect(res.body.summary.totalPrice).toBe(40.00);
    });

    it('should isolate carts by userId', async () => {
      const USER_1 = 'user-1';
      const USER_2 = 'user-2';

      // Add item to user 1 cart
      await request(app)
        .post('/cart/add')
        .send({
          userId: USER_1,
          productName: 'User 1 Product',
          price: 10.00
        });

      // Add item to user 2 cart
      await request(app)
        .post('/cart/add')
        .send({
          userId: USER_2,
          productName: 'User 2 Product',
          price: 20.00
        });

      // Check user 1 cart
      const res1 = await request(app)
        .get(`/cart/${USER_1}`)
        .expect(200);

      expect(res1.body.cart).toHaveLength(1);
      expect(res1.body.cart[0].productName).toBe('User 1 Product');

      // Check user 2 cart
      const res2 = await request(app)
        .get(`/cart/${USER_2}`)
        .expect(200);

      expect(res2.body.cart).toHaveLength(1);
      expect(res2.body.cart[0].productName).toBe('User 2 Product');
    });
  });

  describe('PATCH /cart/:userId/:itemId', () => {
    let itemId;

    beforeEach(async () => {
      // Add item to cart
      const res = await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Test Product',
          price: 10.00,
          quantity: 1
        });
      itemId = res.body.item.id;
    });

    it('should update item quantity', async () => {
      const res = await request(app)
        .patch(`/cart/${TEST_USER_ID}/${itemId}`)
        .send({ quantity: 5 })
        .expect(200);

      expect(res.body.item.quantity).toBe(5);
      expect(res.body.summary.totalItems).toBe(5);
      expect(res.body.summary.totalPrice).toBe(50.00);
    });

    it('should fail with quantity less than 1', async () => {
      const res = await request(app)
        .patch(`/cart/${TEST_USER_ID}/${itemId}`)
        .send({ quantity: 0 })
        .expect(400);

      expect(res.body.error).toMatch(/quantity.*least 1/i);
    });

    it('should fail with negative quantity', async () => {
      const res = await request(app)
        .patch(`/cart/${TEST_USER_ID}/${itemId}`)
        .send({ quantity: -5 })
        .expect(400);

      expect(res.body.error).toMatch(/quantity.*least 1/i);
    });

    it('should fail with non-existent item', async () => {
      const res = await request(app)
        .patch(`/cart/${TEST_USER_ID}/non-existent-id`)
        .send({ quantity: 2 })
        .expect(404);

      expect(res.body.error).toMatch(/not found/i);
    });

    it('should fail without quantity in body', async () => {
      const res = await request(app)
        .patch(`/cart/${TEST_USER_ID}/${itemId}`)
        .send({})
        .expect(400);

      expect(res.body.error).toMatch(/quantity.*required/i);
    });
  });

  describe('DELETE /cart/:userId/:itemId', () => {
    let itemId;

    beforeEach(async () => {
      // Add item to cart
      const res = await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Test Product',
          price: 10.00,
          quantity: 1
        });
      itemId = res.body.item.id;
    });

    it('should remove item from cart', async () => {
      const res = await request(app)
        .delete(`/cart/${TEST_USER_ID}/${itemId}`)
        .expect(200);

      expect(res.body.message).toMatch(/removed/i);
      expect(res.body.summary.totalItems).toBe(0);
      expect(res.body.summary.totalPrice).toBe(0);
    });

    it('should fail with non-existent item', async () => {
      const res = await request(app)
        .delete(`/cart/${TEST_USER_ID}/non-existent-id`)
        .expect(404);

      expect(res.body.error).toMatch(/not found/i);
    });

    it('should only remove specified item', async () => {
      // Add second item
      const res2 = await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product 2',
          price: 20.00
        });

      // Remove first item
      await request(app)
        .delete(`/cart/${TEST_USER_ID}/${itemId}`)
        .expect(200);

      // Check cart still has second item
      const cartRes = await request(app)
        .get(`/cart/${TEST_USER_ID}`)
        .expect(200);

      expect(cartRes.body.cart).toHaveLength(1);
      expect(cartRes.body.cart[0].productName).toBe('Product 2');
    });
  });

  describe('DELETE /cart/:userId', () => {
    beforeEach(async () => {
      // Add multiple items
      await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product 1',
          price: 10.00
        });

      await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product 2',
          price: 20.00
        });
    });

    it('should clear entire cart', async () => {
      const res = await request(app)
        .delete(`/cart/${TEST_USER_ID}`)
        .expect(200);

      expect(res.body.message).toMatch(/cleared/i);

      // Verify cart is empty
      const cartRes = await request(app)
        .get(`/cart/${TEST_USER_ID}`)
        .expect(200);

      expect(cartRes.body.cart).toHaveLength(0);
      expect(cartRes.body.summary.totalItems).toBe(0);
    });

    it('should succeed even if cart is already empty', async () => {
      // Clear cart
      await request(app)
        .delete(`/cart/${TEST_USER_ID}`)
        .expect(200);

      // Clear again
      const res = await request(app)
        .delete(`/cart/${TEST_USER_ID}`)
        .expect(200);

      expect(res.body.message).toMatch(/cleared/i);
    });
  });

  describe('GET /cart/:userId/summary', () => {
    it('should return empty summary for empty cart', async () => {
      const res = await request(app)
        .get(`/cart/${TEST_USER_ID}/summary`)
        .expect(200);

      expect(res.body).toMatchObject({
        totalItems: 0,
        uniqueProducts: 0,
        totalPrice: 0
      });
    });

    it('should calculate correct summary', async () => {
      // Add items with different quantities
      await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product 1',
          price: 10.00,
          quantity: 3
        });

      await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product 2',
          price: 25.50,
          quantity: 2
        });

      const res = await request(app)
        .get(`/cart/${TEST_USER_ID}/summary`)
        .expect(200);

      expect(res.body).toMatchObject({
        totalItems: 5, // 3 + 2
        uniqueProducts: 2,
        totalPrice: 81.00 // (10 * 3) + (25.50 * 2)
      });
    });

    it('should round prices correctly', async () => {
      await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product',
          price: 9.99,
          quantity: 3
        });

      const res = await request(app)
        .get(`/cart/${TEST_USER_ID}/summary`)
        .expect(200);

      expect(res.body.totalPrice).toBe(29.97);
    });
  });

  describe('Edge Cases and Error Handling', () => {
    it('should handle very large quantities', async () => {
      const res = await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Bulk Product',
          price: 1.00,
          quantity: 1000
        })
        .expect(200);

      expect(res.body.item.quantity).toBe(1000);
      expect(res.body.summary.totalItems).toBe(1000);
    });

    it('should handle very high prices', async () => {
      const res = await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Luxury Item',
          price: 999999.99,
          quantity: 1
        })
        .expect(200);

      expect(res.body.item.price).toBe(999999.99);
      expect(res.body.summary.totalPrice).toBe(999999.99);
    });

    it('should handle special characters in product names', async () => {
      const res = await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Product with "Quotes" & <HTML> Tags',
          price: 10.00
        })
        .expect(200);

      expect(res.body.item.productName).toBe('Product with "Quotes" & <HTML> Tags');
    });

    it('should handle malformed JSON', async () => {
      const res = await request(app)
        .post('/cart/add')
        .set('Content-Type', 'application/json')
        .send('{ invalid json }')
        .expect(400);
    });

    it('should handle missing Content-Type header', async () => {
      const res = await request(app)
        .post('/cart/add')
        .send({
          userId: TEST_USER_ID,
          productName: 'Test Product',
          price: 10.00
        })
        .expect(200);

      // Should still work with express.json() middleware
      expect(res.body.item).toBeDefined();
    });
  });
});
