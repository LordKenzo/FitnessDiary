# How to Host Privacy Policy on GitHub Pages

## Quick Setup (5 minutes)

1. **Create docs folder in repo root:**
   ```bash
   mkdir -p docs
   cp AppStoreMetadata/privacy-policy.html docs/index.html
   ```

2. **Commit and push:**
   ```bash
   git add docs/
   git commit -m "Add privacy policy for GitHub Pages"
   git push
   ```

3. **Enable GitHub Pages:**
   - Go to: https://github.com/LordKenzo/FitnessDiary/settings/pages
   - Source: Deploy from branch
   - Branch: main (or your main branch)
   - Folder: /docs
   - Click Save

4. **Wait 2-3 minutes**, then your policy will be live at:
   ```
   https://lordkenzo.github.io/FitnessDiary/
   ```

5. **Use this URL in App Store Connect** → Privacy Policy URL field

## Alternative: Use AppStoreMetadata directly

If you prefer, commit the HTML file to main branch and GitHub will serve it automatically.

Your Privacy Policy URL will be:
```
https://lordkenzo.github.io/FitnessDiary/AppStoreMetadata/privacy-policy.html
```

## Verify It Works

After enabling GitHub Pages, open the URL in a browser to confirm it displays correctly.
