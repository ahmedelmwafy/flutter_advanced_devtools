#!/bin/bash

# Screenshot preparation script for Flutter Advanced DevTools
# This script helps optimize and prepare screenshots for GitHub and pub.dev

set -e

SCREENSHOTS_DIR="assets/screenshots"
GITHUB_USER="yourusername"  # TODO: Update with your GitHub username
REPO_NAME="flutter_advanced_devtools"

echo "🖼️  Flutter Advanced DevTools - Screenshot Helper"
echo "================================================"
echo ""

# Check if screenshots directory exists
if [ ! -d "$SCREENSHOTS_DIR" ]; then
    echo "❌ Error: $SCREENSHOTS_DIR directory not found"
    exit 1
fi

# Count screenshot files
PNG_COUNT=$(find "$SCREENSHOTS_DIR" -name "*.png" -type f | wc -l | tr -d ' ')
JPG_COUNT=$(find "$SCREENSHOTS_DIR" -name "*.jpg" -o -name "*.jpeg" -type f | wc -l | tr -d ' ')
GIF_COUNT=$(find "$SCREENSHOTS_DIR" -name "*.gif" -type f | wc -l | tr -d ' ')

echo "📊 Current screenshots:"
echo "   PNG files: $PNG_COUNT"
echo "   JPG files: $JPG_COUNT"
echo "   GIF files: $GIF_COUNT"
echo ""

# List all image files
if [ "$PNG_COUNT" -gt 0 ] || [ "$JPG_COUNT" -gt 0 ] || [ "$GIF_COUNT" -gt 0 ]; then
    echo "📁 Files in $SCREENSHOTS_DIR:"
    ls -lh "$SCREENSHOTS_DIR"/*.{png,jpg,jpeg,gif} 2>/dev/null || true
    echo ""
fi

# Check for required screenshots
REQUIRED_SCREENSHOTS=(
    "main_screen.png"
    "network_logger.png"
    "network_details.png"
    "performance_monitor.png"
    "environment_switcher.png"
    "permissions.png"
)

echo "✅ Checking required screenshots:"
MISSING_COUNT=0
for screenshot in "${REQUIRED_SCREENSHOTS[@]}"; do
    if [ -f "$SCREENSHOTS_DIR/$screenshot" ]; then
        SIZE=$(du -h "$SCREENSHOTS_DIR/$screenshot" | cut -f1)
        echo "   ✓ $screenshot ($SIZE)"
    else
        echo "   ✗ $screenshot (missing)"
        ((MISSING_COUNT++))
    fi
done
echo ""

if [ "$MISSING_COUNT" -gt 0 ]; then
    echo "⚠️  Warning: $MISSING_COUNT required screenshot(s) missing"
    echo "   See assets/screenshots/SCREENSHOTS_GUIDE.md for instructions"
    echo ""
fi

# Optimization options
echo "🔧 Optimization options:"
echo "   1. Optimize PNGs (requires optipng)"
echo "   2. Resize images to 1080px width (requires ImageMagick)"
echo "   3. Convert to optimized WebP (requires cwebp)"
echo "   4. Update GitHub URLs in README"
echo "   5. Git add and commit screenshots"
echo "   6. Skip optimization"
echo ""

read -p "Select option (1-6): " option

case $option in
    1)
        if command -v optipng &> /dev/null; then
            echo "🔄 Optimizing PNGs..."
            optipng -o7 "$SCREENSHOTS_DIR"/*.png 2>/dev/null || echo "No PNG files to optimize"
            echo "✅ PNG optimization complete"
        else
            echo "❌ optipng not installed. Install with: brew install optipng"
        fi
        ;;
    2)
        if command -v mogrify &> /dev/null; then
            echo "🔄 Resizing images to 1080px width..."
            mogrify -resize 1080x "$SCREENSHOTS_DIR"/*.{png,jpg,jpeg} 2>/dev/null || echo "No images to resize"
            echo "✅ Resize complete"
        else
            echo "❌ ImageMagick not installed. Install with: brew install imagemagick"
        fi
        ;;
    3)
        if command -v cwebp &> /dev/null; then
            echo "🔄 Converting to WebP..."
            for img in "$SCREENSHOTS_DIR"/*.{png,jpg,jpeg}; do
                [ -f "$img" ] && cwebp -q 80 "$img" -o "${img%.*}.webp"
            done
            echo "✅ WebP conversion complete"
        else
            echo "❌ cwebp not installed. Install with: brew install webp"
        fi
        ;;
    4)
        echo "🔄 Updating GitHub URLs in README..."
        echo "   Current GitHub user: $GITHUB_USER"
        read -p "   Enter your GitHub username: " NEW_USER
        
        if [ ! -z "$NEW_USER" ]; then
            sed -i.bak "s/yourusername/$NEW_USER/g" README.md
            rm README.md.bak 2>/dev/null || true
            echo "✅ URLs updated with username: $NEW_USER"
        fi
        ;;
    5)
        echo "🔄 Adding files to git..."
        git add assets/screenshots/
        git add README.md
        
        read -p "   Enter commit message (or press Enter for default): " COMMIT_MSG
        if [ -z "$COMMIT_MSG" ]; then
            COMMIT_MSG="docs: Add screenshots and update README"
        fi
        
        git commit -m "$COMMIT_MSG"
        echo "✅ Changes committed"
        echo ""
        echo "📤 Ready to push! Run: git push origin main"
        ;;
    6)
        echo "⏭️  Skipping optimization"
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "✨ Done! Next steps:"
echo "   1. Review your screenshots"
echo "   2. Update GitHub username in README.md (if not done)"
echo "   3. Run: git add . && git commit -m 'docs: Add screenshots'"
echo "   4. Run: git push origin main"
echo "   5. Screenshots will be available at:"
echo "      https://raw.githubusercontent.com/$GITHUB_USER/$REPO_NAME/main/assets/screenshots/"
