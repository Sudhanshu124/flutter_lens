import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'inspection_data.dart';
import 'property_extractor.dart';

/// Core inspection service - handles hit testing and widget tree navigation
class WidgetInspector {
  final PropertyExtractor _extractor = PropertyExtractor();

  /// Inspect widget at a given screen position
  WidgetInspectionData? inspectWidgetAt(Offset position, int viewId) {
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, position, viewId);

    for (final HitTestEntry entry in result.path) {
      final target = entry.target;

      if (target is RenderBox) {
        // Skip internal Flutter widgets
        final typeName = target.runtimeType.toString();
        if (_shouldSkip(typeName)) continue;

        final creator = target.debugCreator;
        if (creator is DebugCreator) {
          final element = creator.element;
          final properties = _extractor.extractAllProperties(element, target);

          return WidgetInspectionData(
            id: _generateId(element),
            widgetType: element.widget.runtimeType.toString(),
            depth: element.depth,
            size: target.size,
            position: target.localToGlobal(Offset.zero),
            properties: properties,
            element: element,
            timestamp: DateTime.now(),
          );
        }
        break;
      }
    }
    return null;
  }

  /// Get parent widget of current element
  WidgetInspectionData? getParent(Element element) {
    Element? parent;
    element.visitAncestorElements((ancestor) {
      if (!_shouldSkipElement(ancestor)) {
        parent = ancestor;
        return false;
      }
      return true;
    });

    if (parent != null && parent!.renderObject is RenderBox) {
      final renderBox = parent!.renderObject as RenderBox;
      final properties = _extractor.extractAllProperties(parent!, renderBox);

      return WidgetInspectionData(
        id: _generateId(parent!),
        widgetType: parent!.widget.runtimeType.toString(),
        depth: parent!.depth,
        size: renderBox.size,
        position: renderBox.localToGlobal(Offset.zero),
        properties: properties,
        element: parent,
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  /// Get children widgets of current element
  List<WidgetInspectionData> getChildren(Element element) {
    final children = <WidgetInspectionData>[];

    element.visitChildren((child) {
      if (!_shouldSkipElement(child) && child.renderObject is RenderBox) {
        final renderBox = child.renderObject as RenderBox;
        final properties = _extractor.extractAllProperties(child, renderBox);

        children.add(WidgetInspectionData(
          id: _generateId(child),
          widgetType: child.widget.runtimeType.toString(),
          depth: child.depth,
          size: renderBox.size,
          position: renderBox.localToGlobal(Offset.zero),
          properties: properties,
          element: child,
          timestamp: DateTime.now(),
        ));
      }
    });

    return children;
  }

  /// Get ancestor chain from root to current element
  List<WidgetInspectionData> getAncestorChain(Element element) {
    final ancestors = <WidgetInspectionData>[];

    element.visitAncestorElements((ancestor) {
      if (!_shouldSkipElement(ancestor) && ancestor.renderObject is RenderBox) {
        final renderBox = ancestor.renderObject as RenderBox;
        final properties = _extractor.extractAllProperties(ancestor, renderBox);

        ancestors.insert(
          0,
          WidgetInspectionData(
            id: _generateId(ancestor),
            widgetType: ancestor.widget.runtimeType.toString(),
            depth: ancestor.depth,
            size: renderBox.size,
            position: renderBox.localToGlobal(Offset.zero),
            properties: properties,
            element: ancestor,
            timestamp: DateTime.now(),
          ),
        );
      }
      return true;
    });

    return ancestors;
  }

  bool _shouldSkip(String typeName) {
    return typeName.contains('RenderPointerListener') ||
        typeName.contains('RenderSemanticsAnnotations') ||
        typeName.contains('RenderIgnorePointer') ||
        typeName.startsWith('_');
  }

  bool _shouldSkipElement(Element element) {
    final type = element.widget.runtimeType.toString();
    return type.startsWith('_') ||
        type.contains('Semantics') ||
        type.contains('Listener') ||
        type.contains('GestureDetector') ||
        type.contains('IgnorePointer');
  }

  String _generateId(Element element) {
    return '${element.widget.runtimeType}_${element.depth}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Clipboard utilities for copying inspection data
class ClipboardHelper {
  static Future<void> copyProperty(String key, String value) async {
    await Clipboard.setData(ClipboardData(text: '$key: $value'));
  }

  static Future<void> copyAllProperties(WidgetInspectionData data) async {
    final buffer = StringBuffer();
    buffer.writeln('Widget: ${data.widgetType}');
    buffer.writeln(
        'Size: ${data.size.width.toInt()} x ${data.size.height.toInt()}');
    buffer.writeln(
        'Position: ${data.position.dx.toInt()}, ${data.position.dy.toInt()}');
    buffer.writeln('---');
    data.properties.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

}

/// State management for inspection using ChangeNotifier
class InspectionController extends ChangeNotifier {
  final WidgetInspector _inspector = WidgetInspector();

  WidgetInspectionData? _currentInspection;
  final List<WidgetInspectionData> _history = [];
  int _historyIndex = -1;
  int _selectedTabIndex = 0;

  WidgetInspectionData? get currentInspection => _currentInspection;
  List<WidgetInspectionData> get history => List.unmodifiable(_history);
  bool get canGoBack => _historyIndex > 0;
  bool get canGoForward => _historyIndex < _history.length - 1;
  int get selectedTabIndex => _selectedTabIndex;

  /// Inspect widget at position
  Future<void> inspectAt(Offset position, int viewId) async {
    final data = _inspector.inspectWidgetAt(position, viewId);
    if (data != null) {
      _currentInspection = data;

      // Add to history and trim if needed
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      _history.add(data);
      if (_history.length > 20) {
        _history.removeAt(0);
      } else {
        _historyIndex++;
      }

      notifyListeners();
    }
  }

  /// Navigate to parent widget
  void navigateToParent() {
    if (_currentInspection?.element != null) {
      final parent = _inspector.getParent(_currentInspection!.element!);
      if (parent != null) {
        _currentInspection = parent;
        _addToHistory(parent);
        notifyListeners();
      }
    }
  }

  /// Navigate to child widget
  void navigateToChild(Element childElement) {
    if (childElement.renderObject is RenderBox) {
      final data = _inspector.inspectWidgetAt(
        (childElement.renderObject as RenderBox).localToGlobal(Offset.zero),
        0,
      );
      if (data != null) {
        _currentInspection = data;
        _addToHistory(data);
        notifyListeners();
      }
    }
  }

  /// Go back in history
  void goBack() {
    if (canGoBack) {
      _historyIndex--;
      _currentInspection = _history[_historyIndex];
      notifyListeners();
    }
  }

  /// Go forward in history
  void goForward() {
    if (canGoForward) {
      _historyIndex++;
      _currentInspection = _history[_historyIndex];
      notifyListeners();
    }
  }

  /// Clear current inspection
  void clearInspection() {
    _currentInspection = null;
    notifyListeners();
  }

  /// Set selected tab
  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void _addToHistory(WidgetInspectionData data) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(data);
    if (_history.length > 20) {
      _history.removeAt(0);
    } else {
      _historyIndex++;
    }
  }

  /// Get children of current widget
  List<WidgetInspectionData> getCurrentChildren() {
    if (_currentInspection?.element != null) {
      return _inspector.getChildren(_currentInspection!.element!);
    }
    return [];
  }

  /// Get ancestor chain of current widget
  List<WidgetInspectionData> getCurrentAncestors() {
    if (_currentInspection?.element != null) {
      return _inspector.getAncestorChain(_currentInspection!.element!);
    }
    return [];
  }
}
