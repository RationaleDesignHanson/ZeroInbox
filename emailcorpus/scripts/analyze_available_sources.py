#!/usr/bin/env python3
"""
Analyze all available email sources and calculate coverage.
"""

import os
import mailbox
from pathlib import Path
from collections import defaultdict

BASE_DIR = Path('/Users/matthanson/Zer0_Inbox/emailcorpus/emailsfordeepsampling/Takeout/Mail')

def count_mbox_emails(mbox_path):
    """Count emails in an mbox file without loading all into memory."""
    try:
        mbox = mailbox.mbox(str(mbox_path))
        count = len(mbox)
        mbox.close()
        return count
    except Exception as e:
        return f"Error: {e}"

def analyze_sources():
    print("=" * 70)
    print("📊 COMPLETE EMAIL SOURCE ANALYSIS")
    print("=" * 70)
    print(f"\nScanning: {BASE_DIR}\n")
    
    sources = defaultdict(dict)
    total_available = 0
    
    # Analyze .eml directories
    eml_dirs = ['Inbox-001', 'opened_emails', 'starred_emails']
    for dir_name in eml_dirs:
        dir_path = BASE_DIR / dir_name
        if dir_path.exists():
            eml_count = len(list(dir_path.glob('*.eml')))
            sources['eml_directories'][dir_name] = eml_count
            total_available += eml_count
            print(f"📂 {dir_name}/")
            print(f"   .eml files: {eml_count:,}")
    
    print()
    
    # Analyze .mbox files
    mbox_files = list(BASE_DIR.glob('*.mbox'))
    for mbox_path in sorted(mbox_files):
        size_mb = mbox_path.stat().st_size / (1024 * 1024)
        count = count_mbox_emails(mbox_path)
        sources['mbox_files'][mbox_path.name] = {
            'size_mb': round(size_mb, 1),
            'count': count if isinstance(count, int) else 0
        }
        if isinstance(count, int):
            total_available += count
        print(f"📦 {mbox_path.name}")
        print(f"   Size: {size_mb:,.1f} MB")
        print(f"   Emails: {count:,}" if isinstance(count, int) else f"   Status: {count}")
    
    print("\n" + "=" * 70)
    print("📈 SUMMARY")
    print("=" * 70)
    
    # EML totals
    eml_total = sum(sources['eml_directories'].values())
    print(f"\n.eml files total: {eml_total:,}")
    
    # MBOX totals
    mbox_total = sum(v['count'] for v in sources['mbox_files'].values())
    mbox_size = sum(v['size_mb'] for v in sources['mbox_files'].values())
    print(f".mbox files total: {mbox_total:,} emails ({mbox_size:,.1f} MB)")
    
    print(f"\n🎯 TOTAL AVAILABLE EMAILS: {total_available:,}")
    
    # Current coverage
    print("\n" + "=" * 70)
    print("📊 CURRENT PROCESSING STATUS")
    print("=" * 70)
    
    processed_personal = 5000  # From our scrub run
    processed_enron = 517401
    
    print(f"\nPersonal corpus processed: {processed_personal:,}")
    print(f"Enron corpus processed: {processed_enron:,}")
    print(f"Total processed: {processed_personal + processed_enron:,}")
    
    remaining = total_available - processed_personal
    if remaining > 0:
        print(f"\n⚠️  UNPROCESSED PERSONAL EMAILS: {remaining:,}")
        coverage_pct = (processed_personal / total_available) * 100
        print(f"   Current coverage: {coverage_pct:.1f}%")
    
    return sources, total_available

if __name__ == '__main__':
    analyze_sources()

