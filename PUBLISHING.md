# Publishing Guide - Flutter Advanced DevTools

This guide will help you publish the package to pub.dev and ensure everything is ready.

## Pre-Publication Checklist

### 1. Screenshots ✅ (In Progress)

- [x] Create `assets/screenshots/` directory
- [ ] Rename screenshots to proper names:
  - `main_screen.png`
  - `network_logger.png`
  - `network_details.png`
  - `performance_monitor.png`
  - `environment_switcher.png`
  - `permissions.png`
- [ ] Optimize screenshot sizes (< 4MB each)
- [ ] Update `yourusername` in README with actual GitHub username

### 2. Update Package Metadata

Edit `pubspec.yaml`:

```yaml
name: flutter_advanced_devtools
description: A comprehensive developer tools package for Flutter with network logging, performance monitoring, and customizable theming.
version: 1.0.5
homepage: https://github.com/YOURUSERNAME/flutter_advanced_devtools
repository: https://github.com/YOURUSERNAME/flutter_advanced_devtools
issue_tracker: https://github.com/YOURUSERNAME/flutter_advanced_devtools/issues
documentation: https://github.com/YOURUSERNAME/flutter_advanced_devtools#readme

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.0.0"
```

### 3. Documentation Files

- [x] README.md - Comprehensive with examples
- [x] CHANGELOG.md - Version history
- [ ] LICENSE - Add MIT license file
- [ ] Example app in `/example` directory

### 4. Code Quality

Run these commands:

```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Run tests (if you have any)
flutter test

# Check pub.dev score
dart pub publish --dry-run
```

### 5. GitHub Setup

```bash
# Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit for pub.dev publication"

# Create GitHub repository and push
git remote add origin https://github.com/YOURUSERNAME/flutter_advanced_devtools.git
git branch -M main
git push -u origin main
```

### 6. Update GitHub URLs

Replace `yourusername` in these files:
- [ ] README.md (screenshot URLs)
- [ ] CHANGELOG.md (release links)
- [ ] pubspec.yaml (homepage, repository)

### 7. Publish to pub.dev

```bash
# Dry run first (check for issues)
dart pub publish --dry-run

# If all looks good, publish
dart pub publish
```

---

## Quick Commands Reference

### Rename Screenshots
```bash
./scripts/rename_screenshots.sh
```

### Optimize Screenshots
```bash
./scripts/prepare_screenshots.sh
```

### Update GitHub Username in README
```bash
# Replace 'yourusername' with your actual username
sed -i '' 's/yourusername/YOUR_GITHUB_USERNAME/g' README.md
```

### Check Package Health
```bash
dart pub publish --dry-run
```

### Git Push
```bash
git add .
git commit -m "docs: Prepare for pub.dev publication"
git push origin main
```

---

## Post-Publication

After publishing to pub.dev:

1. **Add Topics** on pub.dev:
   - flutter
   - developer-tools
   - debugging
   - network-logger
   - performance-monitoring
   - dio
   - devtools

2. **Create GitHub Release**:
   - Go to GitHub → Releases → Create new release
   - Tag: `v1.0.5`
   - Title: `v1.0.5 - Initial Publication`
   - Description: Copy from CHANGELOG.md

3. **Share**:
   - Tweet about the package
   - Post on Reddit: r/FlutterDev
   - Share in Flutter Discord/Slack communities

4. **Monitor**:
   - Check pub.dev score
   - Respond to issues
   - Keep documentation updated

---

## pubspec.yaml Example

```yaml
name: flutter_advanced_devtools
description: |
  A comprehensive developer tools package for Flutter applications. 
  Features network logging with Dio, performance monitoring, environment switching,
  exception handling, and customizable theming.
version: 1.0.5
homepage: https://github.com/YOURUSERNAME/flutter_advanced_devtools
repository: https://github.com/YOURUSERNAME/flutter_advanced_devtools
issue_tracker: https://github.com/YOURUSERNAME/flutter_advanced_devtools/issues

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0
  device_info_plus: ^9.0.0
  package_info_plus: ^4.0.0
  permission_handler: ^11.0.0
  firebase_messaging: ^14.0.0
  flutter_local_notifications: ^16.0.0
  sensors_plus: ^4.0.0
  share_plus: ^7.0.0
  shared_preferences: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  assets:
    - assets/lang/en.json
    - assets/lang/ar.json
```

---

## Common Issues

### Issue: Package name already taken
**Solution**: Choose a different name (e.g., `flutter_dev_toolkit`, `flutter_debug_tools`)

### Issue: Score too low on pub.dev
**Solution**: 
- Add example app
- Improve documentation
- Add tests
- Follow Dart/Flutter style guides

### Issue: Screenshots not showing on GitHub
**Solution**: 
- Make sure repository is public
- Check file paths in README (case-sensitive)
- Wait a few minutes for GitHub cache to update

---

## Resources

- [pub.dev Publishing Guide](https://dart.dev/tools/pub/publishing)
- [Package Layout Conventions](https://dart.dev/tools/pub/package-layout)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Package Development](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)
