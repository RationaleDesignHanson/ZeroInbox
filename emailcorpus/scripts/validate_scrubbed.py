#!/usr/bin/env python3
"""
Validate Scrubbed Corpus

Spot-checks the scrubbed Enron corpus for:
1. Remaining PII (should be zero)
2. Required fields present
3. Data integrity

Usage:
    python validate_scrubbed.py [--input PATH] [--sample N]
"""

import argparse
import json
import random
import re
import sys
from typing import Dict, List, Tuple

DEFAULT_INPUT = "/Users/matthanson/Zer0_Inbox/emailcorpus/enron/scrubbed/enron_corpus_scrubbed.json"
DEFAULT_SAMPLE = 100

# PII detection patterns (same as scrubber)
PII_PATTERNS = {
    'raw_enron_email': re.compile(r'@enron\.com|@ect\.enron\.com', re.IGNORECASE),
    'ssn_pattern': re.compile(r'\b\d{3}-\d{2}-\d{4}\b'),
    'credit_card': re.compile(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'),
    'common_enron_names': re.compile(r'\b(Kenneth Lay|Jeff Skilling|Andrew Fastow)\b', re.IGNORECASE),
}


def check_pii(text: str) -> List[Tuple[str, str]]:
    """Check text for remaining PII. Returns list of (pattern_name, match)."""
    if not text:
        return []
    
    findings = []
    for name, pattern in PII_PATTERNS.items():
        matches = pattern.findall(text)
        for match in matches:
            findings.append((name, match if isinstance(match, str) else str(match)))
    
    return findings


def validate_email(email: Dict, index: int) -> Dict:
    """Validate a single email. Returns dict with validation results."""
    result = {
        'index': index,
        'valid': True,
        'issues': [],
        'pii_found': []
    }
    
    # Check required fields
    if not email.get('subject'):
        result['issues'].append('missing_subject')
    if not email.get('from'):
        result['issues'].append('missing_from')
        result['valid'] = False
    
    # Check for remaining PII
    full_text = f"{email.get('subject', '')} {email.get('from', '')} {email.get('body', '')}"
    pii = check_pii(full_text)
    if pii:
        result['pii_found'] = pii
        result['valid'] = False
    
    # Check data types
    if email.get('subject') and not isinstance(email['subject'], str):
        result['issues'].append('subject_not_string')
    if email.get('from') and not isinstance(email['from'], str):
        result['issues'].append('from_not_string')
    if email.get('body') and not isinstance(email['body'], str):
        result['issues'].append('body_not_string')
    
    return result


def main():
    parser = argparse.ArgumentParser(description='Validate scrubbed corpus')
    parser.add_argument('--input', '-i', default=DEFAULT_INPUT, help='Input JSON file')
    parser.add_argument('--sample', '-s', type=int, default=DEFAULT_SAMPLE, help='Number of random samples')
    parser.add_argument('--full', '-f', action='store_true', help='Check all emails (slow)')
    args = parser.parse_args()
    
    print(f"🔍 Validating Scrubbed Corpus")
    print(f"=" * 50)
    print(f"Input: {args.input}")
    print()
    
    # Load corpus
    print("Loading corpus...")
    with open(args.input, 'r', encoding='utf-8') as f:
        corpus = json.load(f)
    
    total_emails = len(corpus)
    print(f"Total emails: {total_emails:,}")
    print()
    
    # Determine sample
    if args.full:
        sample_indices = list(range(total_emails))
        print(f"Checking all {total_emails:,} emails...")
    else:
        sample_size = min(args.sample, total_emails)
        sample_indices = random.sample(range(total_emails), sample_size)
        print(f"Checking random sample of {sample_size} emails...")
    
    # Validate
    stats = {
        'checked': 0,
        'valid': 0,
        'invalid': 0,
        'pii_found': 0,
        'missing_subject': 0,
        'missing_from': 0,
        'pii_examples': []
    }
    
    for i, idx in enumerate(sample_indices):
        email = corpus[idx]
        result = validate_email(email, idx)
        
        stats['checked'] += 1
        if result['valid']:
            stats['valid'] += 1
        else:
            stats['invalid'] += 1
        
        if result['pii_found']:
            stats['pii_found'] += 1
            if len(stats['pii_examples']) < 5:
                stats['pii_examples'].append({
                    'index': idx,
                    'subject': email.get('subject', '')[:50],
                    'pii': result['pii_found'][:3]
                })
        
        if 'missing_subject' in result['issues']:
            stats['missing_subject'] += 1
        if 'missing_from' in result['issues']:
            stats['missing_from'] += 1
        
        # Progress
        if (i + 1) % 10000 == 0:
            print(f"  Checked {i+1:,}/{len(sample_indices):,}...")
    
    print()
    print(f"✅ Validation Complete")
    print(f"=" * 50)
    print(f"Emails checked: {stats['checked']:,}")
    print(f"Valid: {stats['valid']:,}")
    print(f"Invalid: {stats['invalid']:,}")
    print(f"PII found in: {stats['pii_found']:,} emails")
    print(f"Missing subject: {stats['missing_subject']:,}")
    print(f"Missing from: {stats['missing_from']:,}")
    print()
    
    if stats['pii_examples']:
        print(f"⚠️  PII Examples Found:")
        for ex in stats['pii_examples']:
            print(f"  Index {ex['index']}: {ex['subject']}")
            for pattern, match in ex['pii']:
                print(f"    - {pattern}: {match}")
        print()
    
    # Summary verdict
    if stats['pii_found'] == 0 and stats['missing_from'] == 0:
        print(f"🎉 PASS: Corpus validation successful!")
        print(f"   - No PII detected in sample")
        print(f"   - All required fields present")
        return 0
    else:
        print(f"⚠️  ISSUES FOUND:")
        if stats['pii_found'] > 0:
            print(f"   - PII detected in {stats['pii_found']} emails")
        if stats['missing_from'] > 0:
            print(f"   - Missing 'from' field in {stats['missing_from']} emails")
        return 1


if __name__ == '__main__':
    sys.exit(main())

