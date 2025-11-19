# 📸 Screenshots Organization

This folder contains all App Store screenshots organized by device type.

## 📐 Folder Structure

### `Raw/`
**Original screenshots** taken directly from iPhone/iPad
- No device frames
- No processing
- Source files for screenshots.pro

**How to capture:**
1. Run FittyPal on iPhone 14 Pro Max or later
2. Navigate to each screen (see list below)
3. Take screenshot (Volume Up + Side Button)
4. AirDrop or transfer to Mac
5. Place in this folder

### `iPhone-6.7/`

Processed screenshots for iPhone 6.7" display

- Resolution: 1290 x 2796 pixels
- Device: iPhone 15 Pro Max, 14 Pro Max, 13 Pro Max
- With device frame and background
- **REQUIRED for App Store submission**

**Minimum:** 3 screenshots
**Recommended:** 5 screenshots

### `iPhone-6.5/`

Processed screenshots for iPhone 6.5" display

- Resolution: 1242 x 2688 pixels
- Device: iPhone 11 Pro Max, XS Max
- With device frame and background
- **REQUIRED for App Store submission**

**Minimum:** 3 screenshots
**Recommended:** 5 screenshots

### `iPad-12.9/`

Processed screenshots for iPad Pro 12.9" display

- Resolution: 2048 x 2732 pixels
- Device: iPad Pro 12.9" (3rd gen and later)
- With device frame and background
- **RECOMMENDED for App Store submission**

**Minimum:** 3 screenshots
**Recommended:** 5 screenshots

---

## 📸 Required Screenshots

Create these 5 screenshots (in order):

### 1. Workout Execution with Heart Rate
**File name:** `01-workout-execution.png`
- Active workout in progress
- Heart rate monitor connected (showing BPM)
- Colored HR zone indicator
- Timer countdown visible

### 2. Workout Cards Library
**File name:** `02-workout-cards.png`
- 3-4 workout cards with professional names
- Visual card design with gradients
- "+" button visible

### 3. Exercise Library
**File name:** `03-exercise-library.png`
- Exercise list with search bar
- Muscle group filter pills
- 6-8 exercises visible
- Exercise photos/icons

### 4. Profile with HR Zones
**File name:** `04-profile-zones.png`
- Personal stats (age, weight, height, BMI)
- 5 colored HR zones prominently displayed
- BPM ranges for each zone

### 5. Workout History
**File name:** `05-workout-history.png`
- 3-4 completed workouts
- Dates, mood indicators, RPE scores
- Timeline view

---

## 🔧 Processing Workflow

**Step 1:** Take raw screenshots → Save to `Raw/`

**Step 2:** Process with screenshots.pro:
1. Go to [screenshots.pro](https://screenshots.pro)
2. Upload raw screenshots
3. Select device: iPhone 15 Pro Max (Space Black)
4. Add background: Gradient matching app theme
5. Export as PNG

**Step 3:** Save processed screenshots:
- iPhone 6.7" → Save to `iPhone-6.7/`
- iPhone 6.5" → Save to `iPhone-6.5/`
- iPad 12.9" → Save to `iPad-12.9/`

**Step 4:** Upload to App Store Connect:
1. Go to appstoreconnect.apple.com
2. Navigate to: Version 1.0 → Screenshots
3. Drag and drop screenshots in order (01-05)

---

## ✅ Quality Checklist

Before uploading to App Store Connect:

- [ ] All screenshots are PNG format (not JPG)
- [ ] Correct resolution for each device type
- [ ] No debug overlays or test data visible
- [ ] Professional sample data (realistic names, weights)
- [ ] Consistent device frame style across all images
- [ ] Screenshots show real app features
- [ ] Text in screenshots is in Italian (or English for EN store)
- [ ] All 5 screenshots created for each device type
- [ ] Files named consistently (01-05)

---

## 📊 File Naming Convention

Use consistent naming:
```text
01-workout-execution.png
02-workout-cards.png
03-exercise-library.png
04-profile-zones.png
05-workout-history.png
```

This order matches the recommended sequence for App Store presentation.

---

## 📚 Additional Resources

**Detailed Guide:** See `../AppStoreMetadata/Screenshot-Guide.md`

**Tools:**
- [screenshots.pro](https://screenshots.pro)
- [Previewed](https://previewed.app)
- Xcode Simulator - Built-in

**Apple Guidelines:**
[App Store Product Page Guidelines](https://developer.apple.com/app-store/product-page/)

---

**Status:** ⚠️ Screenshots not yet created

**Next Step:** Follow Screenshot-Guide.md to create your screenshots
