#!/usr/bin/env python3
"""
Merge Enron and Personal corpora into a combined dataset.
Also provides corpus statistics.
"""

import json
import random
from pathlib import Path
from datetime import datetime

BASE_DIR = Path('/Users/matthanson/Zer0_Inbox/emailcorpus')

ENRON_PATH = BASE_DIR / 'enron' / 'scrubbed' / 'enron_corpus_scrubbed.json'
PERSONAL_PATH = BASE_DIR / 'personal' / 'scrubbed' / 'personal_corpus.json'
OUTPUT_PATH = BASE_DIR / 'combined' / 'combined_corpus.json'
SAMPLE_OUTPUT = BASE_DIR / 'combined' / 'combined_sample_10k.json'

def main():
    print("=" * 60)
    print("🔄 Merging Email Corpora")
    print("=" * 60)
    
    # Load personal corpus (smaller, load fully)
    print("\n📂 Loading Personal Corpus...")
    with open(PERSONAL_PATH, 'r', encoding='utf-8') as f:
        personal = json.load(f)
    print(f"   Personal emails: {len(personal):,}")
    
    # Sample from Enron corpus (too large for memory)
    print("\n📂 Sampling Enron Corpus...")
    enron_sample = []
    
    with open(ENRON_PATH, 'r', encoding='utf-8') as f:
        enron = json.load(f)
    
    print(f"   Enron emails (total): {len(enron):,}")
    
    # Sample 10K from Enron for combined corpus
    sample_size = min(10000, len(enron))
    enron_sample = random.sample(enron, sample_size)
    print(f"   Enron sample: {len(enron_sample):,}")
    
    # Create output directory
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    
    # Combine corpora
    print("\n🔀 Combining corpora...")
    combined = personal + enron_sample
    random.shuffle(combined)
    
    # Add source tags
    for email in personal:
        email['source'] = 'personal'
    for email in enron_sample:
        email['source'] = 'enron'
    
    print(f"   Combined total: {len(combined):,}")
    
    # Write combined sample
    print(f"\n💾 Writing to {SAMPLE_OUTPUT}...")
    with open(SAMPLE_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(combined, f, indent=2, ensure_ascii=False)
    
    # Stats
    file_size = SAMPLE_OUTPUT.stat().st_size / (1024 * 1024)
    print(f"   File size: {file_size:.1f} MB")
    
    # Create report
    report = {
        'timestamp': datetime.now().isoformat(),
        'personal_count': len(personal),
        'enron_sample_count': len(enron_sample),
        'combined_count': len(combined),
        'output_file': str(SAMPLE_OUTPUT),
    }
    
    report_path = SAMPLE_OUTPUT.with_suffix('.report.json')
    with open(report_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2)
    
    print("\n" + "=" * 60)
    print("✅ Merge Complete!")
    print("=" * 60)
    print(f"Personal emails: {len(personal):,}")
    print(f"Enron sample: {len(enron_sample):,}")
    print(f"Combined total: {len(combined):,}")
    print(f"\nOutput: {SAMPLE_OUTPUT}")

if __name__ == '__main__':
    main()

