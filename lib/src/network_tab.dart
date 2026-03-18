import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'network_monitor.dart';

class NetworkTab extends StatelessWidget {
  final NetworkMonitor monitor;

  const NetworkTab({super.key, required this.monitor});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        final calls = monitor.calls;

        if (calls.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 48, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No network calls yet',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  'Network calls will appear here automatically',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with clear button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                border: const Border(
                  bottom: BorderSide(color: Colors.white10),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${calls.length} calls',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: monitor.clear,
                    icon: const Icon(Icons.clear_all,
                        size: 14, color: Colors.white70),
                    label: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            // List of network calls
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: calls.length,
                separatorBuilder: (_, index) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final call = calls[index];
                  return NetworkCallItem(call: call);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Single network call item
class NetworkCallItem extends StatefulWidget {
  final NetworkCall call;

  const NetworkCallItem({super.key, required this.call});

  @override
  State<NetworkCallItem> createState() => _NetworkCallItemState();
}

class _NetworkCallItemState extends State<NetworkCallItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Method badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getMethodColor(widget.call.method),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.call.method,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // URL
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.call.displayUrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.call.timestamp
                            .toString()
                            .substring(11, 19), // HH:MM:SS
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.call),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.call.statusDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Duration
                Text(
                  widget.call.durationDisplay,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) _buildExpandedContent(),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full URL
          _buildSection('URL', widget.call.url.toString()),
          const SizedBox(height: 12),

          // Request Headers
          if (widget.call.requestHeaders.isNotEmpty) ...[
            _buildSection(
              'Request Headers',
              widget.call.requestHeaders.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n'),
            ),
            const SizedBox(height: 12),
          ],

          // Request Body
          if (widget.call.requestBody != null) ...[
            _buildSection('Request Body', widget.call.requestBody!),
            const SizedBox(height: 12),
          ],

          // Response Headers
          if (widget.call.responseHeaders != null &&
              widget.call.responseHeaders!.isNotEmpty) ...[
            _buildSection(
              'Response Headers',
              widget.call.responseHeaders!.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n'),
            ),
            const SizedBox(height: 12),
          ],

          // Response Body
          if (widget.call.responseBody != null) ...[
            _buildSection('Response', widget.call.responseBody!),
            const SizedBox(height: 8),
            // Copy response button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copyToClipboard(widget.call.responseBody!),
                icon: const Icon(Icons.copy, size: 14, color: Colors.white70),
                label: const Text(
                  'Copy Response',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],

          // Error
          if (widget.call.error != null) ...[
            _buildSection(
              'Error',
              widget.call.error!,
              color: Colors.redAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color ?? Colors.greenAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue.withValues(alpha: 0.7);
      case 'POST':
        return Colors.green.withValues(alpha: 0.7);
      case 'PUT':
        return Colors.orange.withValues(alpha: 0.7);
      case 'PATCH':
        return Colors.purple.withValues(alpha: 0.7);
      case 'DELETE':
        return Colors.red.withValues(alpha: 0.7);
      default:
        return Colors.grey.withValues(alpha: 0.7);
    }
  }

  Color _getStatusColor(NetworkCall call) {
    if (call.error != null) {
      return Colors.red.withValues(alpha: 0.7);
    }
    if (!call.isCompleted) {
      return Colors.grey.withValues(alpha: 0.7);
    }
    final status = call.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return Colors.green.withValues(alpha: 0.7);
    } else if (status >= 300 && status < 400) {
      return Colors.blue.withValues(alpha: 0.7);
    } else if (status >= 400 && status < 500) {
      return Colors.orange.withValues(alpha: 0.7);
    } else if (status >= 500) {
      return Colors.red.withValues(alpha: 0.7);
    }
    return Colors.grey.withValues(alpha: 0.7);
  }

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response copied to clipboard!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
