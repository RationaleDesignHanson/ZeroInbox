const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 8080;

// Serve privacy and terms HTML
app.get('/privacy.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'privacy.html'));
});

app.get('/terms.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'terms.html'));
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Zero Inbox Legal Pages',
    endpoints: {
      privacy: '/privacy.html',
      terms: '/terms.html'
    }
  });
});

app.listen(PORT, () => {
  console.log(`Legal pages server running on port ${PORT}`);
});
