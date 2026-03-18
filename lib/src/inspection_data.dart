import 'package:flutter/material.dart';

/// Represents all data from a widget inspection
class WidgetInspectionData {
  final String id;
  final String widgetType;
  final int depth;
  final Size size;
  final Offset position;
  final Map<String, String> properties;
  final Element? element;
  final DateTime timestamp;

  WidgetInspectionData({
    required this.id,
    required this.widgetType,
    required this.depth,
    required this.size,
    required this.position,
    required this.properties,
    this.element,
    required this.timestamp,
  });

  Rect get rect => position & size;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'widgetType': widgetType,
      'depth': depth,
      'size': {'width': size.width, 'height': size.height},
      'position': {'x': position.dx, 'y': position.dy},
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum PropertyCategory {
  basic,
  layout,
  spacing,
  appearance,
  typography,
  other,
}

PropertyCategory categorizePropertyKey(String key) {
  final lowerKey = key.toLowerCase();

  if (lowerKey.contains('widget') || lowerKey.contains('depth')) {
    return PropertyCategory.basic;
  }

  if (lowerKey.contains('size') ||
      lowerKey.contains('position') ||
      lowerKey.contains('constraint') ||
      lowerKey.contains('width') ||
      lowerKey.contains('height')) {
    return PropertyCategory.layout;
  }

  if (lowerKey.contains('padding') ||
      lowerKey.contains('margin') ||
      lowerKey.contains('inset')) {
    return PropertyCategory.spacing;
  }

  if (lowerKey.contains('color') ||
      lowerKey.contains('decoration') ||
      lowerKey.contains('border') ||
      lowerKey.contains('shadow') ||
      lowerKey.contains('background')) {
    return PropertyCategory.appearance;
  }

  if (lowerKey.contains('font') ||
      lowerKey.contains('text') ||
      lowerKey.contains('style') ||
      lowerKey.contains('letter') ||
      lowerKey.contains('line')) {
    return PropertyCategory.typography;
  }

  return PropertyCategory.other;
}

