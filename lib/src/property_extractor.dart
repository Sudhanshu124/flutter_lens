import 'package:flutter/material.dart';

/// Extracts comprehensive properties from widgets
class PropertyExtractor {
  /// Extract all properties from a widget and its render object
  Map<String, String> extractAllProperties(
      Element element, RenderBox renderBox) {
    final properties = <String, String>{};

    // Basic properties
    properties.addAll(_extractBasicProperties(element, renderBox));

    // Box constraints
    properties.addAll(_extractBoxConstraints(renderBox));

    // Widget-specific properties
    final widget = element.widget;
    try {
      final padding = _extractPadding(widget);
      if (padding != null) properties.addAll(padding);

      final textStyle = _extractTextStyle(widget);
      if (textStyle != null) properties.addAll(textStyle);

      final decoration = _extractDecoration(widget);
      if (decoration != null) properties.addAll(decoration);

      final imageProps = _extractImageProperties(widget);
      if (imageProps != null) properties.addAll(imageProps);

      final iconProps = _extractIconProperties(widget);
      if (iconProps != null) properties.addAll(iconProps);

      final opacity = _extractOpacity(widget);
      if (opacity != null) properties.addAll(opacity);

      final alignment = _extractAlignment(widget);
      if (alignment != null) properties.addAll(alignment);
    } catch (e) {
      debugPrint('Property extraction error: $e');
    }

    // Diagnostic properties (from Flutter's diagnostics)
    properties.addAll(_extractDiagnosticProperties(element));

    return properties;
  }

  Map<String, String> _extractBasicProperties(
      Element element, RenderBox renderBox) {
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    return {
      'Widget': element.widget.runtimeType.toString(),
      'Depth': element.depth.toString(),
      'Size': '${size.width.toInt()} x ${size.height.toInt()}',
      'Position': 'x:${position.dx.toInt()}, y:${position.dy.toInt()}',
    };
  }

  Map<String, String> _extractBoxConstraints(RenderBox box) {
    try {
      final constraints = box.constraints;
      return {
        'Min Width': '${constraints.minWidth.toStringAsFixed(1)}px',
        'Max Width': constraints.maxWidth.isFinite
            ? '${constraints.maxWidth.toStringAsFixed(1)}px'
            : 'Infinity',
        'Min Height': '${constraints.minHeight.toStringAsFixed(1)}px',
        'Max Height': constraints.maxHeight.isFinite
            ? '${constraints.maxHeight.toStringAsFixed(1)}px'
            : 'Infinity',
        'Is Tight': constraints.isTight ? 'Yes' : 'No',
      };
    } catch (e) {
      return {};
    }
  }

  Map<String, String>? _extractPadding(Widget widget) {
    EdgeInsetsGeometry? padding;

    if (widget is Container && widget.padding != null) {
      padding = widget.padding;
    } else if (widget is Padding) {
      padding = widget.padding;
    }

    if (padding != null) {
      final resolved = padding.resolve(TextDirection.ltr);
      return {
        'Padding Top': '${resolved.top.toStringAsFixed(1)}px',
        'Padding Right': '${resolved.right.toStringAsFixed(1)}px',
        'Padding Bottom': '${resolved.bottom.toStringAsFixed(1)}px',
        'Padding Left': '${resolved.left.toStringAsFixed(1)}px',
      };
    }
    return null;
  }

  Map<String, String>? _extractTextStyle(Widget widget) {
    TextStyle? style;

    if (widget is Text && widget.style != null) {
      style = widget.style;
    } else if (widget is RichText && widget.text is TextSpan) {
      style = (widget.text as TextSpan).style;
    }

    if (style != null) {
      return {
        if (style.fontFamily != null) 'Font Family': style.fontFamily!,
        'Font Size': '${style.fontSize?.toStringAsFixed(1) ?? '14.0'}px',
        if (style.fontWeight != null)
          'Font Weight': style.fontWeight.toString().split('.').last,
        if (style.letterSpacing != null)
          'Letter Spacing': '${style.letterSpacing!.toStringAsFixed(1)}px',
        if (style.height != null)
          'Line Height': style.height!.toStringAsFixed(2),
        if (style.color != null) 'Text Color': _colorToHex(style.color!),
      };
    }
    return null;
  }

  Map<String, String>? _extractDecoration(Widget widget) {
    BoxDecoration? decoration;

    if (widget is Container && widget.decoration is BoxDecoration) {
      decoration = widget.decoration as BoxDecoration;
    } else if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
      decoration = widget.decoration as BoxDecoration;
    }

    if (decoration != null) {
      final properties = <String, String>{};

      if (decoration.color != null) {
        properties['Background Color'] = _colorToHex(decoration.color!);
      }

      if (decoration.border != null && decoration.border is Border) {
        final border = decoration.border as Border;
        if (border.top.width > 0) {
          properties['Border Top'] =
              '${border.top.width.toStringAsFixed(1)}px ${_colorToHex(border.top.color)}';
        }
        if (border.right.width > 0) {
          properties['Border Right'] =
              '${border.right.width.toStringAsFixed(1)}px ${_colorToHex(border.right.color)}';
        }
        if (border.bottom.width > 0) {
          properties['Border Bottom'] =
              '${border.bottom.width.toStringAsFixed(1)}px ${_colorToHex(border.bottom.color)}';
        }
        if (border.left.width > 0) {
          properties['Border Left'] =
              '${border.left.width.toStringAsFixed(1)}px ${_colorToHex(border.left.color)}';
        }
      }

      if (decoration.borderRadius != null &&
          decoration.borderRadius is BorderRadius) {
        final br = decoration.borderRadius as BorderRadius;
        properties['Border Radius'] =
            'TL:${br.topLeft.x.toInt()} TR:${br.topRight.x.toInt()} BR:${br.bottomRight.x.toInt()} BL:${br.bottomLeft.x.toInt()}';
      }

      if (decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty) {
        final shadow = decoration.boxShadow!.first;
        properties['Shadow'] =
            'blur:${shadow.blurRadius.toInt()} offset:(${shadow.offset.dx.toInt()},${shadow.offset.dy.toInt()})';
      }

      return properties.isNotEmpty ? properties : null;
    }
    return null;
  }

  Map<String, String>? _extractImageProperties(Widget widget) {
    if (widget is Image) {
      final properties = <String, String>{};

      if (widget.width != null) {
        properties['Image Width'] = '${widget.width!.toInt()}px';
      }
      if (widget.height != null) {
        properties['Image Height'] = '${widget.height!.toInt()}px';
      }

      properties['Fit'] = widget.fit?.toString().split('.').last ?? 'none';
      properties['Repeat'] = widget.repeat.toString().split('.').last;

      return properties;
    }
    return null;
  }

  Map<String, String>? _extractIconProperties(Widget widget) {
    if (widget is Icon) {
      final properties = <String, String>{};

      if (widget.size != null) {
        properties['Icon Size'] = '${widget.size!.toInt()}px';
      }
      if (widget.color != null) {
        properties['Icon Color'] = _colorToHex(widget.color!);
      }

      return properties;
    }
    return null;
  }

  Map<String, String>? _extractOpacity(Widget widget) {
    if (widget is Opacity) {
      return {'Opacity': widget.opacity.toStringAsFixed(2)};
    }
    return null;
  }

  Map<String, String>? _extractAlignment(Widget widget) {
    Alignment? alignment;

    if (widget is Align && widget.alignment is Alignment) {
      alignment = widget.alignment as Alignment;
    } else if (widget is Container && widget.alignment is Alignment) {
      alignment = widget.alignment as Alignment;
    }

    if (alignment != null) {
      return {
        'Alignment': 'x:${alignment.x.toStringAsFixed(2)}, y:${alignment.y.toStringAsFixed(2)}'
      };
    }
    return null;
  }

  Map<String, String> _extractDiagnosticProperties(Element element) {
    final properties = <String, String>{};
    final props = element.toDiagnosticsNode().getProperties();

    for (var prop in props) {
      final name = prop.name;
      if (name == null) continue;

      if (prop.value is Color) {
        properties[name] = _colorToHex(prop.value as Color);
      } else {
        final description = prop.toDescription();
        if (description.isNotEmpty) {
          properties[name] = description;
        }
      }
    }

    return properties;
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
