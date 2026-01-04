# Email Corpus Coverage Analysis

**Date**: December 17, 2025

---

## Available Email Sources

### Personal Inbox Data (`emailsfordeepsampling/Takeout/Mail/`)

| Source | Format | Count | Size | Status |
|--------|--------|-------|------|--------|
| **Inbox-001/** | .eml | 20,732 | - | ✅ Partially processed (5K) |
| **opened_emails/** | .eml | 7,372 | - | ❌ Not yet processed |
| **starred_emails/** | .eml | 476 | - | ❌ Not yet processed |
| **Inbox-001.mbox** | mbox | ~20K est. | 2.9 GB | ❌ Not yet processed |
| **Inbox-002.mbox** | mbox | ~200K est. | 26.1 GB | ❌ Not yet processed |
| **Opened2.mbox** | mbox | ~15K est. | 1.9 GB | ❌ Not yet processed |
| **Opened3.mbox** | mbox | ~15K est. | 1.9 GB | ❌ Not yet processed |
| **Sent-003.mbox** | mbox | ~30K est. | 4.3 GB | ❌ Not yet processed |
| **Starred2.mbox** | mbox | ~700 est. | 86 MB | ❌ Not yet processed |
| **Starred3.mbox** | mbox | ~700 est. | 86 MB | ❌ Not yet processed |

**Personal Total**: ~310,000+ emails estimated

### Enron Corpus

| Source | Format | Count | Size | Status |
|--------|--------|-------|------|--------|
| **enron_corpus_scrubbed.json** | JSON | 517,401 | 871 MB | ✅ Fully processed |

**Enron Total**: 517,401 emails

---

## Current Processing Status

| Corpus | Processed | Available | Coverage |
|--------|-----------|-----------|----------|
| Personal | 5,000 | ~310,000 | **1.6%** |
| Enron | 517,401 | 517,401 | **100%** |
| **TOTAL** | 522,401 | ~827,000 | **63%** |

### ⚠️ Gap Analysis

**Unprocessed personal emails**: ~305,000+

This represents significant untapped data that could improve:
- Consumer email pattern recognition
- E-commerce classification
- Marketing/promotional detection
- Calendar/event handling
- Financial notification accuracy

---

## Rotating Sample Strategy

To achieve 100% coverage without memory constraints:

### Approach

```
Total emails: ~827,000
Batch size: 5,000 emails
Rotations needed: ~166 for full coverage
```

### Rotation Schedule

| Rotation | Source | Emails | Cumulative |
|----------|--------|--------|------------|
| 1-4 | Inbox-001/*.eml | 20,732 | 20,732 |
| 5-6 | opened_emails/*.eml | 7,372 | 28,104 |
| 7 | starred_emails/*.eml | 476 | 28,580 |
| 8 | Starred2.mbox + Starred3.mbox | 1,400 | 29,980 |
| 9-14 | Opened2.mbox + Opened3.mbox | 30,000 | 59,980 |
| 15-20 | Inbox-001.mbox | 20,000 | 79,980 |
| 21-26 | Sent-003.mbox | 30,000 | 109,980 |
| 27-66 | Inbox-002.mbox | 200,000 | 309,980 |
| 67-166 | Enron (rotating sections) | 517,401 | 827,381 |

### Usage

```bash
# Run each rotation
python3 emailcorpus/scripts/rotating_baseline.py

# Run baseline on rotation batch
node emailcorpus/scripts/run_baseline.js \
  --input emailcorpus/rotation_batches/rotation_001.json \
  --output emailcorpus/rotation_batches/rotation_001_results.json

# Repeat for comprehensive coverage
```

---

## Recommendations

### Immediate Actions

1. **Process all .eml directories first** (28,580 emails)
   - Fastest to parse
   - Good diversity of consumer emails
   - Command: `python3 scrub_personal_emails.py --limit 30000`

2. **Process smaller mbox files** (Starred2/3, Opened2/3)
   - ~32,000 additional emails
   - Moderate processing time

3. **Process largest files last** (Inbox-002.mbox)
   - 26 GB, ~200K emails
   - May need chunked processing

### Automated Testing Strategy

```python
# Run automated nightly rotations
# Each rotation processes 5K new emails
# Full coverage in ~166 rotations (~6 months daily)

# Or: Parallel processing for faster coverage
# 10 rotations/day = full coverage in ~17 days
```

### Metric Aggregation

After each rotation, metrics aggregate:
- Intent distribution across ALL processed emails
- Confidence score trends
- Fallback rate by email source
- Processing time benchmarks

---

## Scripts Available

| Script | Purpose |
|--------|---------|
| `scrub_personal_emails.py` | PII scrubbing for personal emails |
| `scrub_enron_pii.py` | PII scrubbing for Enron corpus |
| `validate_scrubbed.py` | Validate no PII remains |
| `run_baseline.js` | Run classifier baseline |
| `rotating_baseline.py` | Rotating sample manager |
| `merge_corpora.py` | Merge multiple sources |
| `analyze_available_sources.py` | Analyze all available data |

---

## Files Generated

```
emailcorpus/
├── enron/
│   ├── scrubbed/enron_corpus_scrubbed.json (517K emails)
│   └── baseline_results.json
├── personal/
│   ├── scrubbed/personal_corpus.json (5K emails)
│   └── baseline_personal.json
├── combined/
│   └── combined_sample_10k.json (15K emails)
├── rotation_batches/
│   └── rotation_XXX.json (rotating samples)
├── rotation_state.json (tracks progress)
├── BASELINE_REPORT.md
├── COVERAGE_ANALYSIS.md
└── FUTURE_CORPUS_SOURCES.md
```

---

*This analysis ensures no email data goes unused. The rotating sample strategy guarantees 100% coverage over time while respecting memory and processing constraints.*

