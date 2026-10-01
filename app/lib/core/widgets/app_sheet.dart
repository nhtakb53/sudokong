import 'package:flutter/material.dart';

/// One row of an [showAppSheet] menu.
class AppSheetItem {
  const AppSheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.enabled = true,
    this.destructive = false,
  });

  final IconData icon;
  final String label;

  /// Small text under the label, such as a count.
  final String? detail;
  final bool enabled;

  /// Draws the row in the error color: it removes something.
  final bool destructive;
  final VoidCallback onTap;
}

/// The app's menu: a bottom sheet in the same rounded-card language as the
/// toolbar and keypad, with big rows instead of a dropdown. Tapping a row
/// closes the sheet and runs it.
Future<void> showAppSheet(
  BuildContext context, {
  required String title,
  required List<AppSheetItem> items,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _AppSheet(title: title, items: items),
  );
}

class _AppSheet extends StatelessWidget {
  const _AppSheet({required this.title, required this.items});

  final String title;
  final List<AppSheetItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final item in items) _Row(item: item),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final AppSheetItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = item.destructive ? scheme.error : scheme.onSurface;
    return Opacity(
      opacity: item.enabled ? 1 : 0.38,
      child: InkWell(
        onTap: item.enabled
            ? () {
                Navigator.of(context).pop();
                item.onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 22, color: tint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tint,
                      ),
                    ),
                    if (item.detail != null)
                      Text(
                        item.detail!,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
