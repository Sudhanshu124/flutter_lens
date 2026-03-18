// Flutter Lens - Real-time Widget Inspector
//
// A comprehensive developer tool for inspecting Flutter widgets in real-time.
// Automatically disabled in release mode — zero performance impact in production.
//
// Usage: Wrap your MaterialApp with FlutterLens:
//
// FlutterLens(
//   child: MaterialApp(...),
// )
//
// Entry Point:
// - Tap the eye icon (top-right) to open the action menu
// - Action menu options:
//     Inspect → toggles tap-to-inspect mode (shows ON badge when active)
//     Network → opens the standalone network monitor screen
//
// Widget Inspection:
// - Long-press any widget at any time to open the full-screen inspection panel
// - Inspection panel slides up/down with animation
// - Auto-dismisses when navigating away or the widget unmounts
//
// Inspection Panel Tabs:
// - Properties: all extracted widget properties
// - Layout: size, position, and constraints
// - Styles: colors, decoration, and typography
// - Tree: ancestor chain and children navigation
//
// Network Monitor:
// - Accessible independently via the action menu — no widget selection needed
// - Shows method, URL, status, duration, headers, and response body
// - Clear all calls from within the screen
//
// Other:
// - Back/forward history navigation across inspections
// - Copy individual properties or all properties to clipboard
// - Zero external dependencies!

export 'src/flutter_lens_widget.dart' show FlutterLens, InspectionTrigger;
