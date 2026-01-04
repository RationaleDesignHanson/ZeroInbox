# Future Corpus Sources for Continuous Improvement

## Personal Inbox Data (Ready to Process)

**Location**: `/Users/matthanson/Zer0_Inbox/emailcorpus/emailsfordeepsampling`

This folder contains personal inbox exports ready to be anonymized and added to the corpus for continuous improvement.

### Available Data

| Source | Format | Count | Notes |
|--------|--------|-------|-------|
| Inbox-001 | .eml | 20,732 | Individual email files |
| Inbox-001.mbox | mbox | 2.9 GB | Combined mailbox |
| Inbox-002.mbox | mbox | 26.1 GB | Large mailbox |
| opened_emails | .eml | 7,372 | Previously opened |
| Opened2/3.mbox | mbox | 1.9 GB each | |
| Sent-003.mbox | mbox | 4.3 GB | Sent emails |
| starred_emails | .eml | 476 | Important emails |
| Starred2/3.mbox | mbox | 86 MB each | |

**Total**: ~28,580+ emails across multiple formats

### Processing Instructions

When ready to add these emails:

1. **Create mbox Parser Script**:
   ```bash
   # New script needed for mbox format
   python3 emailcorpus/scripts/scrub_mbox_pii.py \
     --input emailcorpus/emailsfordeepsampling/Takeout/Mail/Inbox-001.mbox \
     --output emailcorpus/personal/scrubbed/inbox_001_scrubbed.json
   ```

2. **Validate Scrubbed Data**:
   ```bash
   python3 emailcorpus/scripts/validate_scrubbed.py \
     --input emailcorpus/personal/scrubbed/inbox_001_scrubbed.json
   ```

3. **Run Baseline on Personal Corpus**:
   ```bash
   node emailcorpus/scripts/run_baseline.js \
     --input emailcorpus/personal/scrubbed/inbox_001_scrubbed.json \
     --output emailcorpus/personal/baseline_personal.json
   ```

4. **Merge and Compare**:
   - Compare metrics against Enron baseline
   - Identify new intent patterns
   - Add to training data as needed

### Why Personal Emails Improve the Product

- **Modern email patterns**: Shopping confirmations, travel bookings, subscriptions
- **Consumer diversity**: Different from Enron's corporate email style
- **Real-world edge cases**: Various email clients, formatting, languages
- **Better intent coverage**: Categories not well-represented in Enron corpus

### Priority Categories to Capture

From personal inboxes, focus on:
- E-commerce (orders, shipping, returns)
- Travel (flights, hotels, reservations)
- Financial (bills, statements, payments)
- Subscriptions (newsletters, notifications)
- Social (notifications from platforms)
- Calendar/Events (invitations, reminders)

### Current Baseline Comparison

| Metric | Enron Baseline | Target for Personal |
|--------|----------------|---------------------|
| Non-fallback Rate | 94.5% | ≥90% |
| Thread Detection | 80.1% | <50% (more diverse) |
| E-commerce Intents | 0.9% | >10% |
| Travel Intents | 0% | >5% |

---

*This file documents future corpus sources. Process when ready to improve classifier accuracy.*

