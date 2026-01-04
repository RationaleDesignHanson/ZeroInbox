#!/usr/bin/env python3
"""
Personal Email PII Scrubber

Processes .eml and .mbox files from personal email exports,
scrubs PII, and outputs JSON compatible with Zero's pipeline.

Usage:
    python3 scrub_personal_emails.py [options]
    
Options:
    --input DIR       Input directory (default: emailsfordeepsampling/Takeout/Mail)
    --output FILE     Output JSON file (default: personal/scrubbed/personal_corpus.json)
    --limit N         Limit number of emails to process
    --verbose         Show detailed progress
"""

import os
import sys
import re
import json
import email
import hashlib
import argparse
import mailbox
from email import policy
from email.parser import BytesParser
from datetime import datetime
from pathlib import Path
from collections import defaultdict

# Configuration
BASE_DIR = Path('/Users/matthanson/Zer0_Inbox/emailcorpus')
DEFAULT_INPUT = BASE_DIR / 'emailsfordeepsampling' / 'Takeout' / 'Mail'
DEFAULT_OUTPUT = BASE_DIR / 'personal' / 'scrubbed' / 'personal_corpus.json'

# PII Patterns
PII_PATTERNS = {
    'email': re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', re.IGNORECASE),
    'phone': re.compile(r'(\+\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'),
    'ssn': re.compile(r'\b\d{3}-\d{2}-\d{4}\b'),
    'credit_card': re.compile(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),
    'zip_code': re.compile(r'\b\d{5}(-\d{4})?\b'),
    'ip_address': re.compile(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'),
    'date_of_birth': re.compile(r'\b(0[1-9]|1[0-2])[-/](0[1-9]|[12]\d|3[01])[-/](\d{2}|\d{4})\b'),
    'street_address': re.compile(r'\b\d{1,5}\s+[\w\s]+(?:street|st|avenue|ave|road|rd|boulevard|blvd|drive|dr|lane|ln|way|court|ct|place|pl)\b', re.IGNORECASE),
}

# Common name patterns (titles + capitalized words)
NAME_PATTERN = re.compile(r'\b(Mr\.|Mrs\.|Ms\.|Dr\.|Prof\.)\s+[A-Z][a-z]+(\s+[A-Z][a-z]+)?\b')

# Email domain cache for consistent anonymization
email_cache = {}
name_cache = {}

def generate_anonymous_email(original):
    """Generate consistent anonymous email for each unique address."""
    if original.lower() in email_cache:
        return email_cache[original.lower()]
    
    # Create hash-based anonymous email
    hash_val = hashlib.md5(original.lower().encode()).hexdigest()[:8]
    anon_email = f"user_{hash_val}@example.com"
    email_cache[original.lower()] = anon_email
    return anon_email

def generate_anonymous_name(original):
    """Generate consistent anonymous name."""
    if original.lower() in name_cache:
        return name_cache[original.lower()]
    
    hash_val = hashlib.md5(original.lower().encode()).hexdigest()[:6]
    anon_name = f"[PERSON_{hash_val}]"
    name_cache[original.lower()] = anon_name
    return anon_name

def scrub_pii(text):
    """Remove all PII from text."""
    if not text:
        return text
    
    result = text
    
    # Scrub emails (with consistent anonymization)
    result = PII_PATTERNS['email'].sub(lambda m: generate_anonymous_email(m.group(0)), result)
    
    # Scrub other PII patterns
    result = PII_PATTERNS['phone'].sub('[PHONE_REDACTED]', result)
    result = PII_PATTERNS['ssn'].sub('[SSN_REDACTED]', result)
    result = PII_PATTERNS['credit_card'].sub('[CARD_REDACTED]', result)
    result = PII_PATTERNS['ip_address'].sub('[IP_REDACTED]', result)
    result = PII_PATTERNS['street_address'].sub('[ADDRESS_REDACTED]', result)
    
    # Scrub names with titles
    result = NAME_PATTERN.sub(lambda m: generate_anonymous_name(m.group(0)), result)
    
    return result

def extract_body(msg):
    """Extract email body, preferring plain text."""
    body = ""
    
    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            content_disposition = str(part.get("Content-Disposition"))
            
            # Skip attachments
            if "attachment" in content_disposition:
                continue
            
            if content_type == "text/plain":
                try:
                    payload = part.get_payload(decode=True)
                    if payload:
                        charset = part.get_content_charset() or 'utf-8'
                        body = payload.decode(charset, errors='replace')
                        break
                except Exception:
                    pass
            elif content_type == "text/html" and not body:
                try:
                    payload = part.get_payload(decode=True)
                    if payload:
                        charset = part.get_content_charset() or 'utf-8'
                        html = payload.decode(charset, errors='replace')
                        # Basic HTML stripping
                        body = re.sub(r'<[^>]+>', ' ', html)
                        body = re.sub(r'\s+', ' ', body).strip()
                except Exception:
                    pass
    else:
        try:
            payload = msg.get_payload(decode=True)
            if payload:
                charset = msg.get_content_charset() or 'utf-8'
                body = payload.decode(charset, errors='replace')
        except Exception:
            body = str(msg.get_payload())
    
    return body.strip()

def parse_eml_file(filepath):
    """Parse a single .eml file."""
    try:
        with open(filepath, 'rb') as f:
            msg = BytesParser(policy=policy.default).parse(f)
        
        subject = msg.get('Subject', '(No Subject)') or '(No Subject)'
        from_addr = msg.get('From', 'unknown@example.com') or 'unknown@example.com'
        date = msg.get('Date', '')
        body = extract_body(msg)
        
        return {
            'subject': subject,
            'from': from_addr,
            'date': date,
            'body': body[:10000] if body else '',  # Limit body length
        }
    except Exception as e:
        return None

def parse_mbox_file(filepath, limit=None):
    """Parse emails from an mbox file."""
    emails = []
    try:
        mbox = mailbox.mbox(filepath)
        count = 0
        for msg in mbox:
            if limit and count >= limit:
                break
            
            try:
                subject = msg.get('Subject', '(No Subject)') or '(No Subject)'
                from_addr = msg.get('From', 'unknown@example.com') or 'unknown@example.com'
                date = msg.get('Date', '')
                body = extract_body(msg)
                
                emails.append({
                    'subject': subject,
                    'from': from_addr,
                    'date': date,
                    'body': body[:10000] if body else '',
                })
                count += 1
            except Exception:
                continue
        mbox.close()
    except Exception as e:
        print(f"  Error reading mbox {filepath}: {e}")
    
    return emails

def process_directory(input_dir, limit=None, verbose=False):
    """Process all email files in directory."""
    emails = []
    stats = defaultdict(int)
    
    input_path = Path(input_dir)
    
    # Process .eml files first (they're cleaner)
    eml_dirs = ['Inbox-001', 'opened_emails', 'starred_emails']
    
    for dir_name in eml_dirs:
        dir_path = input_path / dir_name
        if not dir_path.exists():
            continue
        
        print(f"\n📂 Processing {dir_name}...")
        eml_files = list(dir_path.glob('*.eml'))
        
        for i, eml_file in enumerate(eml_files):
            if limit and len(emails) >= limit:
                break
            
            result = parse_eml_file(eml_file)
            if result:
                emails.append(result)
                stats['eml_processed'] += 1
            else:
                stats['eml_errors'] += 1
            
            if verbose and (i + 1) % 1000 == 0:
                print(f"  Processed {i + 1}/{len(eml_files)} .eml files...")
        
        if limit and len(emails) >= limit:
            break
    
    # Process smaller mbox files if we need more
    if not limit or len(emails) < limit:
        mbox_files = ['Starred2.mbox', 'Starred3.mbox']  # Start with smaller ones
        
        for mbox_name in mbox_files:
            if limit and len(emails) >= limit:
                break
            
            mbox_path = input_path / mbox_name
            if not mbox_path.exists():
                continue
            
            print(f"\n📦 Processing {mbox_name}...")
            remaining = (limit - len(emails)) if limit else None
            mbox_emails = parse_mbox_file(mbox_path, limit=remaining)
            emails.extend(mbox_emails)
            stats['mbox_processed'] += len(mbox_emails)
            print(f"  Extracted {len(mbox_emails)} emails")
    
    return emails, stats

def main():
    parser = argparse.ArgumentParser(description='Scrub PII from personal emails')
    parser.add_argument('--input', type=str, default=str(DEFAULT_INPUT),
                        help='Input directory containing email files')
    parser.add_argument('--output', type=str, default=str(DEFAULT_OUTPUT),
                        help='Output JSON file')
    parser.add_argument('--limit', type=int, default=None,
                        help='Limit number of emails to process')
    parser.add_argument('--verbose', action='store_true',
                        help='Show detailed progress')
    
    args = parser.parse_args()
    
    print("\n" + "=" * 60)
    print("🔒 Personal Email PII Scrubber")
    print("=" * 60)
    print(f"Input:  {args.input}")
    print(f"Output: {args.output}")
    if args.limit:
        print(f"Limit:  {args.limit} emails")
    
    # Create output directory
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Process emails
    print("\n📧 Extracting emails...")
    emails, stats = process_directory(args.input, limit=args.limit, verbose=args.verbose)
    
    print(f"\n✅ Extracted {len(emails)} emails")
    print(f"   - From .eml files: {stats['eml_processed']}")
    print(f"   - From .mbox files: {stats['mbox_processed']}")
    print(f"   - Errors: {stats['eml_errors']}")
    
    # Scrub PII
    print("\n🔐 Scrubbing PII...")
    scrubbed_emails = []
    pii_stats = defaultdict(int)
    
    for i, email_data in enumerate(emails):
        scrubbed = {
            'subject': scrub_pii(email_data['subject']),
            'from': scrub_pii(email_data['from']),
            'body': scrub_pii(email_data['body']),
        }
        
        # Track PII found
        for field in ['subject', 'from', 'body']:
            original = email_data[field] or ''
            if PII_PATTERNS['email'].search(original):
                pii_stats['emails_found'] += 1
            if PII_PATTERNS['phone'].search(original):
                pii_stats['phones_found'] += 1
        
        scrubbed_emails.append(scrubbed)
        
        if args.verbose and (i + 1) % 5000 == 0:
            print(f"  Scrubbed {i + 1}/{len(emails)} emails...")
    
    print(f"   - Email addresses anonymized: {len(email_cache)}")
    print(f"   - Names anonymized: {len(name_cache)}")
    
    # Write output
    print(f"\n💾 Writing to {args.output}...")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(scrubbed_emails, f, indent=2, ensure_ascii=False)
    
    # Write report
    report_path = output_path.with_suffix('.report.json')
    report = {
        'timestamp': datetime.now().isoformat(),
        'input_directory': str(args.input),
        'output_file': str(args.output),
        'total_emails': len(scrubbed_emails),
        'sources': {
            'eml_files': stats['eml_processed'],
            'mbox_files': stats['mbox_processed'],
            'errors': stats['eml_errors'],
        },
        'pii_scrubbed': {
            'unique_emails': len(email_cache),
            'unique_names': len(name_cache),
        }
    }
    
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ Processing Complete!")
    print("=" * 60)
    print(f"Total emails processed: {len(scrubbed_emails)}")
    print(f"Output: {args.output}")
    print(f"Report: {report_path}")
    
    # File size
    file_size = output_path.stat().st_size / (1024 * 1024)
    print(f"Output size: {file_size:.1f} MB")

if __name__ == '__main__':
    main()

