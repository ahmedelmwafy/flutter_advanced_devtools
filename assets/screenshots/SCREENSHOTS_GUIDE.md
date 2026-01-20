# Screenshots Guide

This guide will help you capture professional screenshots for the Flutter Advanced DevTools package.

## Required Screenshots

To showcase the package effectively on pub.dev and GitHub, capture the following screenshots:

### 1. Main DevTools Screen (`main_screen.png`)
**What to show:**
- DevTools overlay with all tabs visible at the bottom (Info, Network, Performance, Logs, Settings)
- Environment badge showing current environment (e.g., "Development")
- Base URL display
- User info section
- Device info section
- Floating action button

**How to capture:**
1. Run the example app
2. Open DevTools (shake device or tap FAB)
3. Navigate to the Info tab
4. Take screenshot

---

### 2. Network Logger (`network_logger.png`)
**What to show:**
- List of HTTP requests with different status codes (200, 201, 404, 500)
- HTTP method badges (GET, POST, etc.)
- Response times
- Statistics at the top (Total, Success, Failed)

**How to capture:**
1. Make several API requests in your app
2. Open DevTools
3. Navigate to Network tab
4. Take screenshot showing multiple requests

---

### 3. Network Details (`network_details.png`)
**What to show:**
- Detailed view of a single request
- Request/Response tabs
- JSON formatted response body with syntax highlighting
- Headers display
- Status code and timing

**How to capture:**
1. In Network tab, tap on any request
2. View the detailed screen
3. Take screenshot

---

### 4. Performance Monitor (`performance_monitor.png`)
**What to show:**
- Memory usage card with value in MB
- CPU usage card with percentage
- FPS card with frame rate
- Performance graphs (if available)

**How to capture:**
1. Open DevTools
2. Navigate to Performance tab
3. Wait for metrics to populate
4. Take screenshot

---

### 5. Environment Switcher (`environment_switcher.png`)
**What to show:**
- List of available environments (Local, Development, Staging, Production)
- Selected environment highlighted
- Custom URL input field
- Radio buttons for selection

**How to capture:**
1. Open DevTools
2. Tap on environment section or settings
3. Show environment selection UI
4. Take screenshot

---

### 6. Permissions Manager (`permissions.png`)
**What to show:**
- Grid/list of app permissions
- Permission icons (camera, location, storage, etc.)
- Status badges (Granted, Denied, Permanently Denied)
- Request buttons for denied permissions

**How to capture:**
1. Open DevTools
2. Navigate to Permissions section
3. Take screenshot showing various permission states

---

### 7. Exception Logger (`exceptions.png`)
**What to show:**
- List of caught exceptions
- Error messages
- Stack traces
- Timestamps

**How to capture:**
1. Trigger some errors in the app
2. Open DevTools
3. Navigate to Logs or Exceptions tab
4. Take screenshot

---

## Screenshot Specifications

### For pub.dev:
- **Format:** PNG or JPEG
- **Aspect ratio:** Ideally 16:9 or phone aspect ratio (9:19.5)
- **Resolution:** At least 1080px width
- **Size:** Under 4MB per image
- **Count:** 1-10 screenshots

### For GitHub:
- **Format:** PNG (recommended for transparency)
- **Resolution:** 1080px - 1920px width
- **Naming:** Use descriptive names (e.g., `main_screen.png`, `network_logger.png`)

---

## Tips for Professional Screenshots

1. **Use a real device or high-quality emulator**
   - iOS Simulator or Android Emulator with latest OS
   - Recommended: iPhone 15 Pro or Pixel 8 Pro

2. **Clean status bar**
   - Full battery
   - Good signal strength
   - Clean time (e.g., 9:41 AM - Apple's standard)

3. **Consistent theme**
   - Use the same theme across all screenshots
   - Dark mode often looks more professional

4. **Real data**
   - Use realistic API endpoints
   - Show actual response data
   - Avoid "lorem ipsum" or placeholder text

5. **Highlight key features**
   - Show various status codes in network tab
   - Display actual performance metrics
   - Include both success and error states

---

## After Capturing Screenshots

1. Save all screenshots to `assets/screenshots/` folder
2. Optimize images (use tools like ImageOptim, TinyPNG)
3. Update README.md with screenshot references
4. Commit and push to GitHub

---

## Quick Capture Commands

```bash
# Create screenshots directory
mkdir -p assets/screenshots

# List all screenshots
ls -lh assets/screenshots/

# Optimize PNGs (requires optipng)
optipng -o7 assets/screenshots/*.png

# Or use ImageMagick to resize
mogrify -resize 1080x assets/screenshots/*.png
```

---

## Screenshot Checklist

- [ ] main_screen.png - Main DevTools overlay
- [ ] network_logger.png - List of network requests
- [ ] network_details.png - Detailed request view
- [ ] performance_monitor.png - Performance metrics
- [ ] environment_switcher.png - Environment selection
- [ ] permissions.png - Permissions manager
- [ ] exceptions.png - Exception logger (optional)
- [ ] demo.gif - Animated demo (optional but recommended)

---

## Creating an Animated Demo (Optional)

Use these tools to create a demo GIF:

- **LICEcap** (Windows/Mac) - Simple screen recorder
- **GIPHY Capture** (Mac) - Easy GIF creation
- **ScreenToGif** (Windows) - Advanced features
- **Peek** (Linux) - Lightweight GIF recorder

**Demo GIF should show:**
1. Opening DevTools (shake gesture or FAB tap)
2. Navigating between tabs
3. Viewing a network request
4. Switching environments
5. Closing DevTools

**Specifications:**
- Duration: 10-30 seconds
- Resolution: 800-1200px width
- Frame rate: 10-15 fps
- Size: Under 5MB
