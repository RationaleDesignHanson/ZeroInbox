/**
 * Audit Logger Stub for Dashboard
 * Lightweight console logging for dashboard authentication events
 */

function logAuditEvent(event, details = {}, req = null) {
  const timestamp = new Date().toISOString();
  const ip = req?.headers?.['x-forwarded-for'] || req?.connection?.remoteAddress || 'unknown';

  console.log(JSON.stringify({
    timestamp,
    event,
    details,
    ip,
    userAgent: req?.headers?.['user-agent']
  }));
}

function auditSessionCreated(sessionId, accessLevel, email, req) {
  logAuditEvent('auth.session_created', {
    sessionId: sessionId.substring(0, 8) + '...',
    accessLevel,
    email
  }, req);
}

function auditSessionExpired(sessionId, req) {
  logAuditEvent('auth.session_expired', {
    sessionId: sessionId ? sessionId.substring(0, 8) + '...' : 'unknown'
  }, req);
}

function auditAccessDenied(resource, reason, req) {
  logAuditEvent('auth.access_denied', {
    resource,
    reason
  }, req);
}

function auditAdminAction(action, details, req) {
  logAuditEvent('auth.admin_action', {
    action,
    ...details
  }, req);
}

module.exports = {
  logAuditEvent,
  auditSessionCreated,
  auditSessionExpired,
  auditAccessDenied,
  auditAdminAction
};
