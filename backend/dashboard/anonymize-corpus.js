#!/usr/bin/env node

/**
 * Corpus Anonymization Script
 *
 * Replaces placeholder tokens with realistic anonymized data while preserving intent signals.
 * Filters out inappropriate content (personal/romantic/adult).
 */

const fs = require('fs');
const path = require('path');

// Anonymized data pools
const NAMES = {
    first: ['Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Drew', 'Jamie', 'Avery'],
    last: ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez']
};

const COMPANIES = [
    'TechCorp', 'DataSystems', 'CloudWorks', 'InnovateLabs', 'DigitalFirst',
    'SmartSolutions', 'FutureWare', 'NetServices', 'WebDynamics', 'InfoTech'
];

const DOMAINS = [
    'example.com', 'test.org', 'demo.net', 'sample.io', 'placeholder.co'
];

const INAPPROPRIATE_KEYWORDS = [
    'dating', 'romantic', 'personal', 'relationship', 'hookup', 'adult',
    'match', 'singles', 'flirt', 'intimate', 'sensual', 'sexy'
];

// Random data generators
function randomNumber(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomName() {
    const first = NAMES.first[randomNumber(0, NAMES.first.length - 1)];
    const last = NAMES.last[randomNumber(0, NAMES.last.length - 1)];
    return `${first} ${last}`;
}

function randomEmail() {
    const first = NAMES.first[randomNumber(0, NAMES.first.length - 1)].toLowerCase();
    const last = NAMES.last[randomNumber(0, NAMES.last.length - 1)].toLowerCase();
    const domain = DOMAINS[randomNumber(0, DOMAINS.length - 1)];
    return `${first}.${last}@${domain}`;
}

function randomCompany() {
    return COMPANIES[randomNumber(0, COMPANIES.length - 1)];
}

function randomOrderNumber() {
    return `${randomNumber(100, 999)}-${randomNumber(1000000, 9999999)}-${randomNumber(1000000, 9999999)}`;
}

function randomTrackingNumber() {
    const carriers = [
        () => `1Z${randomNumber(100, 999)}AA${randomNumber(10000000000, 99999999999)}`, // UPS
        () => `${randomNumber(100000000000, 999999999999)}`, // FedEx
        () => `${randomNumber(9200, 9999)} ${randomNumber(1000, 9999)} ${randomNumber(1000, 9999)} ${randomNumber(1000, 9999)} ${randomNumber(1000, 9999)} ${randomNumber(10, 99)}`, // USPS
    ];
    return carriers[randomNumber(0, carriers.length - 1)]();
}

function randomAccountNumber() {
    return `${randomNumber(1000, 9999)}-${randomNumber(1000, 9999)}-${randomNumber(1000, 9999)}-${randomNumber(1000, 9999)}`;
}

function randomPhone() {
    return `(${randomNumber(200, 999)}) ${randomNumber(200, 999)}-${randomNumber(1000, 9999)}`;
}

function randomInvoiceNumber() {
    return `INV-${new Date().getFullYear()}-${randomNumber(1000, 9999)}`;
}

function randomAmount() {
    return `$${randomNumber(10, 999)}.${randomNumber(10, 99)}`;
}

function randomDate() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const month = months[randomNumber(0, 11)];
    const day = randomNumber(1, 28);
    const year = 2025;
    return `${month} ${day}, ${year}`;
}

function randomURL() {
    const paths = [
        '/track', '/view', '/account', '/order', '/confirm', '/details',
        '/checkout', '/payment', '/invoice', '/return', '/schedule'
    ];
    const domains = ['example.com', 'service.net', 'platform.io', 'app.co'];
    const domain = domains[randomNumber(0, domains.length - 1)];
    const pathIndex = randomNumber(0, paths.length - 1);
    const id = randomNumber(100000, 999999);
    return `https://${domain}${paths[pathIndex]}/${id}`;
}

function randomTime() {
    const hour = randomNumber(8, 20);
    const minute = randomNumber(0, 59).toString().padStart(2, '0');
    const ampm = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour > 12 ? hour - 12 : hour;
    return `${displayHour}:${minute} ${ampm}`;
}

function randomFlightNumber() {
    const airlines = ['UA', 'AA', 'DL', 'SW', 'B6', 'AS'];
    const airline = airlines[randomNumber(0, airlines.length - 1)];
    const number = randomNumber(100, 9999);
    return `${airline} ${number}`;
}

function randomConfirmation() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars[randomNumber(0, chars.length - 1)];
    }
    return code;
}

// Replace placeholder tokens
function anonymizeText(text) {
    if (!text) return text;

    let result = text;

    // Replace placeholders with realistic data
    result = result.replace(/\{num\}/g, () => randomOrderNumber());
    result = result.replace(/\{tracking\}/g, () => randomTrackingNumber());
    result = result.replace(/\{account\}/g, () => randomAccountNumber());
    result = result.replace(/\{invoice\}/g, () => randomInvoiceNumber());
    result = result.replace(/\{phone\}/g, () => randomPhone());
    result = result.replace(/\{amount\}/g, () => randomAmount());
    result = result.replace(/\{date\}/g, () => randomDate());
    result = result.replace(/\{time\}/g, () => randomTime());
    result = result.replace(/\{url\}/g, () => randomURL());
    result = result.replace(/\{name\}/g, () => randomName());
    result = result.replace(/\{email\}/g, () => randomEmail());
    result = result.replace(/\{company\}/g, () => randomCompany());
    result = result.replace(/\{flight\}/g, () => randomFlightNumber());
    result = result.replace(/\{confirmation\}/g, () => randomConfirmation());

    return result;
}

// Check if email contains inappropriate content
function isInappropriate(email) {
    const searchText = `${email.subject} ${email.body}`.toLowerCase();

    for (const keyword of INAPPROPRIATE_KEYWORDS) {
        if (searchText.includes(keyword)) {
            return true;
        }
    }

    return false;
}

// Process corpus
function processCorpus(inputPath, outputPath) {
    console.log('📧 Reading corpus from:', inputPath);

    const corpus = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
    console.log(`📊 Total emails in corpus: ${corpus.length}`);

    // Filter out inappropriate content
    const filtered = corpus.filter(email => !isInappropriate(email));
    console.log(`✅ After filtering inappropriate content: ${filtered.length} emails`);
    console.log(`🗑️  Removed: ${corpus.length - filtered.length} emails`);

    // Anonymize each email
    const anonymized = filtered.map(email => {
        return {
            subject: anonymizeText(email.subject),
            from: anonymizeText(email.from),
            body: anonymizeText(email.body),
            intent: email.intent,
            generated: email.generated || false
        };
    });

    // Remove duplicates (can happen with placeholder replacements)
    const unique = [];
    const seen = new Set();

    for (const email of anonymized) {
        const key = `${email.subject}|${email.intent}`;
        if (!seen.has(key)) {
            seen.add(key);
            unique.push(email);
        }
    }

    console.log(`🎯 After removing duplicates: ${unique.length} unique emails`);

    // Write output
    fs.writeFileSync(outputPath, JSON.stringify(unique, null, 2), 'utf8');
    console.log('✅ Anonymized corpus written to:', outputPath);

    // Show stats
    const intentCounts = {};
    for (const email of unique) {
        intentCounts[email.intent] = (intentCounts[email.intent] || 0) + 1;
    }

    console.log('\n📈 Intent distribution:');
    const sortedIntents = Object.entries(intentCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10);

    for (const [intent, count] of sortedIntents) {
        console.log(`  ${intent}: ${count} emails`);
    }

    console.log(`\n🎉 Done! ${unique.length} anonymized emails ready for use.`);
}

// Main execution
if (require.main === module) {
    const inputPath = process.argv[2] || '/Users/matthanson/EmailShortForm_01/Zero/data/comprehensive-corpus.json';
    const outputPath = process.argv[3] || '/Users/matthanson/Zer0_Inbox/backend/dashboard/data/comprehensive-corpus.json';

    if (!fs.existsSync(inputPath)) {
        console.error('❌ Error: Input corpus not found at:', inputPath);
        process.exit(1);
    }

    processCorpus(inputPath, outputPath);
}

module.exports = { anonymizeText, isInappropriate };
