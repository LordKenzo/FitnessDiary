# Xcode Configuration: Add Config.plist to Bundle

## ⚠️ Problem: "Meteo non disponibile"

Se vedi "Non disponibile" nel meteo, probabilmente **Config.plist non è incluso nel bundle dell'app**.

## ✅ Solution: Add Config.plist to Xcode Target

### Step 1: Open Xcode Project

```bash
cd /home/user/FitnessDiary
open FittyPal.xcodeproj
```

### Step 2: Add Config.plist to Project

1. **Right-click** on the "FittyPal" folder (blue icon) in the Project Navigator
2. Select **"Add Files to FittyPal..."**
3. Navigate to and select `Config.plist` (in the root directory)
4. **IMPORTANT**: In the dialog, make sure:
   - ✅ **"Copy items if needed"** is checked
   - ✅ **"Add to targets"** has FittyPal checked
   - ✅ "Create folder references" is selected
5. Click **"Add"**

### Step 3: Verify File is in Target

1. Select **Config.plist** in Project Navigator
2. Open **File Inspector** (right sidebar, first tab)
3. Under **"Target Membership"**, ensure **FittyPal** is checked

### Step 4: Build and Run

Clean build folder and run:
1. **Product → Clean Build Folder** (⇧⌘K)
2. **Product → Run** (⌘R)

### Step 5: Check Console Logs

When the app starts, you should see in the debug console:

```
✅ API Key loaded from Config.plist: edecff438f...
📍 Location authorization changed: Authorized When In Use
📍 Location updated: 45.4642, 9.1900
🌤️ Fetching weather for: 45.4642, 9.1900
   API configured: true
   HTTP Status: 200
✅ Weather fetched successfully!
   Location: Milan
   Temperature: 8.0°C
   Condition: Clear
```

## 🔧 Alternative: Temporary Hardcoded Key (DEBUG ONLY)

If you can't add Config.plist to the bundle right now, you can temporarily hardcode the key **for DEBUG builds only**:

Edit `FittyPal/Helpers/APIConfiguration.swift`:

```swift
static let weatherAPIKey: String = {
    #if DEBUG
    // Temporary hardcoded key for development
    return "edecff438ff64beb9f5100232252011"
    #else
    // Production: load from Config.plist
    if let key = loadFromConfigPlist(key: "WeatherAPIKey"), !key.isEmpty {
        return key
    }
    return "YOUR_WEATHER_API_KEY_HERE"
    #endif
}()
```

⚠️ **Remember**: This is ONLY for local testing! Remove it before committing.

## 📱 Location Permission

Don't forget to **allow location permission** when the app asks!

Settings → Privacy & Security → Location Services → FittyPal → While Using the App

## 🐛 Debugging Steps

### 1. Check Console Logs

Look for these emoji indicators:
- 🔍 = Looking for Config.plist
- ✅ = Success
- ❌ = Error
- 📍 = Location update
- 🌤️ = Weather fetch

### 2. Common Issues

| Problem | Solution |
|---------|----------|
| "Config.plist not found in bundle" | Add file to Xcode target (Step 2-3 above) |
| "Location not authorized" | Grant permission in Settings |
| "HTTP Error 401" | Invalid API key |
| "HTTP Error 400" | Check coordinates format |
| No logs at all | Make sure you're running DEBUG build |

### 3. Test API Key Manually

You can test your API key with curl:

```bash
curl "https://api.weatherapi.com/v1/current.json?key=edecff438ff64beb9f5100232252011&q=45.4642,9.1900&aqi=no"
```

Should return JSON with weather data.

## 📞 Still Not Working?

Run the app in Xcode and send me the console output. It will show exactly where it's failing!

---

**Last Updated:** 2025-01-20
