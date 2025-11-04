#!/usr/bin/env node

/**
 * Safe Service Manager for EmailShortForm Backend
 *
 * PRIMARY CONSTRAINT: Preserve OAuth and email downloading functionality
 *
 * This script provides:
 * 1. Safe service startup/shutdown (preserves tokens and OAuth config)
 * 2. Real-time health monitoring
 * 3. Interactive service management
 * 4. Critical path validation
 *
 * NEVER:
 * - Deletes /data/tokens/ directory or token files
 * - Modifies .env file (especially JWT_SECRET, OAuth credentials)
 * - Kills processes that might be handling OAuth callbacks
 * - Breaks authentication middleware or token refresh logic
 */

require('dotenv').config();
const axios = require('axios');
const { spawn } = require('child_process');
const readline = require('readline');
const fs = require('fs');
const path = require('path');

// ANSI colors
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[36m',
  gray: '\x1b[90m',
  bold: '\x1b[1m'
};

// Service configuration
const SERVICES = [
  {
    name: 'Gateway',
    port: process.env.GATEWAY_PORT || 3001,
    script: 'start',
    critical: true,
    description: 'OAuth endpoints + API routing',
    healthPath: '/health'
  },
  {
    name: 'Email Service',
    port: process.env.EMAIL_SERVICE_PORT || 8081,
    script: 'start:email',
    critical: true,
    description: 'Gmail/Outlook API integration',
    healthPath: '/health'
  },
  {
    name: 'Classifier',
    port: process.env.CLASSIFIER_SERVICE_PORT || 8082,
    script: 'start:classifier',
    critical: true,
    description: 'Intent detection (117 intents)',
    healthPath: '/health'
  },
  {
    name: 'Summarization',
    port: process.env.SUMMARIZATION_SERVICE_PORT || 8083,
    script: 'start:summarization',
    critical: true,
    description: 'AI email summaries',
    healthPath: '/health'
  },
  {
    name: 'Smart Replies',
    port: 8086,
    script: 'start:smart-replies',
    critical: false,
    description: 'AI reply suggestions',
    healthPath: '/health'
  },
  {
    name: 'Scheduled Purchase',
    port: 8085,
    script: 'start:scheduled-purchase',
    critical: false,
    description: 'Scheduled purchase actions',
    healthPath: '/health'
  },
  {
    name: 'Shopping Agent',
    port: 8084,
    script: 'start:shopping-agent',
    critical: false,
    description: 'Shopping assistant',
    healthPath: '/health'
  },
  {
    name: 'Steel Agent',
    port: 8087,
    script: 'start:steel-agent',
    critical: false,
    description: 'Browser automation',
    healthPath: '/health'
  }
];

// Service processes (PID tracking)
const serviceProcesses = new Map();

/**
 * Logging helpers
 */
function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✅ ${message}`, colors.green);
}

function logError(message) {
  log(`❌ ${message}`, colors.red);
}

function logWarning(message) {
  log(`⚠️  ${message}`, colors.yellow);
}

function logInfo(message) {
  log(`ℹ️  ${message}`, colors.blue);
}

function logSection(title) {
  console.log('\n' + '='.repeat(60));
  log(title.toUpperCase(), colors.blue + colors.bold);
  console.log('='.repeat(60));
}

/**
 * Pre-flight safety checks
 */
async function performSafetyChecks() {
  logSection('Pre-Flight Safety Checks');

  let allChecksPassed = true;

  // Check 1: JWT_SECRET configured
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    logError('JWT_SECRET not configured or too short');
    logInfo('  OAuth flow will FAIL without proper JWT_SECRET');
    logInfo('  Generate: node -e "console.log(require(\'crypto\').randomBytes(64).toString(\'hex\'))"');
    allChecksPassed = false;
  } else {
    logSuccess('JWT_SECRET configured');
  }

  // Check 2: Token directory exists and is writable
  const tokenDir = path.join(__dirname, 'data', 'tokens');
  if (!fs.existsSync(tokenDir)) {
    logWarning('Token directory doesn\'t exist, creating...');
    try {
      fs.mkdirSync(tokenDir, { recursive: true });
      logSuccess('Token directory created');
    } catch (error) {
      logError(`Failed to create token directory: ${error.message}`);
      allChecksPassed = false;
    }
  } else {
    logSuccess(`Token directory exists: ${tokenDir}`);
    const tokenFiles = fs.readdirSync(tokenDir).filter(f => f.endsWith('_gmail.json') || f.endsWith('_outlook.json'));
    logInfo(`  Found ${tokenFiles.length} token files`);
  }

  // Check 3: OAuth credentials configured
  if (!process.env.GOOGLE_CLIENT_ID || !process.env.GOOGLE_CLIENT_SECRET) {
    logError('Google OAuth credentials not configured');
    logInfo('  OAuth flow will FAIL without these credentials');
    allChecksPassed = false;
  } else {
    logSuccess('Google OAuth credentials configured');
  }

  // Check 4: .env file exists
  const envPath = path.join(__dirname, '.env');
  if (!fs.existsSync(envPath)) {
    logError('.env file not found');
    allChecksPassed = false;
  } else {
    logSuccess('.env file found');
  }

  // Check 5: Google Cloud credentials (for Vertex AI / Summarization)
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    const credsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if (fs.existsSync(credsPath)) {
      logSuccess('Google Cloud service account configured');
      logInfo(`  Credentials: ${credsPath}`);
    } else {
      logWarning('GOOGLE_APPLICATION_CREDENTIALS path not found');
      logInfo('  Summarization service may fail to call Vertex AI');
    }
  } else {
    logWarning('GOOGLE_APPLICATION_CREDENTIALS not set');
    logInfo('  Summarization will attempt to use default credentials');
    logInfo('  Run: gcloud auth application-default login');
  }

  // Check 6: Critical shared resources
  const criticalFiles = [
    { path: './shared/models/Intent.js', name: 'Intent Taxonomy' },
    { path: './services/actions/action-catalog.js', name: 'Action Catalog' }
  ];

  for (const file of criticalFiles) {
    const fullPath = path.join(__dirname, file.path);
    if (fs.existsSync(fullPath)) {
      logSuccess(`${file.name} exists`);
    } else {
      logError(`${file.name} not found: ${file.path}`);
      allChecksPassed = false;
    }
  }

  console.log('');

  if (!allChecksPassed) {
    logError('Some safety checks failed - OAuth/email flow may not work');
    logInfo('Fix issues above before starting services');
    return false;
  }

  logSuccess('All safety checks passed - ready to start services');
  return true;
}

/**
 * Check service health
 */
async function checkServiceHealth(service) {
  try {
    // Increase timeout for slow-starting services (Shopping Agent, Smart Replies)
    const timeout = (service.port === 8084 || service.port === 8086) ? 10000 : 3000;

    const response = await axios.get(`http://localhost:${service.port}${service.healthPath}`, {
      timeout
    });

    // Accept both 'ok' and 'healthy' as valid status values
    if (response.status === 200 && (response.data.status === 'ok' || response.data.status === 'healthy')) {
      return { healthy: true, response: response.data };
    }

    return { healthy: false, error: 'Unexpected response' };
  } catch (error) {
    return {
      healthy: false,
      error: error.code === 'ECONNREFUSED' ? 'Not running' : error.message
    };
  }
}

/**
 * Get status of all services
 */
async function getServiceStatus() {
  const statuses = [];

  for (const service of SERVICES) {
    const health = await checkServiceHealth(service);
    statuses.push({
      ...service,
      ...health
    });
  }

  return statuses;
}

/**
 * Display service status table
 */
async function displayServiceStatus() {
  const statuses = await getServiceStatus();

  console.log('\n📊 Service Status:\n');
  console.log('┌─────────────────────┬──────┬────────────┬──────────────────────────────┐');
  console.log('│ Service             │ Port │ Status     │ Description                  │');
  console.log('├─────────────────────┼──────┼────────────┼──────────────────────────────┤');

  for (const status of statuses) {
    const name = status.name.padEnd(19);
    const port = String(status.port).padEnd(4);
    const statusText = status.healthy ? 'HEALTHY   ' : 'DOWN      ';
    const statusColor = status.healthy ? colors.green : (status.critical ? colors.red : colors.yellow);
    const desc = status.description.substring(0, 28).padEnd(28);

    console.log(`│ ${name} │ ${port} │ ${statusColor}${statusText}${colors.reset} │ ${desc} │`);
  }

  console.log('└─────────────────────┴──────┴────────────┴──────────────────────────────┘');

  // Critical services check
  const criticalDown = statuses.filter(s => s.critical && !s.healthy);
  if (criticalDown.length > 0) {
    console.log('');
    logError(`${criticalDown.length} critical service(s) down:`);
    criticalDown.forEach(s => log(`  • ${s.name} (port ${s.port})`, colors.red));
  } else {
    console.log('');
    logSuccess('All critical services operational');
  }
}

/**
 * Start a single service
 */
async function startService(service) {
  log(`\nStarting ${service.name}...`, colors.blue);

  // Check if already running
  const health = await checkServiceHealth(service);
  if (health.healthy) {
    logSuccess(`${service.name} is already running`);
    return true;
  }

  // Start service
  try {
    const npmProcess = spawn('npm', ['run', service.script], {
      cwd: __dirname,
      detached: false,
      stdio: ['ignore', 'pipe', 'pipe']
    });

    serviceProcesses.set(service.name, npmProcess);

    // Capture output
    npmProcess.stdout.on('data', (data) => {
      if (process.env.VERBOSE) {
        log(`  [${service.name}] ${data.toString().trim()}`, colors.gray);
      }
    });

    npmProcess.stderr.on('data', (data) => {
      if (process.env.VERBOSE) {
        log(`  [${service.name}] ERROR: ${data.toString().trim()}`, colors.red);
      }
    });

    npmProcess.on('exit', (code) => {
      serviceProcesses.delete(service.name);
      if (code !== 0 && code !== null) {
        logError(`${service.name} exited with code ${code}`);
      }
    });

    // Wait for health check (longer for slow-starting services)
    const maxAttempts = (service.port === 8084 || service.port === 8086) ? 15 : 30;
    const waitTime = (service.port === 8084 || service.port === 8086) ? 2000 : 1000;

    for (let i = 0; i < maxAttempts; i++) {
      await new Promise(resolve => setTimeout(resolve, waitTime));
      const health = await checkServiceHealth(service);
      if (health.healthy) {
        logSuccess(`${service.name} is healthy (PID: ${npmProcess.pid})`);
        return true;
      }
    }

    logError(`${service.name} failed to become healthy`);
    npmProcess.kill();
    return false;

  } catch (error) {
    logError(`Failed to start ${service.name}: ${error.message}`);
    return false;
  }
}

/**
 * Start all services
 */
async function startAllServices() {
  logSection('Starting All Services');

  // Safety checks first
  const safetyPassed = await performSafetyChecks();
  if (!safetyPassed) {
    logError('Cannot start services - safety checks failed');
    return false;
  }

  // Start critical services first
  logInfo('\nStarting critical services (OAuth + Email path)...\n');
  const criticalServices = SERVICES.filter(s => s.critical);

  for (const service of criticalServices) {
    const started = await startService(service);
    if (!started) {
      logError('Critical service failed to start - aborting');
      return false;
    }
  }

  logSuccess('\n✅ All critical services running\n');

  // Start optional services
  logInfo('Starting optional services...\n');
  const optionalServices = SERVICES.filter(s => !s.critical);

  for (const service of optionalServices) {
    await startService(service);
  }

  console.log('');
  logSuccess('Service startup complete');

  await displayServiceStatus();
  return true;
}

/**
 * Stop a single service
 */
async function stopService(service) {
  log(`\nStopping ${service.name}...`, colors.blue);

  const process = serviceProcesses.get(service.name);
  if (process) {
    process.kill('SIGTERM'); // Graceful shutdown
    serviceProcesses.delete(service.name);

    // Wait a moment to confirm shutdown
    await new Promise(resolve => setTimeout(resolve, 2000));

    const health = await checkServiceHealth(service);
    if (!health.healthy) {
      logSuccess(`${service.name} stopped`);
      return true;
    } else {
      logWarning(`${service.name} still running after SIGTERM, forcing...`);
      process.kill('SIGKILL');
      return true;
    }
  } else {
    logWarning(`${service.name} not managed by this process`);
    return false;
  }
}

/**
 * Stop all services
 */
async function stopAllServices() {
  logSection('Stopping All Services');

  // Stop in reverse order (optional services first, then critical)
  const services = [...SERVICES].reverse();

  for (const service of services) {
    await stopService(service);
  }

  logSuccess('\nAll services stopped');
}

/**
 * Validate critical path (OAuth + Email flow)
 */
async function validateCriticalPath() {
  logSection('Critical Path Validation');

  logInfo('Testing OAuth and Email endpoints...\n');

  // Test 1: Gateway health
  const gatewayHealth = await checkServiceHealth(SERVICES[0]);
  if (gatewayHealth.healthy) {
    logSuccess('Gateway is healthy');
  } else {
    logError('Gateway is down - OAuth flow will FAIL');
    return false;
  }

  // Test 2: OAuth endpoints exist
  try {
    const response = await axios.get('http://localhost:3001/api/auth/gmail', {
      maxRedirects: 0,
      validateStatus: (status) => status >= 200 && status < 400
    });
    if (response.status === 200 || response.status === 302) {
      logSuccess('OAuth initiation endpoint working');
    } else {
      logError('OAuth initiation endpoint failed');
      return false;
    }
  } catch (error) {
    logError(`OAuth initiation endpoint failed: ${error.message}`);
    return false;
  }

  // Test 3: Email Service health
  const emailHealth = await checkServiceHealth(SERVICES[1]);
  if (emailHealth.healthy) {
    logSuccess('Email Service is healthy');
  } else {
    logError('Email Service is down - email fetching will FAIL');
    return false;
  }

  // Test 4: Classifier health
  const classifierHealth = await checkServiceHealth(SERVICES[2]);
  if (classifierHealth.healthy) {
    logSuccess('Classifier is healthy');
  } else {
    logError('Classifier is down - email classification will FAIL');
    return false;
  }

  // Test 5: Summarization health
  const summarizationHealth = await checkServiceHealth(SERVICES[3]);
  if (summarizationHealth.healthy) {
    logSuccess('Summarization is healthy');
  } else {
    logError('Summarization is down - email summaries will FAIL');
    return false;
  }

  // Test 6: Token directory accessible
  const tokenDir = path.join(__dirname, 'data', 'tokens');
  if (fs.existsSync(tokenDir)) {
    const tokenFiles = fs.readdirSync(tokenDir);
    logSuccess(`Token directory accessible (${tokenFiles.length} files)`);
  } else {
    logError('Token directory not found - OAuth tokens cannot be stored');
    return false;
  }

  console.log('');
  logSuccess('✅ Critical path validation passed');
  logInfo('   OAuth and email downloading functionality is operational');

  return true;
}

/**
 * Interactive menu
 */
async function showMenu() {
  console.clear();
  logSection('EmailShortForm Service Manager');
  console.log('\nSafe service management with OAuth/email preservation\n');

  console.log('1. Start all services');
  console.log('2. Stop all services');
  console.log('3. View service status');
  console.log('4. Validate critical path (OAuth + Email)');
  console.log('5. Start individual service');
  console.log('6. Stop individual service');
  console.log('7. Run full system health check');
  console.log('8. Monitor services (real-time)');
  console.log('9. Exit');
  console.log('');
  console.log('Choose an option (1-9): ');
}

/**
 * Monitor services in real-time
 */
async function monitorServices() {
  logSection('Real-time Service Monitoring');
  logInfo('Press Ctrl+C to stop monitoring\n');

  const interval = setInterval(async () => {
    console.clear();
    logSection('Real-time Service Monitoring');
    await displayServiceStatus();
    console.log('\nRefreshing every 5 seconds... (Ctrl+C to stop)');
  }, 5000);

  // Display immediately
  await displayServiceStatus();
  console.log('\nRefreshing every 5 seconds... (Ctrl+C to stop)');

  // Handle Ctrl+C
  process.on('SIGINT', () => {
    clearInterval(interval);
    console.log('\n\nStopped monitoring');
    process.exit(0);
  });
}

/**
 * Main CLI
 */
async function main() {
  const args = process.argv.slice(2);

  // Command-line mode
  if (args.length > 0) {
    const command = args[0];

    switch (command) {
      case 'start':
        await startAllServices();
        break;
      case 'stop':
        await stopAllServices();
        break;
      case 'status':
        await displayServiceStatus();
        break;
      case 'validate':
        await validateCriticalPath();
        break;
      case 'monitor':
        await monitorServices();
        break;
      case 'check':
        await performSafetyChecks();
        break;
      default:
        console.log('Usage: node service-manager.js [start|stop|status|validate|monitor|check]');
        console.log('   or: node service-manager.js (for interactive menu)');
    }
    return;
  }

  // Interactive mode
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  while (true) {
    await showMenu();

    const choice = await new Promise(resolve => {
      rl.question('', resolve);
    });

    switch (choice.trim()) {
      case '1':
        await startAllServices();
        break;
      case '2':
        await stopAllServices();
        break;
      case '3':
        await displayServiceStatus();
        break;
      case '4':
        await validateCriticalPath();
        break;
      case '7':
        console.log('\nRunning full system health check...\n');
        const { spawn } = require('child_process');
        spawn('node', ['test-full-system-health.js'], { stdio: 'inherit' });
        break;
      case '8':
        await monitorServices();
        break;
      case '9':
        console.log('\nGoodbye!\n');
        rl.close();
        process.exit(0);
      default:
        console.log('\nInvalid option. Press Enter to continue...');
    }

    if (choice !== '8') {
      await new Promise(resolve => {
        rl.question('\nPress Enter to continue...', resolve);
      });
    }
  }
}

// Run
if (require.main === module) {
  main().catch(error => {
    logError(`Fatal error: ${error.message}`);
    console.error(error.stack);
    process.exit(1);
  });
}

module.exports = {
  startAllServices,
  stopAllServices,
  getServiceStatus,
  validateCriticalPath,
  performSafetyChecks
};
