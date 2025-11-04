#!/usr/bin/env node
/**
 * Email Corpus Parser
 * Parses Gmail mbox files and extracts emails for testing
 */

const fs = require('fs');
const path = require('path');
const Mbox = require('node-mbox');
const {simpleParser} = require('mailparser');

class CorpusParser {
  constructor(corpusPath) {
    this.corpusPath = corpusPath;
    this.stats = {
      totalFiles: 0,
      totalEmails: 0,
      totalSize: 0,
      byFolder: {},
      parseErrors: 0
    };
  }

  /**
   * Parse single mbox file and extract emails
   * @param {string} mboxPath - Path to mbox file
   * @param {Object} options - Parsing options
   * @returns {Promise<Array>} Parsed emails
   */
  async parseMboxFile(mboxPath, options = {}) {
    const {
      limit = null,
      skipBodyParsing = false,
      onProgress = null
    } = options;

    return new Promise((resolve, reject) => {
      const emails = [];
      const mbox = new Mbox(fs.createReadStream(mboxPath));
      let count = 0;

      mbox.on('message', async (msg) => {
        try {
          count++;

          // Progress callback
          if (onProgress && count % 100 === 0) {
            onProgress(count, path.basename(mboxPath));
          }

          // Limit check
          if (limit && count > limit) {
            mbox.destroy();
            resolve(emails);
            return;
          }

          // Parse email
          const parsed = await simpleParser(msg);

          const email = {
            subject: parsed.subject || '',
            from: parsed.from?.text || '',
            to: parsed.to?.text || '',
            date: parsed.date ? parsed.date.toISOString() : '',
            textBody: skipBodyParsing ? '' : (parsed.text || ''),
            htmlBody: skipBodyParsing ? '' : (parsed.html || ''),
            snippet: this.extractSnippet(parsed.text),
            size: msg.length,
            hasAttachments: parsed.attachments?.length > 0
          };

          emails.push(email);
        } catch (err) {
          this.stats.parseErrors++;
          console.error(`Error parsing email: ${err.message}`);
        }
      });

      mbox.on('end', () => {
        resolve(emails);
      });

      mbox.on('error', (err) => {
        reject(err);
      });
    });
  }

  /**
   * Extract snippet from email body
   * @param {string} text - Email body text
   * @returns {string} Snippet (first 150 chars)
   */
  extractSnippet(text) {
    if (!text) return '';
    return text.substring(0, 150).replace(/\s+/g, ' ').trim();
  }

  /**
   * Scan corpus directory and list all mbox files
   * @returns {Array} List of mbox files with metadata
   */
  scanCorpus() {
    const files = fs.readdirSync(this.corpusPath);
    const mboxFiles = files.filter(f => f.endsWith('.mbox'));

    return mboxFiles.map(filename => {
      const filepath = path.join(this.corpusPath, filename);
      const stats = fs.statSync(filepath);

      return {
        filename,
        filepath,
        size: stats.size,
        sizeGB: (stats.size / (1024 ** 3)).toFixed(2),
        modified: stats.mtime.toISOString()
      };
    }).sort((a, b) => b.size - a.size);
  }

  /**
   * Sample emails from corpus with stratification
   * @param {Object} options - Sampling options
   * @returns {Promise<Array>} Sampled emails
   */
  async sampleEmails(options = {}) {
    const {
      sampleSize = 1000,
      stratifyByFolder = true,
      seedFile = null
    } = options;

    const mboxFiles = this.scanCorpus();

    if (mboxFiles.length === 0) {
      throw new Error('No mbox files found in corpus');
    }

    console.log(`\n📧 Sampling ${sampleSize} emails from ${mboxFiles.length} mbox files...\n`);

    const allEmails = [];
    const filesPerMbox = Math.ceil(sampleSize / mboxFiles.length);

    // If seedFile specified, use only that file
    const filesToProcess = seedFile
      ? mboxFiles.filter(f => f.filename === seedFile)
      : mboxFiles;

    for (const mboxFile of filesToProcess) {
      console.log(`   Processing ${mboxFile.filename} (${mboxFile.sizeGB}GB)...`);

      try {
        const emails = await this.parseMboxFile(mboxFile.filepath, {
          limit: filesPerMbox,
          onProgress: (count, filename) => {
            process.stdout.write(`\r   ${filename}: ${count} emails parsed...`);
          }
        });

        // Add source metadata
        emails.forEach(email => {
          email.sourceFile = mboxFile.filename;
        });

        allEmails.push(...emails);
        console.log(`\n   ✅ Extracted ${emails.length} emails from ${mboxFile.filename}`);

        // Stop if we have enough emails
        if (allEmails.length >= sampleSize) {
          break;
        }
      } catch (err) {
        console.error(`   ❌ Error processing ${mboxFile.filename}: ${err.message}`);
      }
    }

    // Shuffle and limit to exact sample size
    const shuffled = allEmails.sort(() => Math.random() - 0.5);
    return shuffled.slice(0, sampleSize);
  }

  /**
   * Generate corpus statistics
   * @returns {Object} Statistics object
   */
  async generateStatistics(sampleEmails) {
    const stats = {
      totalSampled: sampleEmails.length,
      avgBodyLength: 0,
      avgSubjectLength: 0,
      bySource: {},
      topDomains: {},
      hasAttachments: 0
    };

    let totalBodyLength = 0;
    let totalSubjectLength = 0;

    sampleEmails.forEach(email => {
      // Body length
      totalBodyLength += (email.textBody || '').length;
      totalSubjectLength += (email.subject || '').length;

      // By source file
      stats.bySource[email.sourceFile] = (stats.bySource[email.sourceFile] || 0) + 1;

      // Extract domain from sender
      const domainMatch = email.from.match(/@([^\s>]+)/);
      if (domainMatch) {
        const domain = domainMatch[1].toLowerCase();
        stats.topDomains[domain] = (stats.topDomains[domain] || 0) + 1;
      }

      // Attachments
      if (email.hasAttachments) {
        stats.hasAttachments++;
      }
    });

    stats.avgBodyLength = Math.round(totalBodyLength / sampleEmails.length);
    stats.avgSubjectLength = Math.round(totalSubjectLength / sampleEmails.length);

    // Get top 20 domains
    stats.topDomains = Object.entries(stats.topDomains)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 20)
      .reduce((acc, [domain, count]) => {
        acc[domain] = count;
        return acc;
      }, {});

    return stats;
  }

  /**
   * Save emails to JSON file
   * @param {Array} emails - Emails to save
   * @param {string} outputPath - Output file path
   */
  saveEmails(emails, outputPath) {
    fs.writeFileSync(outputPath, JSON.stringify(emails, null, 2));
    console.log(`\n💾 Saved ${emails.length} emails to ${outputPath}`);
    console.log(`📊 File size: ${(fs.statSync(outputPath).size / 1024 / 1024).toFixed(1)} MB`);
  }
}

// CLI usage
if (require.main === module) {
  const corpusPath = process.argv[2] || '/Users/matthanson/Downloads/emailsfordeepsampling/Takeout/Mail';
  const sampleSize = parseInt(process.argv[3]) || 1000;
  const outputPath = process.argv[4] || path.join(__dirname, 'corpus-sample.json');

  const parser = new CorpusParser(corpusPath);

  console.log('📁 Scanning corpus directory...');
  const mboxFiles = parser.scanCorpus();
  console.log(`\n✅ Found ${mboxFiles.length} mbox files:`);
  mboxFiles.forEach(f => {
    console.log(`   ${f.filename}: ${f.sizeGB} GB`);
  });

  console.log('\n🎯 Starting email sampling...');
  parser.sampleEmails({ sampleSize })
    .then(async (emails) => {
      console.log(`\n✅ Sampled ${emails.length} emails`);

      // Generate statistics
      const stats = await parser.generateStatistics(emails);
      console.log('\n📊 Corpus Statistics:');
      console.log(`   Total Sampled: ${stats.totalSampled}`);
      console.log(`   Avg Body Length: ${stats.avgBodyLength} chars`);
      console.log(`   Avg Subject Length: ${stats.avgSubjectLength} chars`);
      console.log(`   With Attachments: ${stats.hasAttachments}`);
      console.log('\n   By Source File:');
      Object.entries(stats.bySource).forEach(([file, count]) => {
        console.log(`      ${file}: ${count} emails`);
      });
      console.log('\n   Top 10 Sender Domains:');
      Object.entries(stats.topDomains).slice(0, 10).forEach(([domain, count]) => {
        console.log(`      ${domain}: ${count} emails`);
      });

      // Save emails and stats
      parser.saveEmails(emails, outputPath);
      fs.writeFileSync(
        path.join(__dirname, 'corpus-stats.json'),
        JSON.stringify(stats, null, 2)
      );

      console.log('\n✨ Done!\n');
    })
    .catch(err => {
      console.error('❌ Error:', err.message);
      process.exit(1);
    });
}

module.exports = CorpusParser;
