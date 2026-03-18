# Flutter Lens 🔍

**A comprehensive real-time widget inspector for Flutter development.**

Inspect any widget in your app with detailed property information, widget tree navigation, and zero external dependencies. Automatically disabled in release builds!

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## ✨ Features

- 🎯 **Tap or long-press** any widget to inspect its properties
- 📊 **Enhanced property extraction** - constraints, padding, text styles, borders, shadows, and more
- 🌳 **Widget tree navigation** - explore parent, children, and ancestor widgets
- 📋 **Copy to clipboard** - copy individual properties or all data at once
- 📤 **Export as JSON** - export inspection data for sharing or debugging
- 🔙 **History navigation** - navigate back and forward through inspections
- 🔍 **Search & filter** - quickly find specific properties
- 📑 **Organized tabs** - Properties, Layout, Styles, and Tree views
- 🎨 **Visual overlay** - green highlight shows selected widget bounds
- 🔄 **Toggle button** - enable/disable inspection mode on the fly
- 🚀 **Zero dependencies** - uses only Flutter SDK
- 🎯 **Debug-only** - automatically disabled in release builds (zero overhead!)

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_lens: ^1.0.0  
```

Or for local development:

```yaml
dependencies:
  flutter_lens:
    path: ../flutter_lens
```

## 🚀 Quick Start

### Basic Usage

Wrap your **entire MaterialApp** with `FlutterLens`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_lens/flutter_lens.dart';

void main() {
  runApp(
    FlutterLens(
      child: MaterialApp(
        home: MyHomePage(),
      ),
    ),
  );
}
```

That's it! Now:
1. **Tap the toggle button** (top-right) to enable inspection
2. **Tap any widget** to inspect it
3. **Explore the tabs** - Properties, Layout, Styles, Tree
4. **Double-tap the green highlight** to dismiss

## ⚙️ Configuration

### Trigger Modes

Choose between tap or long-press to inspect widgets:

```dart
FlutterLens(
  // Tap mode (default) - simple and intuitive
  trigger: InspectionTrigger.tap,
  child: MaterialApp(...),
)

// OR

FlutterLens(
  // Long-press mode - won't interfere with scrolling
  trigger: InspectionTrigger.longPress,
  child: MaterialApp(...),
)
```

### Toggle Button

Show or hide the toggle button:

```dart
FlutterLens(
  showToggleButton: true,  // Show toggle (default)
  // showToggleButton: false,  // Always on, no toggle
  child: MaterialApp(...),
)
```

### Manual Enable/Disable

Control inspection programmatically:

```dart
FlutterLens(
  enabled: false,  // Disable entirely
  child: MaterialApp(...),
)
```

## 🎯 Debug-Only Mode

**FlutterLens automatically disables in release builds!**

- ✅ Works in **debug mode** (during development)
- ✅ Works in **debug APKs** (shared with testers)
- ❌ **Completely removed** in release builds
- 🚀 **Zero performance impact** in production

The Dart compiler uses tree-shaking to remove all FlutterLens code from release builds, so there's absolutely no overhead!

## 📱 Usage Guide

### Inspecting Widgets

1. **Enable inspection** - Tap the toggle button (top-right)
2. **Inspect widget** - Tap (or long-press) any widget
3. **View details** - See all properties in organized tabs

### Tabs Overview

#### 1️⃣ Properties Tab
- All widget properties
- Search and filter
- Basic info (widget type, depth, size, position)

#### 2️⃣ Layout Tab
- Size and position
- Box constraints (min/max width/height)
- Padding and margins
- Layout-specific properties

#### 3️⃣ Styles Tab
- Colors and decorations
- Text styles (font, size, weight)
- Borders and shadows
- Visual appearance properties

#### 4️⃣ Tree Tab
- Parent widget (navigate up)
- Children widgets (navigate down)
- Ancestor chain
- Full widget hierarchy

### Copy & Export

**Copy single property:**
- Long-press any property row → Copied to clipboard!

**Copy all properties:**
- Tap the **copy icon** in header → All properties copied!

**Export as JSON:**
- Tap the **download icon** in header → JSON exported to clipboard!

### History Navigation

- **Back arrow** - Go to previously inspected widget
- **Forward arrow** - Return to newer inspection
- Keeps last 20 inspections

## 🏗️ Architecture

FlutterLens is built with a clean, modular architecture:

```
lib/
├── flutter_lens.dart          # Public API
└── src/
    ├── flutter_lens_widget.dart   # Main widget
    ├── inspection_data.dart       # Data models
    ├── property_extractor.dart    # Property extraction
    ├── widget_inspector.dart      # Inspector & state
    └── ui_components.dart         # UI widgets
```

**Total: ~1300 lines in 5 files**
**Dependencies: 0** (pure Flutter/Dart)

## 🎨 Customization

### Theme Colors

FlutterLens uses a green accent theme by default. The colors are defined in the UI components and can be customized by modifying the source.

Future versions will support theme customization via parameters.

## 📊 APK Size Impact

**~50KB** added to debug builds
**0KB** added to release builds (completely removed!)

The small debug overhead is negligible compared to the development value.

## 🔧 Advanced Usage

### Conditional Enable

Enable only for specific users or environments:

```dart
FlutterLens(
  enabled: _shouldEnableInspector(),
  child: MaterialApp(...),
)

bool _shouldEnableInspector() {
  // Enable for beta testers
  return kDebugMode || isBetaTester;
}
```

### Multiple Screens

FlutterLens works automatically on all screens when wrapped around MaterialApp:

```dart
FlutterLens(
  child: MaterialApp(
    home: HomePage(),
    routes: {
      '/settings': (context) => SettingsPage(),
      '/profile': (context) => ProfilePage(),
    },
  ),
)
// Inspector works on ALL screens! ✅
```

## 📝 Best Practices

1. ✅ **Wrap MaterialApp** - not individual screens
2. ✅ **Use long-press mode** - for better UX with scrolling
3. ✅ **Leave it in debug** - it auto-disables in release
4. ✅ **Share debug APKs** - let testers use the inspector too
5. ❌ **Don't wrap widgets** - wrap the entire app instead

## 🐛 Troubleshooting

### Inspector not opening?

1. Make sure you **enabled the toggle** (tap top-right button)
2. Check if you're using the right **trigger mode** (tap vs long-press)
3. Look for the **green banner** at top when enabled

### Toggle button not showing?

1. Check `showToggleButton: true` parameter
2. Make sure app is in **debug mode**
3. Try hot restart (not just hot reload)

### Properties not showing?

Some widgets may not expose all properties. FlutterLens extracts:
- Standard Flutter widget properties
- Diagnostic properties
- Render object properties

Custom widgets may have limited property extraction.

## 🗺️ Roadmap

Future enhancements:
- [ ] Performance metrics (build/paint times)
- [ ] Theme information extraction
- [ ] Accessibility info
- [ ] Multi-select comparison
- [ ] Visual measurement tools
- [ ] Custom theme colors
- [ ] Export to file (not just clipboard)

## 🤝 Contributing

Contributions are welcome! This is a simple, dependency-free package that aims to stay lean and focused.

## 📄 License

MIT License - feel free to use in any project!

## 💡 Inspiration

Inspired by Flutter DevTools but embedded directly in your app for quick debugging during development.

## 🙏 Support

If you find Flutter Lens helpful:
- ⭐ Star the repo
- 🐛 Report bugs
- 💡 Suggest features
- 📣 Share with others

---

**Made with ❤️ for Flutter developers**
