# FittyPal - App Review Information

## App Overview

**FittyPal** is a privacy-focused workout tracking app designed for personal trainers and fitness enthusiasts. The app operates **100% offline** with all data stored locally on the device using SwiftData. No account required, no servers, no tracking.

---

## Key Features to Test

1. **Workout Cards** - Create custom training programs with advanced methodologies (cluster sets, rest-pause, drop sets)
2. **Exercise Library** - Pre-populated database with muscle targeting and equipment tracking
3. **Real-time Workout Execution** - Timer-based workout tracking with customizable countdowns
4. **Heart Rate Monitoring** - Optional Bluetooth LE heart rate monitor connection with zone training
5. **Multi-client Management** - Personal trainer feature to manage multiple client profiles
6. **Health Integration** - Optional Apple Health sync for weight, height, age, and biometric data

---

## Testing Instructions

### STEP 1: Onboarding (First Launch)

1. Launch the app - you'll see a 3-screen onboarding tutorial
2. Swipe through the introduction screens
3. Tap "Get Started" to proceed to profile setup

### STEP 2: Profile Setup

**Option A - Manual Entry (Recommended for Testing):**
1. Enter a test name (e.g., "Test Reviewer")
2. Select gender: Male/Female/Other
3. Enter age: e.g., 30 years
4. Enter weight: e.g., 70 kg
5. Enter height: e.g., 175 cm
6. The app will auto-calculate max heart rate (220 - age)
7. Tap "Save" to create profile

**Option B - Import from Apple Health (Optional):**
- Tap "Import from Apple Health" button
- Grant read permissions for: Weight, Height, Date of Birth, Biological Sex
- Data will auto-populate
- **Note:** You can deny Health permissions - the app works perfectly without them

### STEP 3: Create a Workout Card

1. Navigate to the **"Cards"** tab (second icon in bottom tab bar)
2. Tap the **"+"** button (top-right corner)
3. Enter workout card name: e.g., "Test Workout"
4. Select a client from the list (default: your profile)
5. Tap "Save"
6. Tap on the newly created card to open it

### STEP 4: Add Exercises to the Card

1. In the workout card detail view, tap **"Add Block"**
2. In the block configuration:
   - Name: e.g., "Block A"
   - Method: Select "Traditional Sets" (simplest option)
   - Tap "Save"
3. Tap **"Add Exercise"** within the block
4. Browse or search the pre-populated exercise library
   - Try searching: "Bench Press", "Squat", "Deadlift"
   - Filter by muscle group or equipment if desired
5. Select an exercise
6. Configure sets:
   - Number of sets: 3
   - Reps per set: 10
   - Rest time: 60 seconds
7. Tap "Save"
8. Repeat to add 2-3 more exercises

### STEP 5: Execute a Workout

1. Navigate to the **"Workout"** tab (third icon in tab bar)
2. Select the workout card you created ("Test Workout")
3. Tap **"Start Workout"**
4. Follow the workout execution screen:
   - Timer will show countdown (default: 10 seconds)
   - Perform the exercise when countdown completes
   - Enter the load used (e.g., 50 kg) and actual reps completed
   - Tap "Complete Set"
   - Rest timer will start automatically
5. Complete 2-3 sets to see the flow
6. Tap the **"End Workout"** button (top-right)
7. Fill in the completion form:
   - Mood: Select emoji (1-5 scale)
   - RPE: Rate of Perceived Exertion (0-10 scale)
   - Notes: Optional text
8. Tap "Save" to log the workout

### STEP 6: View Workout History

1. Navigate to the **"History"** tab (fourth icon)
2. You'll see the workout you just completed
3. Tap on it to view detailed session log
4. Verify all sets, loads, and reps are recorded correctly

### STEP 7: Explore Profile & Settings

1. Navigate to the **"Profile"** tab (fifth icon)
2. View your physical data and BMI calculation
3. Scroll to "Heart Rate Zones" section
4. Tap "Customize Zones" to see zone editor
5. Tap the gear icon (top-right) to access preferences
6. Try changing:
   - Language (7 languages supported)
   - App theme (Vibrant / Calm)
   - Countdown duration (0-120 seconds)
   - Timer sounds and volume

---

## Optional Features to Test

### Bluetooth Heart Rate Monitor (Optional)

**Requirements:**
- A Bluetooth LE heart rate monitor (Polar H10, Garmin HRM, Wahoo, etc.)
- Standard Heart Rate Service UUID: 0x180D

**Testing Steps:**
1. Turn on your heart rate monitor
2. During workout execution (Step 5), tap the **heart icon** in the top-right
3. Grant Bluetooth permission when prompted
4. Select your device from the list
5. Once connected, real-time BPM will display
6. Heart rate zones will be color-coded:
   - 🟢 Zone 1 (Recovery)
   - 🔵 Zone 2 (Endurance)
   - 🟡 Zone 3 (Tempo)
   - 🟠 Zone 4 (Threshold)
   - 🔴 Zone 5 (VO2 Max)

**Note:** The app is **fully functional without a heart rate monitor**. If you don't have one available, you can skip this test.

### Apple Health Integration (Optional)

**Testing Steps:**
1. In Profile Setup or Profile Edit view, tap "Import from Apple Health"
2. Grant permissions for: Weight, Height, Date of Birth, Biological Sex
3. Data will sync to the profile
4. **Note:** Health integration is completely optional and can be denied

**Note:** The app **does NOT require Health permissions** to function. All features work with manual data entry.

---

## Privacy & Data Storage

### Local-Only Storage
- All data is stored locally on the device using SwiftData (Apple's modern persistence framework)
- **Zero network calls** - the app works 100% offline
- **No cloud sync** - no iCloud, no external servers
- **No account required** - no sign-up, no login

### Privacy Manifest
The app includes a complete `PrivacyInfo.xcprivacy` file declaring:
- **No ad tracking** (NSPrivacyTracking: false)
- **No data collection** for third parties
- **UserDefaults** usage for app preferences (language, timer settings)
- **File timestamps** accessed by SwiftData framework

### Permissions Used
1. **Bluetooth** (optional) - Connect to heart rate monitors
2. **HealthKit** (optional) - Import weight, height, age, biological sex
3. **Photos** (optional) - Select profile photo or exercise images
4. **Camera** (optional) - Take photos for profile or exercises

All permissions are **requested at the point of use** and are **completely optional**.

---

## Technical Details

### Build Information
- **Minimum iOS Version:** 17.0
- **Language:** Swift 6.0
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Bundle ID:** `lo.france.FitnessDiary`
- **App Category:** Health & Fitness

### Localization
The app is fully localized in 7 languages:
- 🇮🇹 Italian (primary)
- 🇬🇧 English
- 🇪🇸 Spanish
- 🇫🇷 French
- 🇵🇹 Portuguese
- 🇷🇺 Russian
- 🇩🇪 German

To test localization: Settings app → General → Language & Region → change iPhone language, then relaunch FittyPal.

### Background Modes
- **Bluetooth LE background mode** enabled for continuous heart rate monitoring during workouts
- App does **not** run in background otherwise

---

## Known Limitations (By Design)

1. **No cloud sync** - Data stays on device only (privacy feature)
2. **No export** - Currently no CSV/PDF export (planned for v1.1)
3. **No Apple Watch app** - iPhone only for v1.0 (planned for v2.0)
4. **No GPS tracking** - Indoor workout focus (outdoor tracking planned)
5. **iOS 17.0+ only** - Uses latest SwiftData and SwiftUI features

---

## Demo Account

**Not applicable** - The app does not use accounts. Simply create a test profile during onboarding (see Step 2 above).

---

## Test Scenarios Summary

### ✅ Happy Path (Recommended)
1. Complete onboarding → 2. Create profile manually → 3. Create workout card → 4. Add exercises → 5. Execute workout → 6. View history

**Estimated Time:** 5-7 minutes

### ✅ With Health Integration
Same as above, but import data from Apple Health in Step 2

**Estimated Time:** 6-8 minutes

### ✅ With Bluetooth HR Monitor
Same as Happy Path, but connect heart rate monitor during workout execution (Step 5)

**Estimated Time:** 7-10 minutes

### ✅ Multi-Client Test (Personal Trainer Feature)
1. In Profile tab → Tap "Clients" → Add multiple test clients
2. Create workout cards assigned to different clients
3. Execute workouts for different clients
4. Verify data separation between clients

**Estimated Time:** 8-10 minutes

---

## Troubleshooting

### "No exercises in library"
- This should not happen - the app pre-populates 50+ exercises on first launch
- If this occurs, please restart the app

### "Bluetooth connection failed"
- Ensure heart rate monitor is turned on and in pairing mode
- Grant Bluetooth permission when prompted
- Connection timeout is 10 seconds - if it fails, try again

### "Health import doesn't work"
- Grant all requested permissions (Weight, Height, Date of Birth, Sex)
- Ensure you have data in Apple Health app
- If permissions are denied, use manual entry instead

### "App crashes or freezes"
- Please note any reproduction steps - the app has been thoroughly tested but edge cases may exist

---

## Contact Information

**Developer:** Lorenzo Franceschini

**Support Email:** support@fittypal.com

**Support URL:** https://github.com/LordKenzo/FitnessDiary/issues

**Privacy Policy:** https://www.fittypal.com/privacy-policy.html

**App Store Review Contact:**
- Name: Lorenzo Franceschini
- Email: [Your review email]
- Phone: [Your review phone number]

---

## Additional Notes for Reviewers

### Why iOS 17.0+?
The app leverages SwiftData (introduced in iOS 17.0) for modern, type-safe persistence. This enables better performance, compile-time safety, and seamless SwiftUI integration.

### Why No Cloud Sync?
Privacy is a core value. Many fitness apps collect and monetize user data. FittyPal intentionally keeps all data local, giving users complete control and privacy.

### Architecture
- **MVVM pattern** with SwiftUI
- **SwiftData models** for persistence
- **Async/await** for HealthKit and Bluetooth operations
- **Zero third-party dependencies** for maximum security and stability

### Compliance
- ✅ Complete Privacy Manifest (PrivacyInfo.xcprivacy)
- ✅ Privacy descriptions in 7 languages
- ✅ GDPR-compliant privacy policy
- ✅ Age rating: 4+ (no mature content)
- ✅ All sensitive APIs properly declared

---

## Screenshots Checklist

The submitted screenshots demonstrate:
1. ✅ Workout execution with heart rate monitoring
2. ✅ Workout card management interface
3. ✅ Exercise library with search and filters
4. ✅ Profile view with heart rate zones
5. ✅ Workout history and session logs

---

Thank you for reviewing FittyPal! We believe this app provides real value to fitness enthusiasts and personal trainers while respecting user privacy. If you have any questions during the review process, please don't hesitate to contact us.

---

**Submission Date:** [To be filled]

**Version:** 1.0 (Build 1)

**Submitted By:** Lorenzo Franceschini
