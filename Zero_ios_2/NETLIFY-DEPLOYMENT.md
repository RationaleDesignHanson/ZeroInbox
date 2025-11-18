# Netlify Deployment Guide for Zero Inbox

**Time Required:** 5 minutes
**Files Ready:** ✅ index.html, privacy.html, terms.html

---

## 🚀 Option 1: Deploy via Netlify Web UI (Easiest - 3 minutes)

### Step 1: Create a Deployment Folder

```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2
mkdir netlify-deploy
cp index.html netlify-deploy/
cp privacy.html netlify-deploy/
cp terms.html netlify-deploy/
```

Or simply use Finder:
1. Open `/Users/matthanson/Zer0_Inbox/Zero_ios_2` in Finder
2. Create a new folder called `netlify-deploy`
3. Copy `index.html`, `privacy.html`, and `terms.html` into it

### Step 2: Deploy to Netlify

1. **Go to** [app.netlify.com](https://app.netlify.com)
2. **Log in** to your Netlify account
3. **Click** "Add new site" → "Deploy manually"
4. **Drag and drop** the `netlify-deploy` folder onto the upload area
5. **Wait** for deployment to complete (30 seconds)

### Step 3: Get Your URLs

After deployment, you'll see:
- **Your site URL:** `https://random-name-12345.netlify.app`

Your privacy and terms URLs will be:
- Privacy: `https://random-name-12345.netlify.app/privacy.html`
- Terms: `https://random-name-12345.netlify.app/terms.html`

### Step 4: (Optional) Set a Custom Subdomain

1. In Netlify dashboard, go to **Site settings** → **Domain management**
2. Click **Options** → **Edit site name**
3. Change from `random-name-12345` to something like `zeroinbox` or `zero-inbox-app`
4. Your new URLs will be:
   - Privacy: `https://zeroinbox.netlify.app/privacy.html`
   - Terms: `https://zeroinbox.netlify.app/terms.html`

---

## 🚀 Option 2: Deploy via Netlify CLI (Fast - 2 minutes)

### Step 1: Install Netlify CLI (if not already installed)

```bash
npm install -g netlify-cli
```

### Step 2: Login to Netlify

```bash
netlify login
```

This will open your browser to authenticate.

### Step 3: Deploy

```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2

# Deploy directly from this directory
netlify deploy
```

**When prompted:**
- **Create a new site?** → Yes
- **Team:** → Select your team
- **Site name:** → `zeroinbox` (or leave blank for random name)
- **Publish directory:** → Type `.` (current directory)

### Step 4: Test the Draft Deployment

Netlify will give you a **draft URL** like:
```
https://5f7a2b3c4d5e6f7g8h9i0j1k.deploy-preview-1.netlify.app
```

Test it:
```bash
# Open privacy policy
open https://YOUR-DRAFT-URL/privacy.html

# Open terms
open https://YOUR-DRAFT-URL/terms.html
```

### Step 5: Deploy to Production

Once you've tested and everything looks good:

```bash
netlify deploy --prod
```

### Step 6: Get Your URLs

After production deployment:
```bash
netlify open:site
```

Your URLs will be:
- Privacy: `https://YOUR-SITE-NAME.netlify.app/privacy.html`
- Terms: `https://YOUR-SITE-NAME.netlify.app/terms.html`

---

## ✅ After Deployment: Update Constants.swift

Once your site is live, update the iOS app:

1. **Open** `/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Config/Constants.swift`

2. **Replace** the placeholder URLs:

```swift
// BEFORE:
static let privacyPolicyURL = "https://your-dashboard-url.com/privacy.html"
static let termsOfServiceURL = "https://your-dashboard-url.com/terms.html"

// AFTER (replace with your actual Netlify URL):
static let privacyPolicyURL = "https://zeroinbox.netlify.app/privacy.html"
static let termsOfServiceURL = "https://zeroinbox.netlify.app/terms.html"
```

3. **Save** and rebuild the app

---

## 🧪 Test Your Deployment

### Test in Browser

```bash
# Test privacy policy
open https://YOUR-SITE-NAME.netlify.app/privacy.html

# Test terms of service
open https://YOUR-SITE-NAME.netlify.app/terms.html

# Test home page
open https://YOUR-SITE-NAME.netlify.app
```

### Test in iOS App

1. **Rebuild** the app after updating Constants.swift
2. **Open Settings** → **Legal**
3. **Tap** "Privacy Policy" → Should open in Safari
4. **Tap** "Terms of Service" → Should open in Safari

---

## 🎨 (Optional) Configure Custom Domain

If you want to use your own domain (e.g., `https://zeroinbox.com`):

### Via Netlify Web UI

1. Go to **Site settings** → **Domain management**
2. Click **Add custom domain**
3. Enter your domain (e.g., `zeroinbox.com`)
4. Follow instructions to update DNS records
5. Wait for DNS propagation (10-60 minutes)

### Via Netlify CLI

```bash
netlify domains:add zeroinbox.com
```

Then update your DNS provider with the records Netlify provides.

---

## 🔄 Update Deployment (When You Change Privacy/Terms)

### Via Web UI

1. Go to [app.netlify.com](https://app.netlify.com)
2. Click on your site
3. Go to **Deploys** tab
4. Drag and drop updated `netlify-deploy` folder

### Via CLI

```bash
cd /Users/matthanson/Zer0_Inbox/Zero_ios_2
netlify deploy --prod
```

---

## 📋 Deployment Checklist

After deploying, verify:

- [ ] Privacy policy loads correctly: `https://YOUR-SITE/privacy.html`
- [ ] Terms of service loads correctly: `https://YOUR-SITE/terms.html`
- [ ] Home page loads correctly: `https://YOUR-SITE/`
- [ ] All pages are mobile-responsive (test on phone)
- [ ] HTTPS is enabled (Netlify auto-enables this)
- [ ] URLs updated in Constants.swift
- [ ] iOS app rebuilds successfully
- [ ] Privacy/Terms open correctly from iOS app Settings
- [ ] Contact email links work (`mailto:0Inboxapp@gmail.com`)

---

## 🎯 For Google OAuth Consent Screen

After deployment, update your Google Cloud Console:

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Navigate to **APIs & Services** → **OAuth consent screen**
3. Update:
   - **Privacy Policy URL:** `https://YOUR-SITE.netlify.app/privacy.html`
   - **Terms of Service URL:** `https://YOUR-SITE.netlify.app/terms.html`
   - **Homepage URL:** `https://YOUR-SITE.netlify.app`
4. **Save** changes

---

## 🐛 Troubleshooting

### "Site not found" error

- Make sure all three HTML files are in the same directory you're deploying
- Check that file names are exactly: `index.html`, `privacy.html`, `terms.html`

### Links don't work from iOS app

- Verify URLs in Constants.swift are correct
- Make sure URLs include `https://`
- Rebuild the iOS app after changing Constants.swift

### Pages look broken on mobile

- All three HTML files have responsive CSS already
- Test in Safari on iPhone to verify
- If issues persist, open Netlify deploy logs to check for errors

---

## 📞 Need Help?

If you encounter any issues:

1. Check Netlify deploy logs in the dashboard
2. Verify all files uploaded correctly
3. Test URLs directly in browser before testing in app
4. Contact: 0Inboxapp@gmail.com

---

**Ready to deploy?** Start with **Option 1 (Web UI)** - it's the fastest!

Once deployed, come back here and update the URLs in Constants.swift. 🚀
