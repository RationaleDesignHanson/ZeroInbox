#!/usr/bin/env ts-node
import OpenAI from 'openai';
import * as fs from 'fs';

const OPENAI_API_KEY = fs.readFileSync('/Users/matthanson/Desktop/openaik.txt', 'utf8').trim();

console.log('Testing OpenAI API...');
console.log(`API Key: ${OPENAI_API_KEY.substring(0, 20)}...`);

const openai = new OpenAI({ apiKey: OPENAI_API_KEY });

async function test() {
  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // Use cheaper model for testing
      messages: [
        { role: 'user', content: 'Say "API is working!" in JSON format with key "message"' }
      ],
      response_format: { type: 'json_object' },
      max_tokens: 50
    });

    console.log('\n✅ API Test Successful!');
    console.log('Response:', response.choices[0].message.content);
    console.log(`Tokens used: ${response.usage?.total_tokens}`);
    console.log(`Cost: ~$${(response.usage?.total_tokens || 0) / 1000 * 0.0002}`);
  } catch (error: any) {
    console.error('\n❌ API Test Failed');
    console.error('Error:', error.message);
    if (error.code) console.error('Code:', error.code);
    if (error.status) console.error('Status:', error.status);
  }
}

test();
