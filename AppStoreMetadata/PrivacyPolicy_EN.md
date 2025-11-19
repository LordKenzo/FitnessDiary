# Privacy Policy - FittyPal

**Last Updated:** November 18, 2025
**Effective Date:** November 18, 2025

---

## Introduction

FittyPal ("we," "our," or "the app") is committed to protecting your privacy. This Privacy Policy explains how FittyPal handles your personal data and protects your information.

**Key Principle:** FittyPal is built with privacy as the foundation. All your data stays on your device. We do not collect, transmit, or store any of your personal information on external servers.

---

## Data Controller

**Name:** Lorenzo Franceschini
**Contact:** support@fittypal.com
**Location:** Italy

For GDPR-related inquiries, please contact us at the email above.

---

## What Data We Process

FittyPal stores the following data **exclusively on your device**:

### 1. Profile Information
- Age
- Gender (biological sex)
- Weight
- Height
- Profile photo (optional)
- Heart rate zones (calculated from age and max heart rate)

### 2. Exercise Library Data
- Exercise names and descriptions
- Muscle group targeting
- Equipment used
- Up to 3 photos per exercise (optional)
- Custom notes

### 3. Workout Data
- Workout cards and templates
- Workout blocks and exercise sequences
- Sets, repetitions, and loads
- Rest periods and tempo
- Workout execution logs
- Session duration
- Mood ratings (5-level scale)
- RPE (Rate of Perceived Exertion, 0-10 scale)
- Session notes

### 4. Client Data (For Personal Trainers)
- Client names
- Client profile photos (optional)
- Client-specific workout assignments
- Client workout history

### 5. App Preferences
- Selected language (7 options: EN, IT, ES, FR, PT, RU, DE)
- Workout countdown timer duration
- Custom heart rate zones

### 6. Health Data (Optional - Only if You Grant Permission)
FittyPal can import the following data from Apple Health:
- Weight
- Height
- Age
- Biological sex
- Heart rate (from connected devices)

FittyPal can export the following data to Apple Health:
- Workout sessions
- Exercise duration
- Calories burned (estimated)

---

## How We Use Your Data

All data processing happens **locally on your device**. FittyPal uses your data to:

1. **Display your profile** and calculate personalized heart rate zones
2. **Create and manage workout plans** tailored to your needs
3. **Track your workout progress** over time
4. **Provide workout execution guidance** with timers and rep counting
5. **Manage multiple clients** (for personal trainers)
6. **Remember your preferences** (language, timer settings)
7. **Sync with Apple Health** (only if you grant permission)

**No data is sent to external servers.** FittyPal does not have backend servers, databases, or cloud storage.

---

## Data Storage

### Local Storage Only
All data is stored using **SwiftData**, Apple's modern local persistence framework. Data files are stored in your device's sandboxed container, accessible only by FittyPal.

### Photos
Profile photos and exercise photos are stored as compressed JPEG images (80% quality) using SwiftData's external storage feature. Photos are stored in your app's private storage area.

### iCloud Sync
FittyPal does not currently sync data to iCloud. All data remains exclusively on your device.

---

## Data Sharing

**We do not share your data with anyone.**

FittyPal does not:
- Send data to remote servers
- Share data with third parties
- Sell your data to advertisers
- Use analytics or tracking services
- Collect telemetry or usage statistics

The only data sharing that occurs is:
- **Apple Health** (only if you explicitly grant permission)
- **Bluetooth heart rate monitors** (real-time heart rate transmission only during active workout sessions)

---

## Third-Party Services

FittyPal uses the following Apple frameworks, which process data locally:

### Apple Health (HealthKit)
- **Purpose:** Import biometric data (weight, height, age) and export workout sessions
- **Data Shared:** Only data you explicitly authorize
- **Privacy:** Controlled by iOS permissions - you can revoke access anytime in Settings > Privacy > Health
- **Apple's Policy:** [Apple HealthKit Privacy](https://www.apple.com/legal/privacy/data/en/health-app/)

### Bluetooth Low Energy (CoreBluetooth)
- **Purpose:** Connect to heart rate monitors during workouts
- **Data Shared:** None - FittyPal only receives heart rate readings from your device
- **Privacy:** Controlled by iOS permissions - you can revoke access anytime in Settings > Privacy > Bluetooth
- **Data Retention:** Heart rate data is stored locally in workout logs

**FittyPal does not use any third-party SDKs, analytics libraries, or advertising frameworks.**

---

## Your Privacy Rights (GDPR Compliance)

Under the General Data Protection Regulation (GDPR) and other privacy laws, you have the following rights:

### 1. Right to Access
You can view all your data within the FittyPal app at any time.

### 2. Right to Rectification
You can edit or correct any of your data directly in the app (profile information, workout logs, exercises, etc.).

### 3. Right to Erasure ("Right to be Forgotten")
You can delete your data at any time by:
- Deleting individual items within the app (exercises, workouts, clients)
- Uninstalling FittyPal from your device (permanently deletes all app data)

### 4. Right to Data Portability
Currently, FittyPal does not offer data export functionality. This feature is planned for a future update. For now, your data remains in the app's local database.

### 5. Right to Object
Since FittyPal does not perform any automated decision-making, profiling, or data sharing, there is no processing to object to.

### 6. Right to Withdraw Consent
You can withdraw permission for Apple Health or Bluetooth access at any time in iOS Settings > Privacy.

---

## Children's Privacy

FittyPal is rated 4+ and does not contain objectionable content. However, the app is designed for individuals who are at least 13 years old.

We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us (though note that all data is stored locally on the device).

---

## Data Security

FittyPal implements the following security measures:

### Local Storage Encryption
- All data is stored in your device's sandboxed container
- iOS encrypts data at rest using hardware-level encryption (if you enable device passcode/Face ID)
- FittyPal benefits from iOS's built-in security features

### No Network Transmission
- Zero network requests = zero risk of interception
- No API keys, tokens, or authentication credentials
- No cloud storage = no server breaches possible

### Bluetooth Security
- Bluetooth heart rate monitors use encrypted BLE connections
- Only heart rate data is received (no personal information transmitted)
- Connection is temporary and terminates when workout ends

---

## International Data Transfers

**Not applicable.** FittyPal does not transfer data outside your device, so there are no international data transfers.

---

## Data Retention

### How Long We Keep Your Data
FittyPal stores your data **indefinitely on your device** until you:
1. Manually delete items in the app
2. Uninstall FittyPal (all data is permanently deleted)

### Automatic Deletion
FittyPal does not automatically delete any data. You have full control over what to keep and what to remove.

---

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Changes will be posted:
- In this document (with updated "Last Updated" date)
- In future app updates (via App Store release notes if significant)

Continued use of FittyPal after changes constitutes acceptance of the updated policy.

---

## Cookies and Tracking Technologies

**FittyPal does not use cookies, tracking pixels, or any analytics tools.**

The app does not:
- Track your usage behavior
- Collect device identifiers (IDFA, IDFV)
- Use fingerprinting techniques
- Employ third-party tracking services

---

## Contact Us

If you have questions, concerns, or requests regarding this Privacy Policy or your data, please contact:

**Email:** support@fittypal.com
**GitHub Issues:** https://github.com/LordKenzo/FitnessDiary/issues

We will respond to all requests within 30 days, as required by GDPR.

---

## Legal Basis for Processing (GDPR)

FittyPal processes your data based on the following legal grounds:

1. **Consent:** You provide explicit consent when granting permissions (HealthKit, Bluetooth)
2. **Legitimate Interest:** Providing workout tracking functionality requires storing workout data locally
3. **Contractual Necessity:** Processing is necessary to provide the app's core functionality

---

## Summary

- ✅ All data stored **locally on your device**
- ✅ **No servers, no cloud, no tracking**
- ✅ **No data sharing** with third parties
- ✅ **Full control** over your data
- ✅ **Delete anytime** by uninstalling the app
- ✅ **GDPR compliant**

FittyPal is designed to respect your privacy completely. Your workout data is yours and yours alone.

---

**Last Updated:** November 18, 2025
**Version:** 1.0
