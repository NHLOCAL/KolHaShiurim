import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/models/app_user.dart';
import 'package:kol_hashiurim/features/user_panel/providers/user_panel_providers.dart';
import 'package:kol_hashiurim/features/user_panel/widgets/file_selection_panel.dart';
import 'package:kol_hashiurim/features/user_panel/widgets/transfer_details_panel.dart';

class UserTransferScreen extends ConsumerStatefulWidget {
  const UserTransferScreen({super.key});

  @override
  ConsumerState<UserTransferScreen> createState() => _UserTransferScreenState();
}

class _UserTransferScreenState extends ConsumerState<UserTransferScreen> {
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _handleAuthState(ref.read(authStateProvider));
    ref.listen<AppUserState>(
      authStateProvider,
      (_, next) => _handleAuthState(next),
    );

    ref.read(sourceFilesProvider).whenData(_handleSourceFiles);
    ref.listen<AsyncValue<List<File>>>(
      sourceFilesProvider,
      (_, next) => next.whenData(_handleSourceFiles),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleAuthState(AppUserState state) {
    state.maybeWhen(
      user: (user, device, mountPath) {
        if (mounted && _selectedFile != null) {
          setState(() => _selectedFile = null);
        }
      },
      orElse: () {
        if (mounted && _selectedFile != null) {
          setState(() => _selectedFile = null);
        }
      },
    );
  }

  void _handleSourceFiles(List<File> files) {
    final current = _selectedFile;
    if (current != null &&
        !files.any((file) => file.path == current.path) &&
        mounted) {
      setState(() => _selectedFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final logService = ref.read(logServiceProvider);

    final userName = authState.maybeMap(
      user: (u) => u.user.name,
      orElse: () => '',
    );
    final deviceSerial = authState.maybeMap(
      user: (u) => u.device.serialNumber,
      orElse: () => '',
    );
    final theme = Theme.of(context);

    logService.logInfo(
      'User Transfer screen built for user: $userName, device: $deviceSerial',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('העברת שיעורים - שלום, $userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'התנתקות וסגירת הממשק',
            onPressed: () {
              logService.logUserActivity(
                'User $userName clicked logout button.',
              );
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            'התקן מחובר: $deviceSerial',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: FileSelectionPanel(
              selectedFile: _selectedFile,
              onFileSelected: (file) {
                setState(() {
                  _selectedFile = file;
                });
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: TransferDetailsPanel(
              selectedFile: _selectedFile,
              onCopyComplete: () {
                setState(() {
                  _selectedFile = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
