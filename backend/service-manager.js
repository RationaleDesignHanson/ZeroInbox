/**
 * Service Manager API
 * Allows web dashboard to restart backend services
 *
 * Run with: node service-manager.js
 */

const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const path = require('path');

const app = express();
const PORT = 9000;

// Enable CORS for dashboard
app.use(cors());
app.use(express.json());

// Service configurations
const SERVICES = {
  3001: { name: 'Gateway', command: 'cd gateway && npm start', dir: 'gateway' },
  8081: { name: 'Email Service', command: 'cd email && npm start', dir: 'email' },
  8082: { name: 'Classifier', command: 'cd classifier && npm start', dir: 'classifier' },
  8083: { name: 'Summarization', command: 'cd summarization && npm start', dir: 'summarization' },
  8084: { name: 'Smart Replies', command: 'cd smart-replies && npm start', dir: 'smart-replies' },
  8085: { name: 'Scheduled Purchase', command: 'cd scheduled-purchase && npm start', dir: 'scheduled-purchase' },
  8086: { name: 'Shopping Agent', command: 'cd shopping-agent && npm start', dir: 'shopping-agent' },
  8087: { name: 'Subscriptions', command: 'cd subscriptions && npm start', dir: 'subscriptions' },
  8090: { name: 'Analytics', command: 'cd analytics && npm start', dir: 'analytics' }
};

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'Service Manager', timestamp: new Date().toISOString() });
});

// Restart service endpoint
app.post('/api/services/restart', async (req, res) => {
  const { port } = req.body;

  if (!port || !SERVICES[port]) {
    return res.status(400).json({
      error: 'Invalid port',
      validPorts: Object.keys(SERVICES).map(Number)
    });
  }

  const service = SERVICES[port];
  console.log(`🔄 Restart requested for ${service.name} on port ${port}`);

  try {
    // Step 1: Kill process on port
    console.log(`   Killing process on port ${port}...`);
    await killProcessOnPort(port);

    // Step 2: Wait a moment for cleanup
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Step 3: Start service in background
    console.log(`   Starting ${service.name}...`);
    const servicesDir = path.join(__dirname, 'services');
    const serviceDir = path.join(servicesDir, service.dir);

    // Start the service in the background using nohup for proper detachment
    const logFile = path.join(__dirname, 'services', 'logs', `${service.dir}.log`);
    const startCommand = `cd "${serviceDir}" && nohup npm start >> "${logFile}" 2>&1 &`;

    exec(startCommand, (error, stdout, stderr) => {
      if (error) {
        console.error(`   ⚠️ Warning starting ${service.name}:`, error.message);
      } else {
        console.log(`   📝 Logs: ${logFile}`);
      }
    });

    console.log(`   ✅ ${service.name} restart initiated`);

    res.json({
      success: true,
      message: `${service.name} restart initiated`,
      port,
      note: 'Service starting in background. Check health in 5-10 seconds.'
    });

  } catch (error) {
    console.error(`   ❌ Error restarting ${service.name}:`, error.message);
    res.status(500).json({
      error: error.message,
      service: service.name,
      port
    });
  }
});

// Kill all services endpoint
app.post('/api/services/kill-all', async (req, res) => {
  console.log('🛑 Kill all services requested');

  const results = [];
  for (const port of Object.keys(SERVICES)) {
    try {
      await killProcessOnPort(port);
      results.push({ port, status: 'killed', service: SERVICES[port].name });
      console.log(`   ✅ Killed ${SERVICES[port].name} on port ${port}`);
    } catch (error) {
      results.push({ port, status: 'error', error: error.message });
      console.log(`   ⚠️ Error killing port ${port}: ${error.message}`);
    }
  }

  res.json({ success: true, results });
});

// Start all services endpoint
app.post('/api/services/start-all', async (req, res) => {
  console.log('🚀 Start all services requested');

  const servicesDir = path.join(__dirname, 'services');
  const results = [];

  for (const [port, service] of Object.entries(SERVICES)) {
    try {
      const serviceDir = path.join(servicesDir, service.dir);
      const logFile = path.join(__dirname, 'services', 'logs', `${service.dir}.log`);
      const startCommand = `cd "${serviceDir}" && nohup npm start >> "${logFile}" 2>&1 &`;

      exec(startCommand, (error) => {
        if (error) {
          console.error(`   ⚠️ Warning starting ${service.name}:`, error.message);
        }
      });

      results.push({ port, status: 'started', service: service.name });
      console.log(`   ✅ Started ${service.name} on port ${port}`);

      // Stagger starts to avoid overwhelming the system
      await new Promise(resolve => setTimeout(resolve, 500));
    } catch (error) {
      results.push({ port, status: 'error', error: error.message });
      console.log(`   ❌ Error starting ${service.name}:`, error.message);
    }
  }

  res.json({
    success: true,
    results,
    note: 'Services starting in background. Check health in 10-15 seconds.'
  });
});

// List all services
app.get('/api/services', (req, res) => {
  res.json({
    services: Object.entries(SERVICES).map(([port, service]) => ({
      port: Number(port),
      name: service.name,
      directory: service.dir
    }))
  });
});

/**
 * Kill process on specific port
 */
function killProcessOnPort(port) {
  return new Promise((resolve, reject) => {
    // Use lsof to find process, then kill it
    const command = `lsof -ti:${port} | xargs kill -9`;

    exec(command, (error, stdout, stderr) => {
      if (error) {
        // If error is "No such process" or empty lsof, that's fine (no process to kill)
        if (stderr.includes('No such process') || !stdout.trim()) {
          resolve(`No process found on port ${port}`);
        } else {
          reject(new Error(`Failed to kill process on port ${port}: ${error.message}`));
        }
      } else {
        resolve(`Killed process on port ${port}`);
      }
    });
  });
}

// Start server
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║                  Service Manager API                       ║
║                   Port ${PORT}                                 ║
╠═══════════════════════════════════════════════════════════╣
║                                                            ║
║  Endpoints:                                                ║
║    POST /api/services/restart                             ║
║    POST /api/services/kill-all                            ║
║    POST /api/services/start-all                           ║
║    GET  /api/services                                     ║
║    GET  /health                                           ║
║                                                            ║
║  Web Dashboard:                                            ║
║    http://localhost:${PORT}                                    ║
║                                                            ║
║  Status: ✅ Ready to manage services                       ║
╚═══════════════════════════════════════════════════════════╝
  `);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n🛑 Service Manager shutting down...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Service Manager shutting down...');
  process.exit(0);
});
