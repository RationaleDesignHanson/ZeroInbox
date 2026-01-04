#!/bin/bash
# Quick progress checker

echo "📊 Processing Progress Check"
echo "=============================="
echo ""

if [ -f "/Users/matthanson/Zer0_Inbox/emailcorpus/personal/scrubbed/personal_corpus_complete.json" ]; then
    COUNT=$(python3 -c "import json; f=open('/Users/matthanson/Zer0_Inbox/emailcorpus/personal/scrubbed/personal_corpus_complete.json'); print(len(json.load(f)))" 2>/dev/null)
    SIZE=$(du -h /Users/matthanson/Zer0_Inbox/emailcorpus/personal/scrubbed/personal_corpus_complete.json | cut -f1)
    echo "✅ Complete corpus exists: $COUNT emails ($SIZE)"
else
    echo "⏳ Complete corpus not yet created..."
fi

echo ""
echo "Recent log output:"
tail -20 /tmp/process_all.log 2>/dev/null || echo "No log file yet"

