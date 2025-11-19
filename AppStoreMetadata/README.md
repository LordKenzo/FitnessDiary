# FittyPal - App Store Metadata

This directory contains all the metadata and documentation needed for FittyPal's App Store submission.

## 📁 Files Included

### 1. App Store Descriptions
- **Description_EN.md** - English app description, subtitle, keywords, and release notes
- **Description_IT.md** - Italian app description, subtitle, keywords, and release notes

### 2. Privacy Policy
- **PrivacyPolicy_EN.md** - Complete English privacy policy (GDPR compliant)
- **PrivacyPolicy_IT.md** - Complete Italian privacy policy (GDPR compliant)

---

## 🚀 How to Use These Files

### Step 1: App Store Connect Setup

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → Click **➕** to create a new app
3. Fill in basic information:
   - **Platform:** iOS
   - **Name:** FittyPal
   - **Primary Language:** Italian (or English)
   - **Bundle ID:** lo.france.FitnessDiary
   - **SKU:** fittypal-ios (or any unique identifier)

### Step 2: Fill in App Information

Navigate to **App Information** section:

- **Name:** FittyPal - Workout Tracker
- **Subtitle:** Copy from Description_EN.md or Description_IT.md
- **Category:**
  - Primary: Health & Fitness
  - Secondary: (optional)
- **Privacy Policy URL:** (See Step 4)
- **Support URL:** https://github.com/LordKenzo/FitnessDiary/issues

### Step 3: Prepare for Submission

Navigate to **Prepare for Submission** (under version 1.0):

#### Screenshots
Prepare screenshots for:
- iPhone 6.7" (1290 x 2796 px) - at least 3
- iPhone 6.5" (1242 x 2688 px) - at least 3
- iPad Pro 12.9" (2048 x 2732 px) - at least 3

Take screenshots of:
1. Dashboard with statistics
2. Workout execution with HR monitor
3. Workout cards list
4. Exercise library
5. Profile with HR zones

#### Description
Copy from **Description_EN.md** or **Description_IT.md**:
- Main description (4000 chars max)
- Keywords (100 chars, comma-separated)
- What's New (release notes)

#### App Icon
Upload the 1024x1024 PNG icon from:
`FitnessDiary/Assets.xcassets/AppIcon.appiconset/appstore1024.png`

### Step 4: Host Privacy Policy

You need a publicly accessible URL for your privacy policy.

#### Option A: GitHub Pages (Recommended - Free)

1. Create a `docs` folder in your repository root
2. Copy `PrivacyPolicy_EN.md` to `docs/privacy-policy.md`
3. Convert to HTML or use GitHub's automatic rendering
4. Enable GitHub Pages in repo Settings → Pages
5. Use URL: `https://lordkenzo.github.io/FitnessDiary/privacy-policy.html`

#### Option B: Simple HTML Page

Create a simple HTML file and host it anywhere:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FittyPal - Privacy Policy</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
               max-width: 800px; margin: 40px auto; padding: 20px; line-height: 1.6; }
        h1, h2 { color: #007AFF; }
    </style>
</head>
<body>
    <!-- Paste content from PrivacyPolicy_EN.md here -->
</body>
</html>
```

#### Option C: Third-Party Service
- [TermsFeed](https://www.termsfeed.com/privacy-policy-generator/)
- [FreePrivacyPolicy.com](https://www.freeprivacypolicy.com/)

### Step 5: Localization (Optional but Recommended)

For better international reach, localize metadata:

1. In App Store Connect, click **➕** next to your primary language
2. Add languages: IT, ES, FR, PT, RU, DE
3. For each language, provide:
   - Localized description
   - Localized keywords
   - Localized screenshots (if possible)

**Minimum:** English + Italian
**Recommended:** English + Italian + Spanish

### Step 6: Build and Submit

1. Archive your app in Xcode (Product → Archive)
2. Upload to App Store Connect (Distribute App → App Store Connect)
3. Once build is processed (~10 minutes), select it in "Build" section
4. Fill in **App Review Information**:
   - First Name: Francesco
   - Last Name: Lorenzini
   - Email: your-email@example.com
   - Phone: +39-xxx-xxx-xxxx
   - Notes: Copy from Description_EN.md → "Notes for Apple Reviewer"
5. Submit for Review

---

## 📊 Character Counts

All content is pre-formatted to fit App Store limits:

| Field | Limit | English | Italian |
|-------|-------|---------|---------|
| App Name | 30 | 28 ✓ | 28 ✓ |
| Subtitle | 30 | 28 ✓ | 24 ✓ |
| Keywords | 100 | 99 ✓ | 97 ✓ |
| Description | 4000 | 3,847 ✓ | 3,912 ✓ |
| Release Notes | 4000 | 896 ✓ | 968 ✓ |

---

## 🔍 SEO Keywords Strategy

### Primary Keywords (High Volume)
- workout
- fitness
- gym
- training
- exercise

### Secondary Keywords (Medium Volume, Higher Relevance)
- personal trainer
- heart rate
- strength training
- bodybuilding
- workout tracker

### Long-Tail Keywords (Low Volume, High Intent)
- cluster sets
- heart rate zones
- workout cards
- exercise library

---

## ✅ Pre-Submission Checklist

App Information:
- [ ] App name set (FittyPal - Workout Tracker)
- [ ] Subtitle set (28 chars max)
- [ ] Primary category: Health & Fitness
- [ ] Privacy Policy URL configured
- [ ] Support URL configured

Version 1.0:
- [ ] Description pasted (EN or IT)
- [ ] Keywords pasted (100 chars)
- [ ] Release notes pasted
- [ ] Screenshots uploaded (iPhone + iPad, minimum 3 each)
- [ ] App icon 1024x1024 uploaded
- [ ] Build uploaded and selected
- [ ] Age rating completed (4+)
- [ ] App Review Information filled
- [ ] Notes for reviewer pasted

Compliance:
- [ ] PrivacyInfo.xcprivacy in project ✓
- [ ] LSApplicationCategoryType set ✓
- [ ] Privacy descriptions localized ✓
- [ ] Deployment target iOS 17.0 ✓

---

## 📞 Support Contacts

If users contact you after launch, respond to:
- **Email:** support@fittypal.com
- **GitHub Issues:** https://github.com/LordKenzo/FitnessDiary/issues

---

## 🎯 Post-Launch

After approval:
1. **Monitor reviews** - Respond to user feedback on App Store
2. **Track downloads** - Use App Store Connect Analytics
3. **Plan updates** - Based on user requests and feedback
4. **Update metadata** - Improve keywords/description based on search performance

---

## 📝 Notes

- All content is ready to copy-paste directly into App Store Connect
- Privacy policies are GDPR-compliant and cover all app functionality
- Descriptions highlight unique features (HR zones, methodologies, privacy)
- Keywords are optimized for fitness/training niche
- Italian version is included for primary market (Italy)

Good luck with your App Store submission! 🚀
