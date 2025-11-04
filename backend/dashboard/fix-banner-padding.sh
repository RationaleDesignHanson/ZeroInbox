#!/bin/bash
#
# Fix banner overlap by ensuring all pages with beta-banner have proper padding-top
#

cd /Users/matthanson/Zer0_Inbox/backend/dashboard

echo "Fixing banner padding for all pages..."

# Pages with beta banner that need fixing
FILES=(
    "action-modal-explorer.html"
    "intent-action-explorer.html"
    "shopping-cart.html"
    "system-health.html"
    "zero-sequence-live.html"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."

        # Use perl to add padding-top: 80px to body selector
        # 80px accounts for banner height (12+35+12 = ~59px) + 20px buffer for wrapping on mobile
        perl -i -pe 's/(body\s*\{[^}]*?)(background:)/$1padding-top: 80px;\n            $2/s' "$file" 2>/dev/null || \
        perl -i -pe 's/(body\s*\{)/$1\n            padding-top: 80px;/' "$file"

        echo "  ✓ Added padding-top to $file"
    else
        echo "  ⚠ $file not found"
    fi
done

echo ""
echo "✓ Banner padding fix complete!"
echo ""
