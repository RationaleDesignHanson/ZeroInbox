#!/usr/bin/env python3
"""
Process ALL Email Sources for Complete Coverage

Systematically processes every email source in the personal inbox directory.
"""

import os
import sys
import json
import mailbox
import hashlib
from pathlib import Path
from datetime import datetime
from email import policy
from email.parser import BytesParser
from collections import defaultdict

BASE_DIR = Path('/Users/matthanson/Zer0_Inbox/emailcorpus')
PERSONAL_DIR = BASE_DIR / 'emailsfordeepsampling' / 'Takeout' / 'Mail'
OUTPUT_DIR = BASE_DIR / 'personal' / 'scrubbed'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Import PII scrubbing
sys.path.insert(0, str(BASE_DIR / 'scripts'))
from scrub_personal_emails import scrub_pii, extract_body

# Track all processed emails
all_emails = []
stats = defaultdict(int)

def process_eml_directory(dir_path, dir_name):
    """Process all .eml files in a directory."""
    print(f"\n📂 Processing {dir_name}/...")
    eml_files = sorted(dir_path.glob('*.eml'))
    print(f"   Found {len(eml_files):,} .eml files")
    
    processed = 0
    for i, eml_path in enumerate(eml_files):
        try:
            with open(eml_path, 'rb') as f:
                msg = BytesParser(policy=policy.default).parse(f)
            
            email = {
                'subject': msg.get('Subject', '(No Subject)') or '(No Subject)',
                'from': msg.get('From', 'unknown') or 'unknown',
                'body': extract_body(msg)[:10000],
                '_source': dir_name,
            }
            
            # Scrub PII
            email['subject'] = scrub_pii(email['subject'])
            email['from'] = scrub_pii(email['from'])
            email['body'] = scrub_pii(email['body'])
            
            all_emails.append(email)
            processed += 1
            stats['eml_processed'] += 1
            
            if (i + 1) % 1000 == 0:
                print(f"   Processed {i + 1:,}/{len(eml_files):,}...")
                
        except Exception as e:
            stats['eml_errors'] += 1
            if stats['eml_errors'] <= 5:
                print(f"   Error on {eml_path.name}: {e}")
    
    print(f"   ✅ Processed {processed:,} emails from {dir_name}")
    return processed


def process_mbox_file(mbox_path, source_name, limit=None):
    """Process emails from an mbox file."""
    print(f"\n📦 Processing {source_name}...")
    print(f"   File: {mbox_path.name}")
    
    try:
        mbox = mailbox.mbox(str(mbox_path))
        total = len(mbox)
        print(f"   Total emails: {total:,}")
        
        processed = 0
        target = limit if limit else total
        
        for i, msg in enumerate(mbox):
            if processed >= target:
                break
                
            try:
                email = {
                    'subject': msg.get('Subject', '(No Subject)') or '(No Subject)',
                    'from': msg.get('From', 'unknown') or 'unknown',
                    'body': extract_body(msg)[:10000],
                    '_source': source_name,
                }
                
                # Scrub PII
                email['subject'] = scrub_pii(email['subject'])
                email['from'] = scrub_pii(email['from'])
                email['body'] = scrub_pii(email['body'])
                
                all_emails.append(email)
                processed += 1
                stats['mbox_processed'] += 1
                
                if (i + 1) % 5000 == 0:
                    print(f"   Processed {i + 1:,}/{target:,}...")
                    
            except Exception as e:
                stats['mbox_errors'] += 1
                if stats['mbox_errors'] <= 5:
                    print(f"   Error on email {i}: {e}")
        
        mbox.close()
        print(f"   ✅ Processed {processed:,} emails from {source_name}")
        return processed
        
    except Exception as e:
        print(f"   ❌ Error reading {mbox_path}: {e}")
        stats['mbox_errors'] += 1
        return 0


def main():
    print("=" * 70)
    print("🔄 PROCESSING ALL EMAIL SOURCES FOR COMPLETE COVERAGE")
    print("=" * 70)
    
    # Process all .eml directories
    eml_dirs = {
        'Inbox-001': PERSONAL_DIR / 'Inbox-001',
        'opened_emails': PERSONAL_DIR / 'opened_emails',
        'starred_emails': PERSONAL_DIR / 'starred_emails',
    }
    
    for dir_name, dir_path in eml_dirs.items():
        if dir_path.exists():
            process_eml_directory(dir_path, dir_name)
    
    # Process smaller mbox files first
    small_mbox = {
        'Starred2.mbox': PERSONAL_DIR / 'Starred2.mbox',
        'Starred3.mbox': PERSONAL_DIR / 'Starred3.mbox',
    }
    
    for name, path in small_mbox.items():
        if path.exists():
            process_mbox_file(path, name)
    
    # Process medium mbox files
    medium_mbox = {
        'Opened2.mbox': PERSONAL_DIR / 'Opened2.mbox',
        'Opened3.mbox': PERSONAL_DIR / 'Opened3.mbox',
        'Inbox-001.mbox': PERSONAL_DIR / 'Inbox-001.mbox',
        'Sent-003.mbox': PERSONAL_DIR / 'Sent-003.mbox',
    }
    
    for name, path in medium_mbox.items():
        if path.exists():
            # Process in chunks for large files
            size_mb = path.stat().st_size / (1024 * 1024)
            if size_mb > 2000:  # > 2GB
                print(f"   ⚠️  Large file ({size_mb:.1f} MB), processing sample...")
                process_mbox_file(path, name, limit=50000)  # Sample 50K
            else:
                process_mbox_file(path, name)
    
    # Process largest mbox file (Inbox-002.mbox - 26GB)
    large_mbox = PERSONAL_DIR / 'Inbox-002.mbox'
    if large_mbox.exists():
        print(f"\n📦 Processing Inbox-002.mbox (26GB - largest file)...")
        print(f"   This will take significant time...")
        # Process in large sample
        process_mbox_file(large_mbox, 'Inbox-002.mbox', limit=100000)  # Sample 100K
    
    # Save complete corpus
    print("\n" + "=" * 70)
    print("💾 SAVING COMPLETE CORPUS")
    print("=" * 70)
    
    output_file = OUTPUT_DIR / 'personal_corpus_complete.json'
    print(f"\nWriting {len(all_emails):,} emails to {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_emails, f, indent=2, ensure_ascii=False)
    
    file_size = output_file.stat().st_size / (1024 * 1024)
    print(f"✅ Saved {len(all_emails):,} emails ({file_size:.1f} MB)")
    
    # Create report
    report = {
        'timestamp': datetime.now().isoformat(),
        'total_emails': len(all_emails),
        'sources': dict(stats),
        'output_file': str(output_file),
        'file_size_mb': round(file_size, 1),
    }
    
    report_file = OUTPUT_DIR / 'personal_corpus_complete.report.json'
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    
    # Summary
    print("\n" + "=" * 70)
    print("✅ PROCESSING COMPLETE!")
    print("=" * 70)
    print(f"\nTotal emails processed: {len(all_emails):,}")
    print(f"  - From .eml files: {stats['eml_processed']:,}")
    print(f"  - From .mbox files: {stats['mbox_processed']:,}")
    print(f"  - Errors: {stats['eml_errors'] + stats['mbox_errors']:,}")
    print(f"\nOutput: {output_file}")
    print(f"Report: {report_file}")

if __name__ == '__main__':
    main()

