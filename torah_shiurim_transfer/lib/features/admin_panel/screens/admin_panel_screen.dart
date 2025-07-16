import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פאנל ניהול'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'התנתקות',
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'משתמשים'),
              Tab(icon: Icon(Icons.mic_external_on_outlined), text: 'רבנים'),
              Tab(icon: Icon(Icons.usb_outlined), text: 'התקנים'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersManagementTab(),
            _RabbisManagementTab(),
            _DevicesManagementTab(),
          ],
        ),
      ),
    );
  }
}

// --- Users Management Tab ---
class _UsersManagementTab extends ConsumerWidget {
  const _UsersManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: Icon(user.isAdmin ? Icons.shield_outlined : Icons.person),
            title: Text(user.name),
            subtitle: Text(user.isAdmin ? 'מנהל' : 'משתמש רגיל'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!user.isAdmin)
                  TextButton(
                    child: const Text('הרשאות'),
                    onPressed: () => _showPermissionsDialog(context, ref, user),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref.read(databaseProvider).deleteUser(user.id);
                  },
                ),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  void _showPermissionsDialog(BuildContext context, WidgetRef ref, User user) {
    showDialog(
      context: context,
      builder: (context) => _PermissionsDialog(user: user),
    );
  }
}

class _PermissionsDialog extends ConsumerStatefulWidget {
  final User user;
  const _PermissionsDialog({required this.user});

  @override
  ConsumerState<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends ConsumerState<_PermissionsDialog> {
  late Future<List<int>> _initialPermissionsFuture;
  Set<int> _selectedRabbiIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialPermissionsFuture = ref.read(databaseProvider).getPermissionIdsForUser(widget.user.id);
    _initialPermissionsFuture.then((ids) {
      if (mounted) {
        setState(() {
          _selectedRabbiIds = ids.toSet();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allRabbisAsync = ref.watch(allRabbisProvider);
    return AlertDialog(
      title: Text('עריכת הרשאות עבור ${widget.user.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : allRabbisAsync.when(
                data: (allRabbis) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: allRabbis.length,
                  itemBuilder: (context, index) {
                    final rabbi = allRabbis[index];
                    return CheckboxListTile(
                      title: Text(rabbi.name),
                      value: _selectedRabbiIds.contains(rabbi.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedRabbiIds.add(rabbi.id);
                          } else {
                            _selectedRabbiIds.remove(rabbi.id);
                          }
                        });
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text("Error: $e"),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ביטול')),
        FilledButton(
          onPressed: () async {
            await ref.read(databaseProvider).setPermissionsForUser(widget.user.id, _selectedRabbiIds.toList());
            Navigator.of(context).pop();
          },
          child: const Text('שמירה'),
        ),
      ],
    );
  }
}

// --- Rabbis Management Tab ---
class _RabbisManagementTab extends ConsumerWidget {
  const _RabbisManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rabbisAsync = ref.watch(allRabbisProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showRabbiDialog(context, ref),
      ),
      body: rabbisAsync.when(
        data: (rabbis) => ListView.builder(
          itemCount: rabbis.length,
          itemBuilder: (context, index) {
            final rabbi = rabbis[index];
            return ListTile(
              leading: const Icon(Icons.folder_special_outlined),
              title: Text(rabbi.name),
              subtitle: Text('נתיב: ${rabbi.targetPath}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(databaseProvider).deleteRabbi(rabbi.id);
                },
              ),
              onTap: () => _showRabbiDialog(context, ref, rabbi: rabbi),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showRabbiDialog(BuildContext context, WidgetRef ref, {Rabbi? rabbi}) {
    final nameController = TextEditingController(text: rabbi?.name);
    final pathController = TextEditingController(text: rabbi?.targetPath);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rabbi == null ? 'הוספת רב חדש' : 'עריכת פרטי רב'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'שם הרב'),
                validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
              ),
              TextFormField(
                controller: pathController,
                decoration: InputDecoration(
                  labelText: 'נתיב יעד (במחשב)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                      if (selectedDirectory != null) {
                        pathController.text = selectedDirectory;
                      }
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ביטול')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final companion = drift.RabbisCompanion(
                  name: drift.Value(nameController.text),
                  targetPath: drift.Value(pathController.text),
                );
                if (rabbi == null) {
                  await ref.read(databaseProvider).insertRabbi(companion);
                } else {
                  await ref.read(databaseProvider).updateRabbi(companion.copyWith(id: drift.Value(rabbi.id)));
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('שמירה'),
          ),
        ],
      ),
    );
  }
}

// --- Devices Management Tab ---
class _DevicesManagementTab extends ConsumerWidget {
  const _DevicesManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(allDevicesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showDeviceDialog(context, ref),
      ),
      body: devicesAsync.when(
        data: (devices) => ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final deviceWithUser = devices[index];
            final device = deviceWithUser.device;
            final user = deviceWithUser.user;
            return ListTile(
              leading: const Icon(Icons.memory),
              title: Text('התקן: ${device.serialNumber}'),
              subtitle: Text('משוייך ל: ${user.name}\nנתיב מקור: ${device.sourcePath}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(databaseProvider).deleteDevice(device.id);
                },
              ),
              onTap: () => _showDeviceDialog(context, ref, device: device),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDeviceDialog(BuildContext context, WidgetRef ref, {Device? device}) {
    final serialController = TextEditingController(text: device?.serialNumber);
    final sourcePathController = TextEditingController(text: device?.sourcePath);
    int? selectedUserId = device?.userId;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Use a stateful builder to manage the dropdown state
        return StatefulBuilder(
          builder: (context, setState) {
            final usersAsync = ref.watch(allUsersProvider);

            return AlertDialog(
              title: Text(device == null ? 'הוספת התקן חדש' : 'עריכת התקן'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: serialController,
                      decoration: const InputDecoration(labelText: 'מספר סידורי'),
                      validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                    ),
                    TextFormField(
                      controller: sourcePathController,
                      decoration: const InputDecoration(labelText: 'נתיב מקור (בהתקן)', hintText: 'לדוגמה: voice/'),
                      validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                    ),
                    usersAsync.when(
                      data: (users) => DropdownButtonFormField<int>(
                        value: selectedUserId,
                        hint: const Text('בחר משתמש לשיוך'),
                        items: users
                            .where((u) => !u.isAdmin)
                            .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
                            .toList(),
                        onChanged: (id) => setState(() => selectedUserId = id),
                        validator: (id) => id == null ? 'שדה חובה' : null,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => Text("Error: $e"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ביטול')),
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final companion = drift.DevicesCompanion(
                        serialNumber: drift.Value(serialController.text),
                        sourcePath: drift.Value(sourcePathController.text),
                        userId: drift.Value(selectedUserId!),
                      );
                      if (device == null) {
                        await ref.read(databaseProvider).insertDevice(companion);
                      } else {
                        await ref.read(databaseProvider).updateDevice(companion.copyWith(id: drift.Value(device.id)));
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('שמירה'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}