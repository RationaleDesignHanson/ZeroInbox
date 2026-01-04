#!/usr/bin/env python3
"""
Enron Corpus PII Scrubbing Script

Processes the Enron email corpus CSV, scrubs PII, and outputs JSON
in Zero's expected format.

Usage:
    python scrub_enron_pii.py [--input PATH] [--output PATH] [--chunk-size N] [--limit N]

PII Patterns Scrubbed:
    - Email addresses → hash-based anonymization
    - Phone numbers → [PHONE_REDACTED]
    - Credit cards → [CARD_REDACTED]
    - SSN patterns → [SSN_REDACTED]
    - Names with titles → [NAME_REDACTED]
"""

import argparse
import csv
import hashlib
import json
import os
import re
import sys
from datetime import datetime
from typing import Dict, List, Optional, Tuple

# Increase CSV field size limit for large email bodies
csv.field_size_limit(sys.maxsize)

# Configuration
DEFAULT_INPUT = "/Users/matthanson/Zer0_Inbox/emailcorpus/enron/emails.csv"
DEFAULT_OUTPUT = "/Users/matthanson/Zer0_Inbox/emailcorpus/enron/scrubbed/enron_corpus_scrubbed.json"
DEFAULT_CHUNK_SIZE = 10000
ANONYMIZATION_SALT = "zero-enron-pii-salt-2024"

# PII Regex Patterns (ported from data-anonymizer.js)
PATTERNS = {
    'email': re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', re.IGNORECASE),
    'phone': re.compile(r'(\+\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'),
    'credit_card': re.compile(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),
    'ssn': re.compile(r'\b\d{3}-\d{2}-\d{4}\b'),
    'title_name': re.compile(r'\b(Mr\.|Mrs\.|Ms\.|Dr\.|Prof\.)\s+[A-Z][a-z]+(\s+[A-Z][a-z]+)?\b'),
    # Known Enron executives and key figures
    'enron_executives': re.compile(
        r'\b(Kenneth\s+Lay|Ken\s+Lay|Jeff\s+Skilling|Jeffrey\s+Skilling|Andrew\s+Fastow|'
        r'Rebecca\s+Mark|Lou\s+Pai|Cliff\s+Baxter|Mark\s+Frevert|'
        r'Rick\s+Buy|Rick\s+Causey|Ben\s+Glisan|Sherron\s+Watkins)\b',
        re.IGNORECASE
    ),
}

# Known Enron employee name patterns (will be anonymized)
ENRON_DOMAINS = ['@enron.com', '@enron.net', '@ect.enron.com']

# Generic replacement names
GENERIC_NAMES = [
    'Alex Smith', 'Jordan Lee', 'Taylor Kim', 'Morgan Chen', 'Casey Park',
    'Riley Davis', 'Drew Wilson', 'Jamie Brown', 'Avery Garcia', 'Sam Miller'
]

# Stats tracking
stats = {
    'total_rows': 0,
    'processed_emails': 0,
    'parse_errors': 0,
    'pii_scrubbed': {
        'emails': 0,
        'phones': 0,
        'credit_cards': 0,
        'ssns': 0,
        'names': 0
    },
    'missing_subject': 0,
    'missing_from': 0,
    'empty_body': 0
}


def hash_email(email: str) -> str:
    """Create deterministic hash-based anonymization for email addresses."""
    hash_input = f"{email.lower()}{ANONYMIZATION_SALT}"
    hash_value = hashlib.sha256(hash_input.encode()).hexdigest()[:8]
    
    # Extract domain structure
    if '@' in email:
        local, domain = email.rsplit('@', 1)
        domain_parts = domain.split('.')
        if len(domain_parts) >= 2:
            tld = domain_parts[-1]
            return f"user_{hash_value}@example.{tld}"
    
    return f"user_{hash_value}@example.com"


def get_generic_name(original: str) -> str:
    """Get consistent generic name based on hash of original."""
    hash_value = int(hashlib.md5(original.encode()).hexdigest(), 16)
    return GENERIC_NAMES[hash_value % len(GENERIC_NAMES)]


def scrub_pii(text: str) -> Tuple[str, Dict[str, int]]:
    """
    Scrub PII from text content.
    Returns (scrubbed_text, counts_dict)
    """
    if not text:
        return text, {}
    
    counts = {'emails': 0, 'phones': 0, 'credit_cards': 0, 'ssns': 0, 'names': 0}
    result = text
    
    # Email addresses - hash-based anonymization
    def replace_email(match):
        counts['emails'] += 1
        return hash_email(match.group(0))
    result = PATTERNS['email'].sub(replace_email, result)
    
    # Phone numbers
    def replace_phone(match):
        counts['phones'] += 1
        return '[PHONE_REDACTED]'
    result = PATTERNS['phone'].sub(replace_phone, result)
    
    # Credit card numbers
    def replace_cc(match):
        counts['credit_cards'] += 1
        return '[CARD_REDACTED]'
    result = PATTERNS['credit_card'].sub(replace_cc, result)
    
    # SSN patterns
    def replace_ssn(match):
        counts['ssns'] += 1
        return '[SSN_REDACTED]'
    result = PATTERNS['ssn'].sub(replace_ssn, result)
    
    # Names with titles
    def replace_name(match):
        counts['names'] += 1
        title = match.group(1)
        return f"{title} [NAME_REDACTED]"
    result = PATTERNS['title_name'].sub(replace_name, result)
    
    # Known Enron executives
    def replace_exec(match):
        counts['names'] += 1
        return '[EXECUTIVE_REDACTED]'
    result = PATTERNS['enron_executives'].sub(replace_exec, result)
    
    # Any remaining @enron.com mentions (in text, not as email addresses)
    result = re.sub(r'@(ect\.)?enron\.(com|net)', '@example.com', result, flags=re.IGNORECASE)
    
    return result, counts


def parse_email_message(message: str) -> Optional[Dict]:
    """
    Parse raw email message into structured fields.
    Returns dict with: from, to, subject, date, body
    """
    if not message:
        return None
    
    lines = message.split('\n')
    headers = {}
    body_lines = []
    in_body = False
    
    for line in lines:
        if in_body:
            body_lines.append(line)
        elif line.strip() == '':
            # Empty line marks start of body
            in_body = True
        elif ':' in line and not line.startswith(' ') and not line.startswith('\t'):
            # Header line
            key, _, value = line.partition(':')
            key = key.strip().lower()
            value = value.strip()
            
            # Handle common headers
            if key in ['from', 'to', 'subject', 'date', 'message-id', 'x-from', 'x-to']:
                headers[key] = value
        elif line.startswith(' ') or line.startswith('\t'):
            # Continuation of previous header (folded header)
            pass
    
    body = '\n'.join(body_lines).strip()
    
    # Extract best available values
    from_addr = headers.get('from') or headers.get('x-from', '')
    to_addr = headers.get('to') or headers.get('x-to', '')
    subject = headers.get('subject', '')
    date = headers.get('date', '')
    message_id = headers.get('message-id', '')
    
    return {
        'from': from_addr,
        'to': to_addr,
        'subject': subject,
        'date': date,
        'message_id': message_id,
        'body': body
    }


def process_email(parsed: Dict) -> Optional[Dict]:
    """
    Process a parsed email: scrub PII and format for Zero.
    Returns None if email is invalid.
    """
    global stats
    
    # Scrub PII from all fields
    from_scrubbed, from_counts = scrub_pii(parsed['from'])
    subject_scrubbed, subject_counts = scrub_pii(parsed['subject'])
    body_scrubbed, body_counts = scrub_pii(parsed['body'])
    
    # Update stats
    for key in stats['pii_scrubbed']:
        stats['pii_scrubbed'][key] += from_counts.get(key, 0)
        stats['pii_scrubbed'][key] += subject_counts.get(key, 0)
        stats['pii_scrubbed'][key] += body_counts.get(key, 0)
    
    # Track missing fields
    if not subject_scrubbed:
        stats['missing_subject'] += 1
    if not from_scrubbed:
        stats['missing_from'] += 1
    if not body_scrubbed:
        stats['empty_body'] += 1
    
    # Must have at least subject or from to be useful
    if not subject_scrubbed and not from_scrubbed:
        return None
    
    # Format for Zero's expected schema
    return {
        'subject': subject_scrubbed or '(No Subject)',
        'from': from_scrubbed or 'unknown@example.com',
        'body': body_scrubbed[:10000] if body_scrubbed else '',  # Truncate long bodies
        'generated': False,
        'source': 'enron_corpus'
    }


def process_chunk(chunk: List[Dict], output_file, first_chunk: bool) -> int:
    """Process a chunk of emails and write to output file."""
    global stats
    
    processed = 0
    
    for row in chunk:
        stats['total_rows'] += 1
        
        try:
            message = row.get('message', '')
            parsed = parse_email_message(message)
            
            if parsed:
                email_data = process_email(parsed)
                if email_data:
                    # Write JSON line (handle comma for array format)
                    prefix = '' if first_chunk and processed == 0 else ','
                    output_file.write(f"{prefix}\n  {json.dumps(email_data)}")
                    processed += 1
                    stats['processed_emails'] += 1
                    first_chunk = False
        except Exception as e:
            stats['parse_errors'] += 1
            if stats['parse_errors'] <= 10:  # Only log first 10 errors
                print(f"  Parse error in row {stats['total_rows']}: {e}", file=sys.stderr)
    
    return processed


def main():
    parser = argparse.ArgumentParser(description='Scrub PII from Enron email corpus')
    parser.add_argument('--input', '-i', default=DEFAULT_INPUT, help='Input CSV file path')
    parser.add_argument('--output', '-o', default=DEFAULT_OUTPUT, help='Output JSON file path')
    parser.add_argument('--chunk-size', '-c', type=int, default=DEFAULT_CHUNK_SIZE, help='Rows per chunk')
    parser.add_argument('--limit', '-l', type=int, default=None, help='Limit total rows processed')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    args = parser.parse_args()
    
    print(f"📧 Enron Corpus PII Scrubbing Script")
    print(f"=" * 50)
    print(f"Input:  {args.input}")
    print(f"Output: {args.output}")
    print(f"Chunk size: {args.chunk_size:,}")
    if args.limit:
        print(f"Limit: {args.limit:,} rows")
    print()
    
    # Verify input file exists
    if not os.path.exists(args.input):
        print(f"❌ Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)
    
    # Create output directory if needed
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    
    # Process CSV in chunks
    start_time = datetime.now()
    chunk_num = 0
    total_processed = 0
    
    with open(args.output, 'w', encoding='utf-8') as out_file:
        out_file.write('[')  # Start JSON array
        
        with open(args.input, 'r', encoding='utf-8', errors='replace') as in_file:
            reader = csv.DictReader(in_file)
            chunk = []
            first_chunk = True
            
            for row in reader:
                chunk.append(row)
                
                if len(chunk) >= args.chunk_size:
                    chunk_num += 1
                    processed = process_chunk(chunk, out_file, first_chunk and total_processed == 0)
                    total_processed += processed
                    first_chunk = False
                    
                    elapsed = (datetime.now() - start_time).total_seconds()
                    rate = stats['total_rows'] / elapsed if elapsed > 0 else 0
                    print(f"  Chunk {chunk_num}: {stats['total_rows']:,} rows read, {stats['processed_emails']:,} emails processed ({rate:.0f} rows/sec)")
                    
                    chunk = []
                    
                    # Check limit
                    if args.limit and stats['total_rows'] >= args.limit:
                        print(f"  Reached limit of {args.limit:,} rows")
                        break
            
            # Process remaining rows
            if chunk:
                chunk_num += 1
                processed = process_chunk(chunk, out_file, first_chunk and total_processed == 0)
                total_processed += processed
                print(f"  Final chunk {chunk_num}: {stats['total_rows']:,} rows read, {stats['processed_emails']:,} emails processed")
        
        out_file.write('\n]')  # End JSON array
    
    # Calculate final stats
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    print()
    print(f"✅ Processing Complete!")
    print(f"=" * 50)
    print(f"Duration: {duration:.1f} seconds")
    print(f"Total rows read: {stats['total_rows']:,}")
    print(f"Emails processed: {stats['processed_emails']:,}")
    print(f"Parse errors: {stats['parse_errors']:,}")
    print()
    print(f"📊 PII Scrubbed:")
    print(f"  - Email addresses: {stats['pii_scrubbed']['emails']:,}")
    print(f"  - Phone numbers: {stats['pii_scrubbed']['phones']:,}")
    print(f"  - Credit cards: {stats['pii_scrubbed']['credit_cards']:,}")
    print(f"  - SSN patterns: {stats['pii_scrubbed']['ssns']:,}")
    print(f"  - Names (titled): {stats['pii_scrubbed']['names']:,}")
    print()
    print(f"📋 Field Stats:")
    print(f"  - Missing subject: {stats['missing_subject']:,}")
    print(f"  - Missing from: {stats['missing_from']:,}")
    print(f"  - Empty body: {stats['empty_body']:,}")
    print()
    print(f"Output written to: {args.output}")
    
    # Write processing report
    report_path = args.output.replace('.json', '_report.json')
    report = {
        'timestamp': end_time.isoformat(),
        'duration_seconds': duration,
        'input_file': args.input,
        'output_file': args.output,
        'stats': stats,
        'chunk_size': args.chunk_size,
        'limit': args.limit
    }
    
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    print(f"Report written to: {report_path}")


if __name__ == '__main__':
    main()

