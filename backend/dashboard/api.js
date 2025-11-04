/**
 * Dashboard API Router
 *
 * Provides REST API endpoints for the web dashboard to interact with services,
 * run tests, and manage the backend infrastructure.
 *
 * Usage:
 *   In gateway/server.js:
 *   const dashboardAPI = require('../dashboard/api');
 *   app.use('/api/dashboard', dashboardAPI);
 */

const express = require('express');
const { exec, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const axios = require('axios');

const router = express.Router();

// Service definitions
const SERVICES = [
    {
        name: 'Gateway',
        port: 3001,
        critical: true,
        healthPath: '/health',
        script: 'start',
        description: 'OAuth endpoints + API routing'
    },
    {
        name: 'Email Service',
        port: 8081,
        critical: true,
        healthPath: '/health',
        script: 'start:email',
        description: 'Gmail/Outlook API integration'
    },
    {
        name: 'Classifier',
        port: 8082,
        critical: true,
        healthPath: '/health',
        script: 'start:classifier',
        description: 'Intent detection (117 intents)'
    },
    {
        name: 'Summarization',
        port: 8083,
        critical: true,
        healthPath: '/health',
        script: 'start:summarization',
        description: 'AI email summaries'
    },
    {
        name: 'Smart Replies',
        port: 8084,
        critical: false,
        healthPath: '/health',
        script: 'start:smart-replies',
        description: 'AI reply suggestions'
    },
    {
        name: 'Scheduled Purchase',
        port: 8085,
        critical: false,
        healthPath: '/health',
        script: 'start:scheduled-purchase',
        description: 'Scheduled purchase actions'
    },
    {
        name: 'Shopping Agent',
        port: 8086,
        critical: false,
        healthPath: '/health',
        script: 'start:shopping-agent',
        description: 'Shopping assistant'
    },
    {
        name: 'Steel Agent',
        port: 8087,
        critical: false,
        healthPath: '/health',
        script: 'start:steel-agent',
        description: 'Browser automation'
    }
];

// ==========================================
// Service Status & Health Endpoints
// ==========================================

/**
 * GET /api/dashboard/status
 * Get status of all services
 */
router.get('/status', async (req, res) => {
    try {
        const servicesStatus = await Promise.all(
            SERVICES.map(async (service) => {
                const health = await checkServiceHealth(service);
                return {
                    ...service,
                    healthy: health.healthy,
                    responseTime: health.responseTime,
                    error: health.error
                };
            })
        );

        const healthyCount = servicesStatus.filter(s => s.healthy).length;
        const totalCount = servicesStatus.length;

        res.json({
            services: servicesStatus,
            summary: {
                healthy: healthyCount,
                total: totalCount,
                status: healthyCount === totalCount ? 'operational' :
                        healthyCount >= totalCount - 2 ? 'degraded' : 'down'
            }
        });
    } catch (error) {
        console.error('Failed to get service status:', error);
        res.status(500).json({ error: 'Failed to get service status' });
    }
});

/**
 * GET /api/dashboard/services/:port/health
 * Get health status of a specific service
 */
router.get('/services/:port/health', async (req, res) => {
    try {
        const port = parseInt(req.params.port);
        const service = SERVICES.find(s => s.port === port);

        if (!service) {
            return res.status(404).json({ error: 'Service not found' });
        }

        const health = await checkServiceHealth(service);

        res.json({
            service: service.name,
            port: service.port,
            ...health
        });
    } catch (error) {
        console.error('Failed to check service health:', error);
        res.status(500).json({ error: 'Failed to check service health' });
    }
});

// ==========================================
// Service Control Endpoints
// ==========================================

/**
 * POST /api/dashboard/services/start-all
 * Start all services
 */
router.post('/services/start-all', async (req, res) => {
    try {
        console.log('Starting all services...');

        // Use service-manager.js to start services
        const result = await runCommand('node service-manager.js start');

        res.json({
            success: true,
            message: 'All services started',
            output: result.stdout
        });
    } catch (error) {
        console.error('Failed to start services:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to start services',
            message: error.message
        });
    }
});

/**
 * POST /api/dashboard/services/stop-all
 * Stop all services
 */
router.post('/services/stop-all', async (req, res) => {
    try {
        console.log('Stopping all services...');

        // Use service-manager.js to stop services
        const result = await runCommand('node service-manager.js stop');

        res.json({
            success: true,
            message: 'All services stopped',
            output: result.stdout
        });
    } catch (error) {
        console.error('Failed to stop services:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to stop services',
            message: error.message
        });
    }
});

/**
 * POST /api/dashboard/services/:port/start
 * Start a specific service
 */
router.post('/services/:port/start', async (req, res) => {
    try {
        const port = parseInt(req.params.port);
        const service = SERVICES.find(s => s.port === port);

        if (!service) {
            return res.status(404).json({ error: 'Service not found' });
        }

        console.log(`Starting ${service.name}...`);

        // Start service using npm script
        const result = await runCommand(`npm run ${service.script}`);

        res.json({
            success: true,
            message: `${service.name} started`,
            service: service.name,
            port: service.port
        });
    } catch (error) {
        console.error(`Failed to start service:`, error);
        res.status(500).json({
            success: false,
            error: 'Failed to start service',
            message: error.message
        });
    }
});

/**
 * POST /api/dashboard/services/:port/stop
 * Stop a specific service
 */
router.post('/services/:port/stop', async (req, res) => {
    try {
        const port = parseInt(req.params.port);
        const service = SERVICES.find(s => s.port === port);

        if (!service) {
            return res.status(404).json({ error: 'Service not found' });
        }

        console.log(`Stopping ${service.name}...`);

        // Kill process on port
        await killProcessOnPort(port);

        res.json({
            success: true,
            message: `${service.name} stopped`,
            service: service.name,
            port: service.port
        });
    } catch (error) {
        console.error(`Failed to stop service:`, error);
        res.status(500).json({
            success: false,
            error: 'Failed to stop service',
            message: error.message
        });
    }
});

/**
 * POST /api/dashboard/services/:port/restart
 * Restart a specific service
 */
router.post('/services/:port/restart', async (req, res) => {
    try {
        const port = parseInt(req.params.port);
        const service = SERVICES.find(s => s.port === port);

        if (!service) {
            return res.status(404).json({ error: 'Service not found' });
        }

        console.log(`Restarting ${service.name}...`);

        // Stop then start
        await killProcessOnPort(port);
        await new Promise(resolve => setTimeout(resolve, 2000)); // Wait 2s
        await runCommand(`npm run ${service.script}`);

        res.json({
            success: true,
            message: `${service.name} restarted`,
            service: service.name,
            port: service.port
        });
    } catch (error) {
        console.error(`Failed to restart service:`, error);
        res.status(500).json({
            success: false,
            error: 'Failed to restart service',
            message: error.message
        });
    }
});

// ==========================================
// Service Logs Endpoints
// ==========================================

/**
 * GET /api/dashboard/services/:port/logs
 * Get recent logs for a service
 */
router.get('/services/:port/logs', async (req, res) => {
    try {
        const port = parseInt(req.params.port);
        const service = SERVICES.find(s => s.port === port);

        if (!service) {
            return res.status(404).json({ error: 'Service not found' });
        }

        // Read logs from temp file if available
        const logPath = `/tmp/${service.name.toLowerCase().replace(/\s+/g, '-')}.log`;

        if (fs.existsSync(logPath)) {
            const logs = fs.readFileSync(logPath, 'utf8')
                .split('\n')
                .slice(-50) // Last 50 lines
                .filter(line => line.trim())
                .map(line => ({
                    timestamp: new Date().toISOString(),
                    message: line
                }));

            res.json({ logs });
        } else {
            res.json({ logs: [] });
        }
    } catch (error) {
        console.error('Failed to get logs:', error);
        res.status(500).json({ error: 'Failed to get logs' });
    }
});

// ==========================================
// System Health Tests Endpoints
// ==========================================

/**
 * POST /api/dashboard/tests/run
 * Run system health tests
 */
router.post('/tests/run', async (req, res) => {
    try {
        console.log('Running system health tests...');

        const result = await runCommand('node test-full-system-health.js');

        res.json({
            success: true,
            output: result.stdout,
            exitCode: result.exitCode
        });
    } catch (error) {
        console.error('Failed to run tests:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to run tests',
            message: error.message
        });
    }
});

/**
 * POST /api/dashboard/validate
 * Validate critical path (OAuth + Email)
 */
router.post('/validate', async (req, res) => {
    try {
        console.log('Validating critical path...');

        const result = await runCommand('node service-manager.js validate');

        res.json({
            success: true,
            output: result.stdout,
            valid: !result.stderr
        });
    } catch (error) {
        console.error('Failed to validate critical path:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to validate critical path',
            message: error.message
        });
    }
});

// ==========================================
// Helper Functions
// ==========================================

/**
 * Check if a service is healthy
 */
async function checkServiceHealth(service) {
    try {
        const startTime = Date.now();
        const response = await axios.get(`http://localhost:${service.port}${service.healthPath}`, {
            timeout: 3000
        });
        const responseTime = Date.now() - startTime;

        if (response.status === 200 &&
            (response.data.status === 'ok' || response.data.status === 'healthy')) {
            return {
                healthy: true,
                responseTime: `${responseTime}ms`
            };
        }

        return {
            healthy: false,
            error: 'Unexpected response',
            responseTime: `${responseTime}ms`
        };
    } catch (error) {
        return {
            healthy: false,
            error: error.code === 'ECONNREFUSED' ? 'Not running' : error.message
        };
    }
}

/**
 * Run a shell command and return output
 */
function runCommand(command) {
    return new Promise((resolve, reject) => {
        exec(command, { cwd: path.join(__dirname, '..') }, (error, stdout, stderr) => {
            if (error && error.code !== 0) {
                reject(error);
            } else {
                resolve({ stdout, stderr, exitCode: error?.code || 0 });
            }
        });
    });
}

/**
 * Kill process running on a port
 */
async function killProcessOnPort(port) {
    try {
        // Find PID on port
        const { stdout } = await runCommand(`lsof -ti:${port}`);
        const pid = stdout.trim();

        if (pid) {
            // Kill process gracefully
            await runCommand(`kill -TERM ${pid}`);
            await new Promise(resolve => setTimeout(resolve, 1000));

            // Force kill if still running
            try {
                await runCommand(`kill -9 ${pid}`);
            } catch (e) {
                // Process already dead
            }
        }
    } catch (error) {
        // No process on port
    }
}

module.exports = router;
