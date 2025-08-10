import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

final recentTransfersProvider = StreamProvider.autoDispose<List<Transfer>>((
  ref,
) {
  return ref.watch(databaseProvider).watchRecentTransfers();
});

class RecentTransfersOverlay extends StatefulWidget {
  final bool isPureOverlayMode;

  const RecentTransfersOverlay({super.key, required this.isPureOverlayMode});

  @override
  State<RecentTransfersOverlay> createState() => _RecentTransfersOverlayState();
}

class _RecentTransfersOverlayState extends State<RecentTransfersOverlay> {
  bool _isPanelOpen = false;

  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
    });
  }

  void _setIgnoreMouse(bool ignore) {
    if (widget.isPureOverlayMode) {
      windowManager.setIgnoreMouseEvents(ignore);
    }
  }

  @override
  Widget build(BuildContext context) {
    const panelWidth = 350.0;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          right: _isPanelOpen ? 0 : -panelWidth,
          width: panelWidth,
          child: MouseRegion(
            onEnter: (_) => _setIgnoreMouse(false),
            onExit: (_) => _setIgnoreMouse(true),
            child: const RecentTransfersPanel(),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 20,
          right: _isPanelOpen ? panelWidth + 10 : 10,
          child: MouseRegion(
            onEnter: (_) => _setIgnoreMouse(false),
            onExit: (_) => _setIgnoreMouse(true),
            child: FloatingActionButton(
              mini: true,
              onPressed: _togglePanel,
              child: Icon(_isPanelOpen ? Icons.close : Icons.menu),
            ),
          ),
        ),
      ],
    );
  }
}

class RecentTransfersPanel extends ConsumerWidget {
  const RecentTransfersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTransfersAsync = ref.watch(recentTransfersProvider);
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'העברות אחרונות (7 ימים)',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: recentTransfersAsync.when(
              data: (transfers) {
                if (transfers.isEmpty) {
                  return const Center(child: Text('לא בוצעו העברות לאחרונה.'));
                }
                return ListView.builder(
                  itemCount: transfers.length,
                  itemBuilder: (context, index) {
                    final transfer = transfers[index];
                    final fileName = p.basename(transfer.destinationFile);
                    final d = transfer.timestamp;
                    final dateString =
                        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: Text(
                        fileName,
                        style: const TextStyle(fontSize: 13),
                        textDirection: TextDirection.rtl,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(dateString),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('שגיאה: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
