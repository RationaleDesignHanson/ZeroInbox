# Zero - Complete App Store Submission Checklist

## 1. Privacy Policy URL ✅
**What to enter:** `https://zero-dashboard-514014482017.us-central1.run.app/privacy.html`

**Action needed:** Upload the privacy.html file to your dashboard deployment
- File location: `/Users/matthanson/Zer0_Inbox/Zero_ios_2/privacy.html`
- Deploy to: Your Google Cloud dashboard

## 2. iPad Screenshots (13-inch displays) ⚠️
**Required sizes:**
- 2048 × 2732px (portrait)
- 2732 × 2048px (landscape)

**Options:**
- Use iPhone screenshots scaled up (not ideal but acceptable)
- Mark as "iPad not supported" if iOS app is iPhone-only
- Generate iPad-specific screenshots if you have iPad support

## 3. Contact Information 📞
**What to enter:**
```
First Name: [Your first name]
Last Name: [Your last name]
Email: [Your support email]
Phone: [Your phone number with country code]
```

## 4. Content Rights Information ©️
**What to select:**
- ✅ "I own the rights to all content in my app"
OR
- ✅ "I have the rights to use all content and comply with the terms in any applicable license agreements"

**For Zero app, select:** "I own the rights" (since Rationale Design owns all assets)

## 5. Age Rating Frequency Selections 🔞
**For Zero Email App, select:**

| Content Type | Frequency |
|--------------|-----------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |

**Unrestricted Web Access:** NO
**Gambling and Contests:** NO

**Recommended Age Rating:** 4+ (No objectionable content)

## 6. App Privacy Practices 🔒

### Data Collection
**Does your app collect data?** YES

### Data Types Collected:

#### Contact Info
- **Email Address**
  - Purpose: App Functionality
  - Linked to User: NO
  - Used for Tracking: NO

#### User Content
- **Emails or Text Messages**
  - Purpose: App Functionality
  - Linked to User: NO
  - Used for Tracking: NO

#### Usage Data
- **Product Interaction**
  - Purpose: Analytics, App Functionality
  - Linked to User: NO
  - Used for Tracking: NO

### Data Collection Details:
```
Zero processes your email data to provide AI-powered categorization and
action suggestions. Your email data is:

- Processed using OpenAI or Gemini APIs (user-provided keys)
- NOT stored on Zero's servers
- NOT shared with third parties
- NOT used for advertising or tracking
- Only accessible through your own API credentials

API keys are stored securely on your device via environment variables.
Zero does not collect, store, or have access to your API credentials.
```

## 7. Primary Category 📱
**Select:** Productivity

**Secondary Category (optional):** Utilities

## 8. Pricing 💰
**Recommended for v1.0:**

Option A: **Free** (Recommended for initial launch)
- Builds user base quickly
- Gets feedback before monetization
- Can add IAP later

Option B: **Paid**
- Price tier: $0.99 - $4.99
- Users pay upfront for premium features

Option C: **Free with IAP**
- Free download
- Premium features via subscription or one-time purchase

**Recommendation:** Start with **FREE** to gain traction

## 9. App Icon Issue 🎨

### Problem
The old icon is showing instead of the new glassmorphic zero icon.

### Solution
Check these locations:

1. **Xcode Asset Catalog**
   - Location: `Zero_ios_2/Zero/Zero/Assets.xcassets/AppIcon.appiconset/`
   - Verify: `icon-1024.png` is the new icon (should be 1.7M, dated Nov 18)

2. **Clean and Rebuild**
   ```bash
   cd /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero
   xcodebuild clean -workspace Zero.xcworkspace -scheme Zero
   ```

3. **Verify in Xcode**
   - Open project in Xcode
   - Go to Assets.xcassets > AppIcon
   - Confirm the new purple glassmorphic icon appears
   - Delete derived data if needed

4. **Archive for App Store**
   - Product > Archive in Xcode
   - The archived build will use the correct icon
   - The simulator may cache old icons

### Quick Check
```bash
sips -g pixelWidth -g pixelHeight /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Zero/Assets.xcassets/AppIcon.appiconset/icon-1024.png
open /Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Zero/Assets.xcassets/AppIcon.appiconset/icon-1024.png
```

---

## Quick Submission Summary

### Fill in App Store Connect:

1. **Privacy Policy URL:** `https://zero-dashboard-514014482017.us-central1.run.app/privacy.html`
2. **Support URL:** `https://zero-dashboard-514014482017.us-central1.run.app`
3. **Marketing URL:** `https://zero-dashboard-514014482017.us-central1.run.app`
4. **Category:** Productivity (Primary)
5. **Age Rating:** 4+
6. **Pricing:** Free
7. **Copyright:** 2025 Rationale Design
8. **Content Rights:** "I own the rights to all content"

### Contact Info Example:
```
First Name: [Your Name]
Last Name: [Your Name]
Email: support@rationaledesign.com (or your email)
Phone: +1-XXX-XXX-XXXX
```

---

## Next Steps

1. ✅ Deploy privacy.html to dashboard
2. ⚠️ Decide on iPad support (or mark iPhone-only)
3. ✅ Fill in all App Store Connect fields using info above
4. ✅ Verify app icon in Xcode
5. ✅ Create Archive build
6. ✅ Upload to App Store Connect
7. ✅ Submit for review

**Estimated time to complete:** 30-45 minutes
