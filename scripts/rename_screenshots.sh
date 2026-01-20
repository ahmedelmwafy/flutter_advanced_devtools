#!/bin/bash

# Screenshot renaming helper
# This script helps you rename simulator screenshots to the proper naming convention

SCREENSHOTS_DIR="assets/screenshots"

echo "🖼️  Screenshot Renaming Helper"
echo "=============================="
echo ""
echo "Found screenshots:"
echo ""

# List all simulator screenshots
counter=1
for file in "$SCREENSHOTS_DIR"/Simulator*.png; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        echo "$counter. $(basename "$file") - $size"
        ((counter++))
    fi
done

echo ""
echo "Suggested naming convention:"
echo "1. main_screen.png          - Main DevTools overlay (Info tab)"
echo "2. network_logger.png       - Network requests list"
echo "3. network_details.png      - Detailed request view"
echo "4. performance_monitor.png  - Performance metrics"
echo "5. environment_switcher.png - Environment selection"
echo "6. permissions.png          - Permissions manager"
echo "7. exceptions.png           - Exception logger"
echo "8. settings.png             - Settings screen"
echo ""

read -p "Would you like to rename screenshots interactively? (y/n): " answer

if [ "$answer" != "y" ]; then
    echo "Skipping rename. You can manually rename files."
    exit 0
fi

echo ""
echo "Let's rename each screenshot..."
echo "Enter the new name (without .png) or press Enter to skip"
echo ""

for file in "$SCREENSHOTS_DIR"/Simulator*.png; do
    if [ -f "$file" ]; then
        basename_file=$(basename "$file")
        echo "Current: $basename_file"
        read -p "New name (or Enter to skip): " newname
        
        if [ ! -z "$newname" ]; then
            # Add .png if not present
            if [[ ! "$newname" =~ \.png$ ]]; then
                newname="${newname}.png"
            fi
            
            mv "$file" "$SCREENSHOTS_DIR/$newname"
            echo "✅ Renamed to: $newname"
        else
            echo "⏭️  Skipped"
        fi
        echo ""
    fi
done

echo "✨ Done! Your screenshots:"
ls -lh "$SCREENSHOTS_DIR"/*.png 2>/dev/null | grep -v "Simulator"

echo ""
echo "Next steps:"
echo "1. Review renamed files"
echo "2. Run: git add assets/screenshots/"
echo "3. Run: git commit -m 'docs: Rename screenshots'"
echo "4. Run: git push origin main"
