import 'package:flutter/material.dart';
import 'inspection_data.dart';
import 'widget_inspector.dart';
import 'network_monitor.dart';
import 'network_tab.dart';

/// Full-screen inspection panel displayed when a widget is selected
class InspectionScreen extends StatelessWidget {
  final InspectionController controller;
  final VoidCallback onClose;

  const InspectionScreen({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Material(
        color: const Color(0xFF0D0D0D),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final data = controller.currentInspection!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 22),
            onPressed: onClose,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: controller.canGoBack ? Colors.white : Colors.white24,
              size: 20,
            ),
            onPressed: controller.canGoBack ? controller.goBack : null,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward,
              color: controller.canGoForward ? Colors.white : Colors.white24,
              size: 20,
            ),
            onPressed: controller.canGoForward ? controller.goForward : null,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.widgetType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${data.size.width.toInt()} × ${data.size.height.toInt()}  •  depth ${data.depth}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
            onPressed: () async {
              await ClipboardHelper.copyAllProperties(data);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied all properties!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab('Properties', 0, Icons.info_outline),
            const SizedBox(width: 4),
            _buildTab('Layout', 1, Icons.crop_square),
            const SizedBox(width: 4),
            _buildTab('Styles', 2, Icons.palette_outlined),
            const SizedBox(width: 4),
            _buildTab('Tree', 3, Icons.account_tree_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = controller.selectedTabIndex == index;
    return GestureDetector(
      onTap: () => controller.setSelectedTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.greenAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.greenAccent : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.greenAccent : Colors.white38,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (controller.selectedTabIndex) {
      case 0:
        return PropertiesTab(controller: controller);
      case 1:
        return LayoutTab(controller: controller);
      case 2:
        return StylesTab(controller: controller);
      case 3:
        return HierarchyTab(controller: controller);
      default:
        return PropertiesTab(controller: controller);
    }
  }
}

/// Properties tab - shows all properties with search
class PropertiesTab extends StatelessWidget {
  final InspectionController controller;

  const PropertiesTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final properties = controller.currentInspection!.properties;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: properties.length,
      separatorBuilder: (_, index) =>
          const Divider(color: Colors.white10, height: 8),
      itemBuilder: (context, index) {
        final entry = properties.entries.elementAt(index);
        return PropertyRow(
          propertyKey: entry.key,
          propertyValue: entry.value,
        );
      },
    );
  }
}

/// Layout tab - shows size, position, constraints
class LayoutTab extends StatelessWidget {
  final InspectionController controller;

  const LayoutTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final properties = controller.currentInspection!.properties;
    final layoutProps = properties.entries
        .where((e) =>
            categorizePropertyKey(e.key) == PropertyCategory.layout ||
            categorizePropertyKey(e.key) == PropertyCategory.spacing)
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: layoutProps.length,
      separatorBuilder: (_, index) =>
          const Divider(color: Colors.white10, height: 8),
      itemBuilder: (context, index) {
        final entry = layoutProps[index];
        return PropertyRow(
          propertyKey: entry.key,
          propertyValue: entry.value,
        );
      },
    );
  }
}

/// Styles tab - shows colors, decorations, typography
class StylesTab extends StatelessWidget {
  final InspectionController controller;

  const StylesTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final properties = controller.currentInspection!.properties;
    final styleProps = properties.entries
        .where((e) =>
            categorizePropertyKey(e.key) == PropertyCategory.appearance ||
            categorizePropertyKey(e.key) == PropertyCategory.typography)
        .toList();

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: styleProps.length,
      separatorBuilder: (_, index) =>
          const Divider(color: Colors.white10, height: 8),
      itemBuilder: (context, index) {
        final entry = styleProps[index];
        return PropertyRow(
          propertyKey: entry.key,
          propertyValue: entry.value,
        );
      },
    );
  }
}

/// Hierarchy tab - shows parent and children
class HierarchyTab extends StatelessWidget {
  final InspectionController controller;

  const HierarchyTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final children = controller.getCurrentChildren();
    final ancestors = controller.getCurrentAncestors();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (ancestors.isNotEmpty) ...[
          const Text(
            'Ancestors',
            style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...ancestors.map((ancestor) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${'  ' * ancestor.depth}${ancestor.widgetType}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              )),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            const Text(
              'Current Widget',
              style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (controller.currentInspection?.element != null)
              TextButton.icon(
                onPressed: controller.navigateToParent,
                icon: const Icon(Icons.arrow_upward,
                    size: 14, color: Colors.white70),
                label: const Text('Parent',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          controller.currentInspection!.widgetType,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (children.isNotEmpty) ...[
          const Text(
            'Children',
            style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...children.map((child) => InkWell(
                onTap: () =>
                    child.element != null
                        ? controller.navigateToChild(child.element!)
                        : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.widgets,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          child.widgetType,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 14, color: Colors.white38),
                    ],
                  ),
                ),
              )),
        ] else
          const Text(
            'No children',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
      ],
    );
  }
}

/// Standalone full-screen network monitor — no widget selection needed
class NetworkScreen extends StatelessWidget {
  final VoidCallback onClose;

  const NetworkScreen({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Material(
        color: const Color(0xFF0D0D0D),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: NetworkTab(monitor: NetworkMonitor.instance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 22),
            onPressed: onClose,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Network Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: NetworkMonitor.instance,
            builder: (context, _) {
              final count = NetworkMonitor.instance.calls.length;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count calls',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Single property row widget
class PropertyRow extends StatelessWidget {
  final String propertyKey;
  final String propertyValue;

  const PropertyRow({
    super.key,
    required this.propertyKey,
    required this.propertyValue,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () async {
        await ClipboardHelper.copyProperty(propertyKey, propertyValue);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied: $propertyKey'),
              duration: const Duration(milliseconds: 800),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                propertyKey,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ),
            Expanded(
              child: Text(
                propertyValue,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
