#!/usr/bin/env python3
"""
Create Golden Test Set

Creates a curated test set from the processed corpus with:
1. Representative samples from each intent category
2. Edge cases (short emails, creative subjects, etc.)
3. Known fallback cases for improvement tracking

This test set can be used for regression testing after classifier changes.
"""

import json
import random
from pathlib import Path
from collections import defaultdict
from datetime import datetime

BASE_DIR = Path('/Users/matthanson/Zer0_Inbox/emailcorpus')

# Load the complete personal corpus
PERSONAL_CORPUS = BASE_DIR / 'personal' / 'scrubbed' / 'personal_corpus_complete.json'
ENRON_CORPUS = BASE_DIR / 'enron' / 'scrubbed' / 'enron_corpus_scrubbed.json'
OUTPUT_DIR = BASE_DIR / 'golden_test_set'
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Target samples per category
SAMPLES_PER_CATEGORY = 10
EDGE_CASE_SAMPLES = 20
TOTAL_TARGET = 200

def categorize_email(email):
    """Simple categorization based on subject/body patterns."""
    subject = (email.get('subject') or '').lower()
    body = (email.get('body') or '').lower()
    from_addr = (email.get('from') or '').lower()
    full_text = f"{subject} {body} {from_addr}"
    
    # Marketing/Promotional
    if any(x in full_text for x in ['sale', 'discount', '% off', 'deal', 'promo', 'limited time', 'shop now']):
        return 'marketing.promotion'
    if any(x in full_text for x in ['new arrival', 'new collection', 'just dropped', 'launching']):
        return 'marketing.new-arrivals'
    if any(x in full_text for x in ['reward', 'points', 'loyalty', 'member exclusive']):
        return 'marketing.loyalty'
    
    # E-commerce
    if any(x in full_text for x in ['order confirm', 'your order', 'shipped', 'delivery', 'tracking']):
        return 'ecommerce.order'
    if any(x in full_text for x in ['back in stock', 'restock', 'available now']):
        return 'ecommerce.restock'
    
    # Travel
    if any(x in full_text for x in ['flight', 'boarding', 'check-in', 'airline', 'airport']):
        return 'travel.flight'
    if any(x in full_text for x in ['hotel', 'reservation', 'booking confirm']):
        return 'travel.hotel'
    
    # Finance
    if any(x in full_text for x in ['payment', 'bill', 'invoice', 'statement', 'balance']):
        return 'finance.payment'
    if any(x in full_text for x in ['tax', '1099', 'w-2', 'irs']):
        return 'finance.tax'
    
    # Education
    if any(x in full_text for x in ['grade', 'assignment', 'class', 'school', 'teacher', 'student']):
        return 'education.school'
    if any(x in full_text for x in ['course', 'lesson', 'learning', 'certificate']):
        return 'education.learning'
    
    # Social
    if any(x in full_text for x in ['posted', 'liked', 'commented', 'followed', 'tagged']):
        return 'social.notification'
    
    # Calendar/Events
    if any(x in full_text for x in ['meeting', 'calendar', 'appointment', 'rsvp', 'event']):
        return 'calendar.event'
    
    # Thread replies
    if subject.startswith('re:') or subject.startswith('fwd:'):
        return 'communication.thread'
    
    # Newsletter
    if any(x in full_text for x in ['newsletter', 'digest', 'weekly', 'roundup', 'update from']):
        return 'content.newsletter'
    
    # Political/Civic
    if any(x in full_text for x in ['donate', 'campaign', 'vote', 'election', 'political']):
        return 'civic.political'
    
    # Healthcare
    if any(x in full_text for x in ['appointment', 'doctor', 'prescription', 'health', 'medical']):
        return 'healthcare.general'
    
    # Personal
    if len(subject) < 20 and 'newsletter' not in subject:
        return 'communication.personal'
    
    return 'other'


def identify_edge_cases(email):
    """Identify edge cases for special testing."""
    subject = email.get('subject') or ''
    body = email.get('body') or ''
    
    edge_cases = []
    
    # Short subject
    if len(subject) < 10:
        edge_cases.append('short_subject')
    
    # Very long subject
    if len(subject) > 100:
        edge_cases.append('long_subject')
    
    # No subject
    if not subject or subject == '(No Subject)':
        edge_cases.append('no_subject')
    
    # Creative/vague subject (no clear keywords)
    if len(subject) > 10 and not any(x in subject.lower() for x in ['order', 'confirm', 'ship', 'sale', 'meeting', 're:', 'fwd:']):
        edge_cases.append('creative_subject')
    
    # Emoji in subject
    if any(ord(c) > 127 for c in subject):
        edge_cases.append('emoji_subject')
    
    # Very short body
    if len(body) < 50:
        edge_cases.append('short_body')
    
    # Very long body
    if len(body) > 5000:
        edge_cases.append('long_body')
    
    return edge_cases


def main():
    print("=" * 70)
    print("🎯 Creating Golden Test Set")
    print("=" * 70)
    
    # Load corpora
    print("\n📂 Loading corpora...")
    
    personal_emails = []
    if PERSONAL_CORPUS.exists():
        with open(PERSONAL_CORPUS, 'r') as f:
            personal_emails = json.load(f)
        print(f"   Personal corpus: {len(personal_emails):,} emails")
    
    enron_emails = []
    if ENRON_CORPUS.exists():
        with open(ENRON_CORPUS, 'r') as f:
            enron_emails = json.load(f)
        print(f"   Enron corpus: {len(enron_emails):,} emails")
    
    # Sample from Enron (it's huge)
    if len(enron_emails) > 50000:
        enron_sample = random.sample(enron_emails, 50000)
    else:
        enron_sample = enron_emails
    
    # Combine
    all_emails = personal_emails + enron_sample
    print(f"\n   Working with: {len(all_emails):,} emails")
    
    # Categorize all emails
    print("\n📊 Categorizing emails...")
    categories = defaultdict(list)
    edge_cases_by_type = defaultdict(list)
    
    for email in all_emails:
        category = categorize_email(email)
        categories[category].append(email)
        
        edges = identify_edge_cases(email)
        for edge in edges:
            edge_cases_by_type[edge].append(email)
    
    print(f"   Found {len(categories)} categories:")
    for cat, emails in sorted(categories.items(), key=lambda x: -len(x[1])):
        print(f"     {cat}: {len(emails):,}")
    
    print(f"\n   Edge cases identified:")
    for edge, emails in sorted(edge_cases_by_type.items(), key=lambda x: -len(x[1])):
        print(f"     {edge}: {len(emails):,}")
    
    # Build golden test set
    print("\n🔨 Building golden test set...")
    
    golden_set = []
    
    # 1. Sample from each category
    for category, emails in categories.items():
        sample_size = min(SAMPLES_PER_CATEGORY, len(emails))
        samples = random.sample(emails, sample_size)
        for email in samples:
            golden_set.append({
                **email,
                '_test_category': category,
                '_test_type': 'category_sample'
            })
    
    # 2. Add edge cases
    for edge_type, emails in edge_cases_by_type.items():
        sample_size = min(5, len(emails))
        samples = random.sample(emails, sample_size)
        for email in samples:
            if email not in [e for e in golden_set if e.get('subject') == email.get('subject')]:
                golden_set.append({
                    **email,
                    '_test_category': f'edge_case.{edge_type}',
                    '_test_type': 'edge_case'
                })
    
    # 3. Ensure diversity by shuffling and trimming
    random.shuffle(golden_set)
    if len(golden_set) > TOTAL_TARGET:
        golden_set = golden_set[:TOTAL_TARGET]
    
    print(f"   Golden set size: {len(golden_set)} emails")
    
    # Save golden test set
    output_file = OUTPUT_DIR / 'golden_test_set.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(golden_set, f, indent=2, ensure_ascii=False)
    
    # Create summary
    summary = {
        'timestamp': datetime.now().isoformat(),
        'total_emails': len(golden_set),
        'source_corpus': {
            'personal': len(personal_emails),
            'enron_sample': len(enron_sample)
        },
        'categories': {cat: len([e for e in golden_set if e.get('_test_category') == cat]) 
                       for cat in set(e.get('_test_category') for e in golden_set)},
        'edge_cases': {edge: len([e for e in golden_set if edge in (e.get('_test_category') or '')])
                      for edge in edge_cases_by_type.keys()},
    }
    
    summary_file = OUTPUT_DIR / 'golden_test_set.summary.json'
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    
    print(f"\n💾 Saved to:")
    print(f"   {output_file}")
    print(f"   {summary_file}")
    
    # Print category breakdown
    print("\n📊 Golden Set Composition:")
    for cat, count in sorted(summary['categories'].items(), key=lambda x: -x[1]):
        print(f"   {cat}: {count}")
    
    print("\n" + "=" * 70)
    print("✅ Golden Test Set Created!")
    print("=" * 70)
    print(f"\nTotal: {len(golden_set)} emails")
    print(f"Categories: {len(summary['categories'])}")
    print(f"\nUse this for regression testing after classifier changes.")

if __name__ == '__main__':
    main()

