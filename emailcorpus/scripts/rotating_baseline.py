#!/usr/bin/env python3
"""
Rotating Sample Baseline Runner

Processes ALL available email sources in rotating batches to ensure
complete coverage over multiple test runs.

Key Features:
1. Tracks which emails have been processed
2. Rotates through different samples each run
3. Aggregates metrics across all runs
4. Ensures 100% coverage over N runs
"""

import os
import sys
import json
import random
import hashlib
import mailbox
from email import policy
from email.parser import BytesParser
from pathlib import Path
from datetime import datetime
from collections import defaultdict

BASE_DIR = Path('/Users/matthanson/Zer0_Inbox/emailcorpus')
PERSONAL_DIR = BASE_DIR / 'emailsfordeepsampling' / 'Takeout' / 'Mail'
STATE_FILE = BASE_DIR / 'rotation_state.json'
BATCH_SIZE = 5000  # Emails per rotation batch

# Source configuration with estimated email counts
SOURCES = {
    'eml_directories': {
        'Inbox-001': {'path': PERSONAL_DIR / 'Inbox-001', 'estimated': 20732},
        'opened_emails': {'path': PERSONAL_DIR / 'opened_emails', 'estimated': 7372},
        'starred_emails': {'path': PERSONAL_DIR / 'starred_emails', 'estimated': 476},
    },
    'mbox_files': {
        'Inbox-001.mbox': {'path': PERSONAL_DIR / 'Inbox-001.mbox', 'estimated': 20000},
        'Inbox-002.mbox': {'path': PERSONAL_DIR / 'Inbox-002.mbox', 'estimated': 200000},
        'Opened2.mbox': {'path': PERSONAL_DIR / 'Opened2.mbox', 'estimated': 15000},
        'Opened3.mbox': {'path': PERSONAL_DIR / 'Opened3.mbox', 'estimated': 15000},
        'Sent-003.mbox': {'path': PERSONAL_DIR / 'Sent-003.mbox', 'estimated': 30000},
        'Starred2.mbox': {'path': PERSONAL_DIR / 'Starred2.mbox', 'estimated': 700},
        'Starred3.mbox': {'path': PERSONAL_DIR / 'Starred3.mbox', 'estimated': 700},
    },
    'enron': {
        'path': BASE_DIR / 'enron' / 'scrubbed' / 'enron_corpus_scrubbed.json',
        'estimated': 517401
    }
}


def load_state():
    """Load rotation state from file."""
    if STATE_FILE.exists():
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    return {
        'rotation_number': 0,
        'processed_hashes': {},
        'source_progress': {},
        'aggregate_metrics': {
            'total_processed': 0,
            'intents': {},
            'confidence_sum': 0,
            'fallbacks': 0,
        },
        'run_history': []
    }


def save_state(state):
    """Save rotation state to file."""
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)


def get_email_hash(email):
    """Generate unique hash for an email to track processing."""
    key = f"{email.get('subject', '')[:50]}|{email.get('from', '')}|{email.get('body', '')[:100]}"
    return hashlib.md5(key.encode()).hexdigest()[:12]


def estimate_total_emails():
    """Estimate total available emails across all sources."""
    total = 0
    
    # EML directories
    for name, config in SOURCES['eml_directories'].items():
        if config['path'].exists():
            total += config['estimated']
    
    # MBOX files
    for name, config in SOURCES['mbox_files'].items():
        if config['path'].exists():
            total += config['estimated']
    
    # Enron
    total += SOURCES['enron']['estimated']
    
    return total


def calculate_coverage(state):
    """Calculate current coverage percentage."""
    total = estimate_total_emails()
    processed = len(state['processed_hashes'])
    return (processed / total) * 100 if total > 0 else 0


def get_next_rotation_batch(state, batch_size=BATCH_SIZE):
    """
    Get the next batch of emails for processing.
    Rotates through sources to ensure diversity.
    """
    batch = []
    rotation = state['rotation_number']
    
    # Calculate which source to prioritize this rotation
    sources_order = [
        ('eml', 'Inbox-001'),
        ('eml', 'opened_emails'),
        ('mbox', 'Starred2.mbox'),
        ('mbox', 'Starred3.mbox'),
        ('eml', 'starred_emails'),
        ('mbox', 'Opened2.mbox'),
        ('mbox', 'Opened3.mbox'),
        ('mbox', 'Inbox-001.mbox'),
        ('mbox', 'Sent-003.mbox'),
        ('mbox', 'Inbox-002.mbox'),  # Largest, process last
        ('enron', 'enron'),
    ]
    
    # Rotate starting point based on rotation number
    start_idx = rotation % len(sources_order)
    rotated_sources = sources_order[start_idx:] + sources_order[:start_idx]
    
    emails_needed = batch_size
    
    for source_type, source_name in rotated_sources:
        if emails_needed <= 0:
            break
            
        # Get progress for this source
        source_key = f"{source_type}_{source_name}"
        source_offset = state['source_progress'].get(source_key, 0)
        
        print(f"  Sampling from {source_name} (offset: {source_offset})...")
        
        if source_type == 'eml':
            config = SOURCES['eml_directories'].get(source_name)
            if config and config['path'].exists():
                eml_files = sorted(config['path'].glob('*.eml'))[source_offset:source_offset + emails_needed]
                for eml_path in eml_files:
                    email = parse_eml(eml_path)
                    if email:
                        email['_source'] = source_name
                        batch.append(email)
                state['source_progress'][source_key] = source_offset + len(eml_files)
                emails_needed -= len(eml_files)
                
        elif source_type == 'mbox':
            config = SOURCES['mbox_files'].get(source_name)
            if config and config['path'].exists():
                mbox_emails = parse_mbox_batch(config['path'], source_offset, emails_needed)
                for email in mbox_emails:
                    email['_source'] = source_name
                    batch.append(email)
                state['source_progress'][source_key] = source_offset + len(mbox_emails)
                emails_needed -= len(mbox_emails)
                
        elif source_type == 'enron':
            # Sample from Enron (already processed, just sample different parts)
            enron_path = SOURCES['enron']['path']
            if enron_path.exists():
                with open(enron_path, 'r') as f:
                    enron_data = json.load(f)
                # Random sample from different section each rotation
                section_size = len(enron_data) // 10
                section_start = (rotation % 10) * section_size
                section = enron_data[section_start:section_start + section_size]
                sample = random.sample(section, min(emails_needed, len(section)))
                for email in sample:
                    email['_source'] = 'enron'
                    batch.append(email)
                emails_needed -= len(sample)
    
    return batch


def parse_eml(filepath):
    """Parse a single .eml file."""
    try:
        with open(filepath, 'rb') as f:
            msg = BytesParser(policy=policy.default).parse(f)
        return {
            'subject': msg.get('Subject', '(No Subject)') or '(No Subject)',
            'from': msg.get('From', 'unknown') or 'unknown',
            'body': extract_body(msg)[:5000],
        }
    except Exception:
        return None


def parse_mbox_batch(mbox_path, offset, limit):
    """Parse a batch from an mbox file."""
    emails = []
    try:
        mbox = mailbox.mbox(str(mbox_path))
        for i, msg in enumerate(mbox):
            if i < offset:
                continue
            if len(emails) >= limit:
                break
            try:
                emails.append({
                    'subject': msg.get('Subject', '(No Subject)') or '(No Subject)',
                    'from': msg.get('From', 'unknown') or 'unknown', 
                    'body': extract_body(msg)[:5000],
                })
            except Exception:
                continue
        mbox.close()
    except Exception as e:
        print(f"    Error reading {mbox_path}: {e}")
    return emails


def extract_body(msg):
    """Extract email body."""
    import re
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain":
                try:
                    payload = part.get_payload(decode=True)
                    if payload:
                        body = payload.decode(part.get_content_charset() or 'utf-8', errors='replace')
                        break
                except Exception:
                    pass
    else:
        try:
            payload = msg.get_payload(decode=True)
            if payload:
                body = payload.decode(msg.get_content_charset() or 'utf-8', errors='replace')
        except Exception:
            body = str(msg.get_payload())
    return body.strip()


def print_coverage_report(state):
    """Print comprehensive coverage report."""
    total = estimate_total_emails()
    processed = state['aggregate_metrics']['total_processed']
    unique = len(state['processed_hashes'])
    
    print("\n" + "=" * 70)
    print("📊 COVERAGE REPORT")
    print("=" * 70)
    print(f"\nTotal available emails (estimated): {total:,}")
    print(f"Total processed (all rotations): {processed:,}")
    print(f"Unique emails processed: {unique:,}")
    print(f"Coverage: {calculate_coverage(state):.2f}%")
    print(f"Rotation number: {state['rotation_number']}")
    
    print("\n📁 Source Progress:")
    for source, offset in sorted(state['source_progress'].items()):
        print(f"  {source}: {offset:,} emails processed")
    
    if state['aggregate_metrics']['intents']:
        print("\n📈 Aggregate Intent Distribution (Top 10):")
        sorted_intents = sorted(
            state['aggregate_metrics']['intents'].items(),
            key=lambda x: x[1],
            reverse=True
        )[:10]
        for intent, count in sorted_intents:
            pct = (count / processed * 100) if processed > 0 else 0
            print(f"  {intent}: {count:,} ({pct:.1f}%)")
    
    # Recommendations
    rotations_for_full = (total // BATCH_SIZE) + 1
    print(f"\n💡 RECOMMENDATIONS:")
    print(f"  - Run {rotations_for_full} rotations for 100% coverage")
    print(f"  - Current progress: rotation {state['rotation_number']}/{rotations_for_full}")
    print(f"  - Consider processing larger batches for faster coverage")


def main():
    print("=" * 70)
    print("🔄 ROTATING SAMPLE BASELINE RUNNER")
    print("=" * 70)
    
    # Load state
    state = load_state()
    state['rotation_number'] += 1
    
    print(f"\n📍 Starting Rotation #{state['rotation_number']}")
    print(f"   Batch size: {BATCH_SIZE:,} emails")
    print(f"   Current coverage: {calculate_coverage(state):.2f}%")
    
    # Get next batch
    print("\n📧 Collecting next batch...")
    batch = get_next_rotation_batch(state, BATCH_SIZE)
    
    print(f"\n✅ Batch ready: {len(batch):,} emails")
    
    # Track unique emails
    new_emails = 0
    for email in batch:
        hash_val = get_email_hash(email)
        if hash_val not in state['processed_hashes']:
            state['processed_hashes'][hash_val] = True
            new_emails += 1
    
    print(f"   New unique emails: {new_emails:,}")
    print(f"   Previously seen: {len(batch) - new_emails:,}")
    
    # Update aggregate metrics
    state['aggregate_metrics']['total_processed'] += len(batch)
    
    # Record run
    state['run_history'].append({
        'rotation': state['rotation_number'],
        'timestamp': datetime.now().isoformat(),
        'batch_size': len(batch),
        'new_emails': new_emails,
    })
    
    # Save state
    save_state(state)
    
    # Output batch for baseline processing
    output_path = BASE_DIR / 'rotation_batches' / f'rotation_{state["rotation_number"]:03d}.json'
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Scrub PII before saving
    from scrub_personal_emails import scrub_pii
    scrubbed_batch = []
    for email in batch:
        scrubbed_batch.append({
            'subject': scrub_pii(email.get('subject', '')),
            'from': scrub_pii(email.get('from', '')),
            'body': scrub_pii(email.get('body', '')),
            'source': email.get('_source', 'unknown'),
        })
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(scrubbed_batch, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Batch saved to: {output_path}")
    
    # Print coverage report
    print_coverage_report(state)
    
    print("\n" + "=" * 70)
    print(f"✅ Rotation #{state['rotation_number']} Complete!")
    print("=" * 70)
    print(f"\nNext steps:")
    print(f"  1. Run baseline: node run_baseline.js --input {output_path}")
    print(f"  2. Run next rotation: python3 rotating_baseline.py")

if __name__ == '__main__':
    main()

