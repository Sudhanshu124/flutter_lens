import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'widget_inspector.dart';
import 'ui_components.dart';
import 'highlight_painter.dart';
import 'network_monitor.dart';

enum InspectionTrigger {
  tap,     
  longPress, 
}


class FlutterLens extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool showToggleButton;
  final InspectionTrigger trigger;
  final Alignment toggleButtonAlignment;

  const FlutterLens({
    super.key,
    required this.child,
    this.enabled = true,
    this.showToggleButton = true,
    this.trigger = InspectionTrigger.longPress,
    this.toggleButtonAlignment = Alignment.topRight,
  });

  @override
  State<FlutterLens> createState() => _FlutterLensState();
}

class _FlutterLensState extends State<FlutterLens>
    with TickerProviderStateMixin {
  final InspectionController _controller = InspectionController();
  bool _inspectionEnabled = false;
  bool _networkScreenOpen = false;
  bool _menuOpen = false;
  static bool _networkMonitoringEnabled = false;
  bool _elementCheckScheduled = false;

  Offset _buttonPosition = Offset.zero;
  bool _buttonPositionInitialized = false;
  double _buttonOpacity = 0.4;
  Timer? _opacityTimer;
  bool _isDragging = false;

  late final AnimationController _inspectionSlideController;
  late final AnimationController _networkSlideController;
  late final Animation<Offset> _inspectionSlideAnimation;
  late final Animation<Offset> _networkSlideAnimation;

  @override
  void initState() {
    super.initState();
    _inspectionSlideController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _networkSlideController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _inspectionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _inspectionSlideController,
      curve: Curves.easeOutCubic,
    ));
    _networkSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _networkSlideController,
      curve: Curves.easeOutCubic,
    ));
    _controller.addListener(_onInspectionChanged);
    if (!_networkMonitoringEnabled && !kReleaseMode && widget.enabled) {
      HttpOverrides.global = NetworkMonitorHttpOverrides();
      _networkMonitoringEnabled = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_buttonPositionInitialized) {
      final size = MediaQuery.of(context).size;
      final padding = MediaQuery.of(context).padding;
      _buttonPosition = Offset(size.width - 56, padding.top + 10);
      _buttonPositionInitialized = true;
    }
  }

  @override
  void dispose() {
    _opacityTimer?.cancel();
    _inspectionSlideController.dispose();
    _networkSlideController.dispose();
    _controller.removeListener(_onInspectionChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onInspectionChanged() {
    if (_controller.currentInspection != null) {
      setState(() => _menuOpen = false);
      _inspectionSlideController.forward();
      _scheduleElementCheck();
    }
  }

  void _scheduleElementCheck() {
    if (_elementCheckScheduled) return;
    _elementCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _elementCheckScheduled = false;
      if (!mounted) return;
      _checkInspectionValidity();
      if (_controller.currentInspection != null) {
        _scheduleElementCheck();
      }
    });
  }

  void _checkInspectionValidity() {
    final inspection = _controller.currentInspection;
    if (inspection?.element == null) return;

    final element = inspection!.element!;

    if (!element.mounted) {
      _dismissInspector();
      return;
    }

    try {
      final route = ModalRoute.of(element);
      if (route != null && !route.isCurrent) {
        _dismissInspector();
      }
    } catch (_) {}
  }

  void _handleTap(PointerDownEvent event) {
    if (!widget.enabled || !_inspectionEnabled) return;
    _controller.inspectAt(event.position, event.viewId);
  }

  void _handleLongPress(LongPressStartDetails details) {
    if (!widget.enabled || !_inspectionEnabled) return;
    _controller.inspectAt(details.globalPosition, 0);
  }

  void _dismissInspector() {
    _inspectionSlideController.reverse().then((_) {
      if (mounted) _controller.clearInspection();
    });
  }

  void _toggleInspection() {
    setState(() => _inspectionEnabled = !_inspectionEnabled);
    if (!_inspectionEnabled) _dismissInspector();
  }

  void _toggleNetworkScreen() {
    if (_networkScreenOpen) {
      _networkSlideController.reverse().then((_) {
        if (mounted) setState(() => _networkScreenOpen = false);
      });
    } else {
      setState(() => _networkScreenOpen = true);
      _networkSlideController.forward();
    }
  }

  void _onButtonInteraction() {
    _opacityTimer?.cancel();
    setState(() => _buttonOpacity = 1.0);
    _opacityTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_menuOpen) setState(() => _buttonOpacity = 0.4);
    });
  }

  void _snapToEdge() {
    final size = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;
    const buttonSize = 44.0;
    const edgePadding = 8.0;
    final snapToRight =
        _buttonPosition.dx + buttonSize / 2 > size.width / 2;
    setState(() {
      _buttonPosition = Offset(
        snapToRight ? size.width - buttonSize - edgePadding : edgePadding,
        _buttonPosition.dy.clamp(
          safePadding.top + 10,
          size.height - buttonSize - safePadding.bottom - 10,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
   
    if (kReleaseMode || !widget.enabled) {
      return widget.child;
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
     
            widget.trigger == InspectionTrigger.tap
                ? Listener(
                    onPointerDown: _handleTap,
                    behavior: HitTestBehavior.translucent,
                    child: widget.child,
                  )
                : GestureDetector(
                    onLongPressStart: _handleLongPress,
                    behavior: HitTestBehavior.translucent,
                    child: widget.child,
                  ),

      
            if (_inspectionEnabled)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 60,
                      left: 10,
                      right: 10,
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.touch_app,
                                size: 16, color: Colors.black87),
                            const SizedBox(width: 6),
                            Text(
                              widget.trigger == InspectionTrigger.tap
                                  ? 'Tap any widget to inspect'
                                  : 'Long-press any widget to inspect',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (_menuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _menuOpen = false),
                  behavior: HitTestBehavior.translucent,
                ),
              ),

            if (widget.showToggleButton && _buttonPositionInitialized)
              AnimatedPositioned(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: (_buttonPosition.dx + 22 <= MediaQuery.of(context).size.width / 2)
                    ? _buttonPosition.dx
                    : null,
                right: (_buttonPosition.dx + 22 > MediaQuery.of(context).size.width / 2)
                    ? MediaQuery.of(context).size.width - _buttonPosition.dx - 44
                    : null,
                top: _buttonPosition.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onPanStart: (_) {
                    setState(() {
                      _isDragging = true;
                      _menuOpen = false;
                    });
                    _onButtonInteraction();
                  },
                  onPanUpdate: (details) {
                    final size = MediaQuery.of(context).size;
                    setState(() {
                      _buttonPosition = Offset(
                        (_buttonPosition.dx + details.delta.dx)
                            .clamp(0.0, size.width - 44.0),
                        (_buttonPosition.dy + details.delta.dy)
                            .clamp(0.0, size.height - 44.0),
                      );
                    });
                  },
                  onPanEnd: (_) {
                    setState(() => _isDragging = false);
                    _snapToEdge();
                  },
                  child: AnimatedOpacity(
                    opacity: _buttonOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: _buildActionMenu(),
                  ),
                ),
              ),

            // Highlight overlay
            if (_controller.currentInspection != null)
              Positioned.fromRect(
                rect: _controller.currentInspection!.rect,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: HighlightPainter(
                      Rect.fromLTWH(
                        0,
                        0,
                        _controller.currentInspection!.size.width,
                        _controller.currentInspection!.size.height,
                      ),
                    ),
                  ),
                ),
              ),

            Positioned.fill(
              child: AnimatedBuilder(
                animation: _inspectionSlideController,
                builder: (context, child) => IgnorePointer(
                  ignoring: _inspectionSlideController.isDismissed,
                  child: SlideTransition(
                    position: _inspectionSlideAnimation,
                    child: child,
                  ),
                ),
                child: _controller.currentInspection != null
                    ? InspectionScreen(
                        controller: _controller,
                        onClose: _dismissInspector,
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            Positioned.fill(
              child: AnimatedBuilder(
                animation: _networkSlideController,
                builder: (context, child) => IgnorePointer(
                  ignoring: _networkSlideController.isDismissed,
                  child: SlideTransition(
                    position: _networkSlideAnimation,
                    child: child,
                  ),
                ),
                child: _networkScreenOpen
                    ? NetworkScreen(onClose: _toggleNetworkScreen)
                    : const SizedBox.shrink(),
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionMenu() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isOnRightSide = _buttonPosition.dx + 22 > screenWidth / 2;
    return Column(
      crossAxisAlignment: isOnRightSide
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: _menuOpen ? Colors.white24 : Colors.black54,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                _onButtonInteraction();
                setState(() => _menuOpen = !_menuOpen);
              },
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _menuOpen
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuOption(
                          icon: Icons.visibility,
                          label: 'Inspect',
                          color: Colors.greenAccent,
                          trailing: _inspectionEnabled ? 'ON' : null,
                          onTap: () {
                            _toggleInspection();
                            setState(() => _menuOpen = false);
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildMenuOption(
                          icon: Icons.wifi,
                          label: 'Network',
                          color: Colors.blueAccent,
                          onTap: () {
                            if (!_networkScreenOpen) _toggleNetworkScreen();
                            setState(() => _menuOpen = false);
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  trailing,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
