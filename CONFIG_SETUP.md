# API Configuration Setup

## ⚠️ Important: API Key Security

**Never commit your actual API keys to version control!**

This project uses a configuration file (`Config.plist`) that is **gitignored** to keep your API keys secure.

## Setup Instructions

### 1. Copy the Example Configuration

```bash
cp Config.plist.example Config.plist
```

### 2. Get Your WeatherAPI Key

1. Visit [WeatherAPI.com](https://www.weatherapi.com/signup.aspx)
2. Sign up for a free account
3. Copy your API key from the dashboard

### 3. Configure Your API Key

Open `Config.plist` and replace the placeholder with your actual key:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>WeatherAPIKey</key>
    <string>YOUR_ACTUAL_API_KEY_HERE</string>
</dict>
</plist>
```

### 4. Verify Configuration

The app will automatically check if the API key is configured. If not, you'll see a placeholder message in the weather section.

## File Structure

```
FitnessDiary/
├── Config.plist.example    # Template file (committed to git)
├── Config.plist             # Your actual config (gitignored)
└── FittyPal/
    └── Helpers/
        └── APIConfiguration.swift  # Loads config
```

## Security Best Practices

✅ **DO:**
- Keep `Config.plist` in `.gitignore`
- Use `Config.plist.example` as a template
- Share `Config.plist.example` with your team
- Rotate API keys if they're exposed

❌ **DON'T:**
- Commit `Config.plist` to git
- Share your API keys in chat/email
- Hardcode API keys in source code
- Push keys to public repositories

## Troubleshooting

### "Weather API not configured" Message

1. Check that `Config.plist` exists in the project root
2. Verify your API key is correctly pasted
3. Make sure the key name is exactly `WeatherAPIKey`
4. Restart Xcode if needed

### Location Permission Denied

The app needs location permission to fetch weather data. Go to:
**Settings → Privacy → Location Services → FittyPal** and enable "While Using"

## WeatherAPI.com Free Tier Limits

- **1 million calls/month** (free tier)
- **Real-time weather data**
- **3-day forecast**
- **No credit card required**

This is more than enough for a personal fitness app!

## For Developers

If you're contributing to this project:

1. Never commit your `Config.plist`
2. Always use `Config.plist.example` for documentation
3. Add new API keys to both files (example with placeholder, actual with your key)
4. Update this README when adding new API services

---

**Last Updated:** 2025-01-20
**Weather API Version:** v1.0
