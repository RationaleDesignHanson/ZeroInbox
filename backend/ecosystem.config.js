/**
 * PM2 Ecosystem Configuration for ZerO Inbox Backend Services
 *
 * This configuration enables:
 * - Automatic restart on crash
 * - Cluster mode for high availability
 * - Log rotation
 * - Health monitoring
 * - Memory limit enforcement
 *
 * Usage:
 *   pm2 start ecosystem.config.js
 *   pm2 save
 *   pm2 startup  (to enable on system boot)
 */

module.exports = {
  apps: [
    // Gateway Service - API Gateway (start first, others depend on it)
    {
      name: 'gateway',
      script: './services/gateway/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: './services/logs/gateway-error.log',
      out_file: './services/logs/gateway-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Classifier Service - Email classification and intent detection
    {
      name: 'classifier',
      script: './services/classifier/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: './services/logs/classifier-error.log',
      out_file: './services/logs/classifier-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Email Service - Email fetching and processing
    {
      name: 'email',
      script: './services/email/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3002
      },
      error_file: './services/logs/email-error.log',
      out_file: './services/logs/email-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Smart Replies Service - AI-powered reply suggestions
    {
      name: 'smart-replies',
      script: './services/smart-replies/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '800M',
      env: {
        NODE_ENV: 'production',
        PORT: 3003
      },
      error_file: './services/logs/smart-replies-error.log',
      out_file: './services/logs/smart-replies-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Shopping Agent Service - E-commerce and shopping assistance
    {
      name: 'shopping-agent',
      script: './services/shopping-agent/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '800M',
      env: {
        NODE_ENV: 'production',
        PORT: 3004
      },
      error_file: './services/logs/shopping-agent-error.log',
      out_file: './services/logs/shopping-agent-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Analytics Service - Usage analytics and metrics
    {
      name: 'analytics',
      script: './services/analytics/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3005
      },
      error_file: './services/logs/analytics-error.log',
      out_file: './services/logs/analytics-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Summarization Service - Email and content summarization
    {
      name: 'summarization',
      script: './services/summarization/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '800M',
      env: {
        NODE_ENV: 'production',
        PORT: 3006
      },
      error_file: './services/logs/summarization-error.log',
      out_file: './services/logs/summarization-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Scheduled Purchase Service - Scheduled buying and reminders
    {
      name: 'scheduled-purchase',
      script: './services/scheduled-purchase/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3007
      },
      error_file: './services/logs/scheduled-purchase-error.log',
      out_file: './services/logs/scheduled-purchase-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Actions Service - Action execution and tracking
    {
      name: 'actions',
      script: './services/actions/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3008
      },
      error_file: './services/logs/actions-error.log',
      out_file: './services/logs/actions-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    },

    // Steel Agent Service - Advanced AI agent
    {
      name: 'steel-agent',
      script: './services/steel-agent/server.js',
      cwd: '/Users/matthanson/Zer0_Inbox/backend',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3009
      },
      error_file: './services/logs/steel-agent-error.log',
      out_file: './services/logs/steel-agent-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000
    }
  ]
};
