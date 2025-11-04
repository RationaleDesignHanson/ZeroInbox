/**
 * Saved Mail API Routes
 * Endpoints for user-created email folders
 */

const express = require('express');
const router = express.Router();
const savedMailService = require('../../services/saved-mail/service');
const logger = require('./shared/config/logger');

/**
 * GET /api/saved-mail/folders
 * Get all folders for a user
 */
router.get('/folders', (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({
        error: 'userId is required'
      });
    }

    const folders = savedMailService.getFolders(userId);

    logger.info('Retrieved folders', { userId, count: folders.length });

    res.json({
      success: true,
      folders: folders.map(f => f.toJSON())
    });

  } catch (error) {
    logger.error('Error retrieving folders', { error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve folders'
    });
  }
});

/**
 * GET /api/saved-mail/folders/:id
 * Get a specific folder
 */
router.get('/folders/:id', (req, res) => {
  try {
    const { userId } = req.query;
    const { id } = req.params;

    if (!userId) {
      return res.status(400).json({
        error: 'userId is required'
      });
    }

    const folder = savedMailService.getFolder(userId, id);

    if (!folder) {
      return res.status(404).json({
        error: 'Folder not found'
      });
    }

    res.json({
      success: true,
      folder: folder.toJSON()
    });

  } catch (error) {
    logger.error('Error retrieving folder', { folderId: req.params.id, error: error.message });
    res.status(500).json({
      error: 'Failed to retrieve folder'
    });
  }
});

/**
 * POST /api/saved-mail/folders
 * Create a new folder
 * Body: { userId, name, color? }
 */
router.post('/folders', (req, res) => {
  try {
    const { userId, name, color } = req.body;

    if (!userId || !name) {
      return res.status(400).json({
        error: 'userId and name are required'
      });
    }

    const result = savedMailService.createFolder(userId, { name, color });

    if (!result.success) {
      return res.status(400).json({
        error: result.error
      });
    }

    logger.info('Created folder via API', { userId, folderId: result.folder.id, name });

    res.status(201).json(result);

  } catch (error) {
    logger.error('Error creating folder via API', { error: error.message });
    res.status(500).json({
      error: 'Failed to create folder'
    });
  }
});

/**
 * PATCH /api/saved-mail/folders/:id
 * Update a folder (rename, change color)
 * Body: { userId, name?, color? }
 */
router.patch('/folders/:id', (req, res) => {
  try {
    const { userId, name, color } = req.body;
    const { id } = req.params;

    if (!userId) {
      return res.status(400).json({
        error: 'userId is required'
      });
    }

    if (!name && !color) {
      return res.status(400).json({
        error: 'At least one of name or color must be provided'
      });
    }

    const result = savedMailService.updateFolder(userId, id, { name, color });

    if (!result.success) {
      return res.status(400).json({
        error: result.error
      });
    }

    logger.info('Updated folder via API', { userId, folderId: id });

    res.json(result);

  } catch (error) {
    logger.error('Error updating folder via API', { folderId: req.params.id, error: error.message });
    res.status(500).json({
      error: 'Failed to update folder'
    });
  }
});

/**
 * DELETE /api/saved-mail/folders/:id
 * Delete a folder
 */
router.delete('/folders/:id', (req, res) => {
  try {
    const { userId } = req.query;
    const { id } = req.params;

    if (!userId) {
      return res.status(400).json({
        error: 'userId is required'
      });
    }

    const result = savedMailService.deleteFolder(userId, id);

    if (!result.success) {
      return res.status(400).json({
        error: result.error
      });
    }

    logger.info('Deleted folder via API', { userId, folderId: id });

    res.json(result);

  } catch (error) {
    logger.error('Error deleting folder via API', { folderId: req.params.id, error: error.message });
    res.status(500).json({
      error: 'Failed to delete folder'
    });
  }
});

/**
 * POST /api/saved-mail/folders/:id/emails
 * Add email to folder
 * Body: { userId, emailId }
 */
router.post('/folders/:id/emails', (req, res) => {
  try {
    const { userId, emailId } = req.body;
    const { id } = req.params;

    if (!userId || !emailId) {
      return res.status(400).json({
        error: 'userId and emailId are required'
      });
    }

    const result = savedMailService.addEmailToFolder(userId, id, emailId);

    if (!result.success) {
      return res.status(400).json({
        error: result.error
      });
    }

    logger.info('Added email to folder via API', { userId, folderId: id, emailId });

    res.json(result);

  } catch (error) {
    logger.error('Error adding email to folder via API', {
      folderId: req.params.id,
      error: error.message
    });
    res.status(500).json({
      error: 'Failed to add email to folder'
    });
  }
});

/**
 * DELETE /api/saved-mail/folders/:id/emails/:emailId
 * Remove email from folder
 */
router.delete('/folders/:id/emails/:emailId', (req, res) => {
  try {
    const { userId } = req.query;
    const { id, emailId } = req.params;

    if (!userId) {
      return res.status(400).json({
        error: 'userId is required'
      });
    }

    const result = savedMailService.removeEmailFromFolder(userId, id, emailId);

    if (!result.success) {
      return res.status(400).json({
        error: result.error
      });
    }

    logger.info('Removed email from folder via API', { userId, folderId: id, emailId });

    res.json(result);

  } catch (error) {
    logger.error('Error removing email from folder via API', {
      folderId: req.params.id,
      emailId: req.params.emailId,
      error: error.message
    });
    res.status(500).json({
      error: 'Failed to remove email from folder'
    });
  }
});

/**
 * POST /api/saved-mail/folders/reorder
 * Reorder folders
 * Body: { userId, folderIds: [...] }
 */
router.post('/folders/reorder', (req, res) => {
  try {
    const { userId, folderIds } = req.body;

    if (!userId || !Array.isArray(folderIds)) {
      return res.status(400).json({
        error: 'userId and folderIds array are required'
      });
    }

    const result = savedMailService.reorderFolders(userId, folderIds);

    if (!result.success) {
      return res.status(400).json({
        error: result.error
      });
    }

    logger.info('Reordered folders via API', { userId, count: folderIds.length });

    res.json(result);

  } catch (error) {
    logger.error('Error reordering folders via API', { error: error.message });
    res.status(500).json({
      error: 'Failed to reorder folders'
    });
  }
});

module.exports = router;
