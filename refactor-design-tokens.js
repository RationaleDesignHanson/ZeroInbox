#!/usr/bin/env node

/**
 * Refactor Hardcoded Design Values → DesignTokens References
 *
 * Systematically replaces hardcoded values in 100+ View files with
 * proper DesignTokens references for maintainability and consistency.
 *
 * Usage:
 *   node refactor-design-tokens.js --dry-run    # Preview changes
 *   node refactor-design-tokens.js --apply      # Apply changes
 *   node refactor-design-tokens.js --stats      # Show statistics only
 *
 * Safety:
 *   - Dry-run by default
 *   - Creates backup before changes
 *   - Only modifies .swift files in Views/
 *   - Preserves formatting and comments
 */

const fs = require('fs');
const path = require('path');

// Configuration
const VIEWS_DIR = path.join(__dirname, 'Zero_ios_2/Zero/Views');
const BACKUP_DIR = path.join(__dirname, '.refactor-backup');
const DRY_RUN = !process.argv.includes('--apply');
const STATS_ONLY = process.argv.includes('--stats');

// Replacement mappings
const OPACITY_MAP = {
  '0.05': 'DesignTokens.Opacity.glassUltraLight',
  '0.1': 'DesignTokens.Opacity.glassLight',
  '0.2': 'DesignTokens.Opacity.overlayLight',
  '0.3': 'DesignTokens.Opacity.overlayMedium',
  '0.5': 'DesignTokens.Opacity.overlayStrong',
  '0.6': 'DesignTokens.Opacity.textDisabled',
  '0.7': 'DesignTokens.Opacity.textSubtle',
  '0.8': 'DesignTokens.Opacity.textTertiary',
  '0.9': 'DesignTokens.Opacity.textSecondary',
  '1.0': 'DesignTokens.Opacity.textPrimary',
  '1': 'DesignTokens.Opacity.textPrimary',
};

const RADIUS_MAP = {
  '4': 'DesignTokens.Radius.minimal',
  '6': 'DesignTokens.Radius.minimal',  // Closest match
  '8': 'DesignTokens.Radius.chip',
  '10': 'DesignTokens.Radius.button',  // Closest match
  '12': 'DesignTokens.Radius.button',
  '16': 'DesignTokens.Radius.card',
  '20': 'DesignTokens.Radius.modal',
  '24': 'DesignTokens.Radius.modal',  // Closest match
  '999': 'DesignTokens.Radius.circle',
};

const PADDING_MAP = {
  '4': 'DesignTokens.Spacing.minimal',
  '6': 'DesignTokens.Spacing.tight',
  '8': 'DesignTokens.Spacing.inline',
  '10': 'DesignTokens.Spacing.element',  // Closest match
  '12': 'DesignTokens.Spacing.element',
  '16': 'DesignTokens.Spacing.component',
  '20': 'DesignTokens.Spacing.section',
  '24': 'DesignTokens.Spacing.card',
  '32': 'DesignTokens.Spacing.card',  // Closest match
};

// Statistics
const stats = {
  filesScanned: 0,
  filesModified: 0,
  opacityReplacements: 0,
  radiusReplacements: 0,
  paddingReplacements: 0,
  errors: [],
};

// Get all Swift files recursively
function getSwiftFiles(dir) {
  let files = [];

  try {
    const items = fs.readdirSync(dir);

    for (const item of items) {
      const fullPath = path.join(dir, item);
      const stat = fs.statSync(fullPath);

      if (stat.isDirectory()) {
        files = files.concat(getSwiftFiles(fullPath));
      } else if (item.endsWith('.swift')) {
        files.push(fullPath);
      }
    }
  } catch (error) {
    stats.errors.push(`Error reading directory ${dir}: ${error.message}`);
  }

  return files;
}

// Refactor opacity values
function refactorOpacity(content) {
  let modified = content;
  let replacements = 0;

  // Pattern: .opacity(0.X) or .opacity(1)
  const opacityPattern = /\.opacity\((\d+(?:\.\d+)?)\)/g;

  modified = modified.replace(opacityPattern, (match, value) => {
    const token = OPACITY_MAP[value];
    if (token) {
      replacements++;
      return `.opacity(${token})`;
    }
    return match;  // Keep original if no mapping
  });

  return { modified, replacements };
}

// Refactor corner radius values
function refactorCornerRadius(content) {
  let modified = content;
  let replacements = 0;

  // Pattern: .cornerRadius(X)
  const radiusPattern = /\.cornerRadius\((\d+)\)/g;

  modified = modified.replace(radiusPattern, (match, value) => {
    const token = RADIUS_MAP[value];
    if (token) {
      replacements++;
      return `.cornerRadius(${token})`;
    }
    return match;  // Keep original if no mapping
  });

  return { modified, replacements };
}

// Refactor padding values
function refactorPadding(content) {
  let modified = content;
  let replacements = 0;

  // Pattern: .padding(X) where X is a number (not .horizontal, .vertical, etc.)
  const paddingPattern = /\.padding\((\d+)\)/g;

  modified = modified.replace(paddingPattern, (match, value) => {
    const token = PADDING_MAP[value];
    if (token) {
      replacements++;
      return `.padding(${token})`;
    }
    return match;  // Keep original if no mapping
  });

  return { modified, replacements };
}

// Process a single file
function processFile(filePath) {
  try {
    stats.filesScanned++;

    const originalContent = fs.readFileSync(filePath, 'utf8');
    let modifiedContent = originalContent;
    let totalReplacements = 0;

    // Apply refactorings
    const { modified: afterOpacity, replacements: opacityCount } = refactorOpacity(modifiedContent);
    modifiedContent = afterOpacity;
    stats.opacityReplacements += opacityCount;
    totalReplacements += opacityCount;

    const { modified: afterRadius, replacements: radiusCount } = refactorCornerRadius(modifiedContent);
    modifiedContent = afterRadius;
    stats.radiusReplacements += radiusCount;
    totalReplacements += radiusCount;

    const { modified: afterPadding, replacements: paddingCount } = refactorPadding(modifiedContent);
    modifiedContent = afterPadding;
    stats.paddingReplacements += paddingCount;
    totalReplacements += paddingCount;

    // Write changes if any
    if (totalReplacements > 0) {
      stats.filesModified++;

      if (!DRY_RUN && !STATS_ONLY) {
        fs.writeFileSync(filePath, modifiedContent, 'utf8');
      }

      return {
        path: filePath,
        replacements: totalReplacements,
        opacity: opacityCount,
        radius: radiusCount,
        padding: paddingCount,
      };
    }

    return null;
  } catch (error) {
    stats.errors.push(`Error processing ${filePath}: ${error.message}`);
    return null;
  }
}

// Create backup of Views directory
function createBackup() {
  if (DRY_RUN || STATS_ONLY) return;

  console.log('📦 Creating backup...');

  try {
    if (fs.existsSync(BACKUP_DIR)) {
      fs.rmSync(BACKUP_DIR, { recursive: true });
    }

    // Copy Views directory
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
    copyDir(VIEWS_DIR, path.join(BACKUP_DIR, 'Views'));

    console.log(`✅ Backup created: ${BACKUP_DIR}\n`);
  } catch (error) {
    console.error(`❌ Backup failed: ${error.message}`);
    process.exit(1);
  }
}

// Recursive directory copy
function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  const entries = fs.readdirSync(src);

  for (const entry of entries) {
    const srcPath = path.join(src, entry);
    const destPath = path.join(dest, entry);
    const stat = fs.statSync(srcPath);

    if (stat.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

// Main execution
function main() {
  console.log('🔨 Design Token Refactoring Tool\n');
  console.log(`Mode: ${DRY_RUN ? '🔍 DRY RUN (preview only)' : '✅ APPLY CHANGES'}`);
  console.log(`Directory: ${VIEWS_DIR}\n`);

  // Check if Views directory exists
  if (!fs.existsSync(VIEWS_DIR)) {
    console.error(`❌ Views directory not found: ${VIEWS_DIR}`);
    process.exit(1);
  }

  // Create backup before making changes
  if (!STATS_ONLY) {
    createBackup();
  }

  // Get all Swift files
  console.log('📁 Scanning Swift files...\n');
  const files = getSwiftFiles(VIEWS_DIR);
  console.log(`Found ${files.length} Swift files\n`);

  // Process files
  console.log('🔄 Processing files...\n');
  const modifiedFiles = [];

  for (const file of files) {
    const result = processFile(file);
    if (result) {
      modifiedFiles.push(result);
    }
  }

  // Print results
  console.log('\n' + '='.repeat(80));
  console.log('RESULTS');
  console.log('='.repeat(80) + '\n');

  console.log(`📊 Statistics:`);
  console.log(`   Files scanned:        ${stats.filesScanned}`);
  console.log(`   Files modified:       ${stats.filesModified}`);
  console.log(`   Opacity replacements: ${stats.opacityReplacements}`);
  console.log(`   Radius replacements:  ${stats.radiusReplacements}`);
  console.log(`   Padding replacements: ${stats.paddingReplacements}`);
  console.log(`   Total replacements:   ${stats.opacityReplacements + stats.radiusReplacements + stats.paddingReplacements}\n`);

  if (modifiedFiles.length > 0) {
    console.log(`📝 Modified files (${modifiedFiles.length}):\n`);

    // Group by replacement count
    const sorted = modifiedFiles.sort((a, b) => b.replacements - a.replacements);

    for (const file of sorted.slice(0, 20)) {  // Show top 20
      const relativePath = file.path.replace(VIEWS_DIR + '/', '');
      console.log(`   ${relativePath}`);
      console.log(`      → ${file.replacements} replacements (opacity: ${file.opacity}, radius: ${file.radius}, padding: ${file.padding})`);
    }

    if (sorted.length > 20) {
      console.log(`\n   ... and ${sorted.length - 20} more files`);
    }
  }

  if (stats.errors.length > 0) {
    console.log(`\n⚠️  Errors (${stats.errors.length}):\n`);
    for (const error of stats.errors) {
      console.log(`   ${error}`);
    }
  }

  console.log('\n' + '='.repeat(80));

  if (DRY_RUN) {
    console.log('\n💡 This was a dry run. Run with --apply to make changes.');
    console.log('   Example: node refactor-design-tokens.js --apply\n');
  } else if (!STATS_ONLY) {
    console.log(`\n✅ Changes applied successfully!`);
    console.log(`📦 Backup available at: ${BACKUP_DIR}\n`);
  }

  // Exit with error code if there were errors
  if (stats.errors.length > 0) {
    process.exit(1);
  }
}

// Run
if (require.main === module) {
  main();
}

module.exports = { refactorOpacity, refactorCornerRadius, refactorPadding };
