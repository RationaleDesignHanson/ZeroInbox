/**
 * Google Classroom OAuth Helper
 * Run this script to get your Google Classroom access token
 *
 * Usage:
 * 1. Run: node google-classroom-oauth.js
 * 2. Open the URL in your browser
 * 3. Authorize the app
 * 4. Copy the access token to .env file
 */

require('dotenv').config({ path: '../../.env' });
const axios = require('axios');
const express = require('express');

const CLIENT_ID = process.env.GOOGLE_CLASSROOM_CLIENT_ID;
const CLIENT_SECRET = process.env.GOOGLE_CLASSROOM_CLIENT_SECRET;
const REDIRECT_URI = 'http://localhost:8099/oauth/callback';  // Use unique port for OAuth

// OAuth scopes for Google Classroom
const SCOPES = [
  'https://www.googleapis.com/auth/classroom.courses.readonly',
  'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
  'https://www.googleapis.com/auth/classroom.announcements.readonly'
].join(' ');

// Create temporary Express server for OAuth callback
const app = express();
let server;

console.log('\n=== Google Classroom OAuth Setup ===\n');

if (!CLIENT_ID || !CLIENT_SECRET) {
  console.error('❌ Missing Google Classroom credentials in .env file');
  console.error('   Required: GOOGLE_CLASSROOM_CLIENT_ID, GOOGLE_CLASSROOM_CLIENT_SECRET');
  process.exit(1);
}

// Step 1: Generate authorization URL
const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
  `client_id=${CLIENT_ID}&` +
  `redirect_uri=${encodeURIComponent(REDIRECT_URI)}&` +
  `response_type=code&` +
  `scope=${encodeURIComponent(SCOPES)}&` +
  `access_type=offline&` +
  `prompt=consent`;

console.log('✅ OAuth credentials found\n');
console.log('📋 Step 1: Open this URL in your browser:\n');
console.log(`   ${authUrl}\n`);
console.log('📋 Step 2: Authorize the app\n');
console.log('📋 Step 3: You\'ll be redirected back (we\'ll handle it automatically)\n');
console.log('⏳ Waiting for authorization...\n');

// Step 2: Handle OAuth callback
app.get('/oauth/callback', async (req, res) => {
  const { code, error } = req.query;

  if (error) {
    console.error(`❌ Authorization failed: ${error}`);
    res.send(`<h1>Authorization Failed</h1><p>${error}</p>`);
    process.exit(1);
  }

  if (!code) {
    console.error('❌ No authorization code received');
    res.send('<h1>Error</h1><p>No authorization code received</p>');
    process.exit(1);
  }

  try {
    // Exchange authorization code for access token
    console.log('🔄 Exchanging authorization code for access token...\n');

    const tokenResponse = await axios.post('https://oauth2.googleapis.com/token', {
      code,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      redirect_uri: REDIRECT_URI,
      grant_type: 'authorization_code'
    });

    const { access_token, refresh_token, expires_in } = tokenResponse.data;

    console.log('✅ Authorization successful!\n');
    console.log('='.repeat(80));
    console.log('\n📝 Add these to your .env file:\n');
    console.log(`GOOGLE_CLASSROOM_TOKEN=${access_token}`);

    if (refresh_token) {
      console.log(`GOOGLE_CLASSROOM_REFRESH_TOKEN=${refresh_token}`);
    }

    console.log(`\n⏰ Token expires in: ${expires_in} seconds (~${Math.round(expires_in / 60)} minutes)\n`);
    console.log('='.repeat(80));
    console.log('\n💡 Note: Access tokens expire after ~1 hour. Use the refresh token to get new ones.\n');

    res.send(`
      <html>
        <head><title>Authorization Complete</title></head>
        <body style="font-family: Arial; padding: 40px; text-align: center;">
          <h1 style="color: green;">✅ Authorization Successful!</h1>
          <p>You can close this window and return to your terminal.</p>
          <hr style="margin: 40px 0;">
          <h3>Access Token:</h3>
          <textarea readonly style="width: 80%; height: 100px; font-family: monospace; padding: 10px;">${access_token}</textarea>
          ${refresh_token ? `
            <h3>Refresh Token:</h3>
            <textarea readonly style="width: 80%; height: 100px; font-family: monospace; padding: 10px;">${refresh_token}</textarea>
          ` : ''}
          <p style="color: #666; margin-top: 20px;">Token expires in ${Math.round(expires_in / 60)} minutes</p>
        </body>
      </html>
    `);

    // Shutdown server after 5 seconds
    setTimeout(() => {
      console.log('🔒 Shutting down OAuth server...\n');
      server.close();
      process.exit(0);
    }, 5000);

  } catch (error) {
    console.error('❌ Token exchange failed:', error.response?.data || error.message);
    res.send(`<h1>Token Exchange Failed</h1><p>${error.message}</p>`);
    process.exit(1);
  }
});

// Start server
server = app.listen(8099, () => {
  console.log('🚀 OAuth server running on http://localhost:8099\n');
});

// Handle Ctrl+C
process.on('SIGINT', () => {
  console.log('\n\n❌ Authorization cancelled\n');
  server.close();
  process.exit(0);
});
