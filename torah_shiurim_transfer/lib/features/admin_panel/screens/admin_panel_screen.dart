import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
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
              Tab(icon: Icon(Icons.settings_outlined), text: 'הגדרות'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _UsersManagementTab(),
            _RabbisManagementTab(),
            _DevicesManagementTab(),
            _SettingsManagementTab(),
          ],
        ),
      ),
    );
  }
}

void _showDeleteConfirmation(BuildContext context, String itemType,
    String itemName, VoidCallback onDelete) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('אישור מחיקה'),
      content:
          Text('האם למחוק את ה$itemType "$itemName"?\nפעולה זו אינה הפיכה.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
          onPressed: () {
            onDelete();
            Navigator.of(context).pop();
          },
          child: const Text('מחק'),
        ),
      ],
    ),
  );
}

class _UsersManagementTab extends ConsumerWidget {
  const _UsersManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף משתמש'),
        onPressed: () => _showUserDialog(context, ref),
      ),
      body: usersAsync.when(
        data: (users) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            // בניית מחרוזת ה-subtitle
            String subtitleText = user.isAdmin ? 'מנהל' : 'משתמש רגיל';
            if (user.additionalInfo != null &&
                user.additionalInfo!.isNotEmpty) {
              subtitleText += '\nפרטים נוספים: ${user.additionalInfo}';
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading:
                    Icon(user.isAdmin ? Icons.shield_outlined : Icons.person),
                title: Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitleText),
                isThreeLine: user.additionalInfo != null &&
                    user.additionalInfo!.isNotEmpty, // חדש: מאפשר 3 שורות
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!user.isAdmin)
                      TextButton(
                        child: const Text('הרשאות'),
                        onPressed: () =>
                            _showPermissionsDialog(context, ref, user),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: 'מחק משתמש',
                      onPressed: () => _showDeleteConfirmation(
                          context, 'משתמש', user.name, () {
                        ref.read(databaseProvider).deleteUser(user.id);
                      }),
                    ),
                  ],
                ),
                onTap: () => _showUserDialog(context, ref, user: user),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context, WidgetRef ref, User user) {
    showDialog(
      context: context,
      builder: (context) => _PermissionsDialog(user: user),
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, {User? user}) {
    final nameController = TextEditingController(text: user?.name);
    bool isAdmin = user?.isAdmin ?? false;
    // בקר עבור מידע נוסף
    final additionalInfoController =
        TextEditingController(text: user?.additionalInfo);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(user == null ? 'הוספת משתמש חדש' : 'עריכת משתמש'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                          labelText: 'שם משתמש', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 16),
                    // שינוי: שדה למידע נוסף עם גובה התחלתי של 3 שורות
                    TextFormField(
                      controller: additionalInfoController,
                      decoration: const InputDecoration(
                          labelText: 'פרטים נוספים (טלפון, שיעור, ועד וכו\')',
                          border: OutlineInputBorder()),
                      textAlign: TextAlign.start,
                      minLines: 3, // שונה ל-3 - הגובה ההתחלתי
                      maxLines:
                          5, // ניתן להרחיב עד 5 שורות, או null לגובה בלתי מוגבל
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('האם מנהל?'),
                      value: isAdmin,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            isAdmin = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ביטול'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final companion = UsersCompanion(
                        name: drift.Value(nameController.text),
                        isAdmin: drift.Value(isAdmin),
                        // שמירת המידע הנוסף
                        additionalInfo: drift.Value(
                            additionalInfoController.text.trim().isEmpty
                                ? null
                                : additionalInfoController.text.trim()),
                      );
                      if (user == null) {
                        await ref.read(databaseProvider).insertUser(companion);
                      } else {
                        await ref.read(databaseProvider).updateUser(
                              companion.copyWith(id: drift.Value(user.id)),
                            );
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

class _PermissionsDialog extends ConsumerStatefulWidget {
  final User user;
  const _PermissionsDialog({required this.user});

  @override
  ConsumerState<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends ConsumerState<_PermissionsDialog> {
  Set<int> _selectedRabbiIds = {};
  Map<int, TextEditingController> _pathControllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialPermissions();
  }

  @override
  void dispose() {
    for (var controller in _pathControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialPermissions() async {
    // נשתמש ב-getPermissionsForUser כדי לקבל את הנתיבים הספציפיים הקיימים
    final initialPermissions =
        await ref.read(databaseProvider).getPermissionsForUser(widget.user.id);
    if (mounted) {
      final newSelectedIds = <int>{};
      final newControllers = <int, TextEditingController>{};
      for (final p in initialPermissions) {
        newSelectedIds.add(p.rabbiId);
        // ודא שהבקר נוצר רק אם יש נתיב ספציפי או אם הוספת אותו לרשימת הנבחרים
        newControllers[p.rabbiId] = TextEditingController(text: p.specificPath);
      }
      setState(() {
        _selectedRabbiIds = newSelectedIds;
        _pathControllers = newControllers;
        _isLoading = false;
      });
    }
  }

  // פונקציה לבחירת תיקיה באמצעות דיאלוג מערכת
  Future<void> _pickSpecificPath(Rabbi rabbi) async {
    // נקודת התחלה לדיאלוג - תיקיית היעד הראשית של הרב
    final initialDirectory = rabbi.targetPath;

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      initialDirectory: initialDirectory,
      lockParentWindow: true,
      dialogTitle: 'בחר תיקיית יעד ספציפית עבור ${rabbi.name}',
    );

    if (selectedDirectory != null) {
      // ודא שהנתיב הנבחר נמצא בתוך תיקיית היעד הראשית של הרב
      if (!selectedDirectory.startsWith(initialDirectory)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('יש לבחור תיקיה בתוך תיקיית הרב המוגדרת.')),
          );
        }
        return;
      }

      // חישוב הנתיב היחסי
      String relativePath =
          selectedDirectory.substring(initialDirectory.length);

      // הסרת סלאשים מובילים/סופיים מיותרים והחלפת \ ב /
      relativePath = relativePath.replaceAll(r'\', '/');
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }
      if (relativePath.endsWith('/')) {
        relativePath = relativePath.substring(0, relativePath.length - 1);
      }

      if (mounted) {
        // עדכון הבקר של שדה הטקסט עם הנתיב היחסי
        _pathControllers[rabbi.id]?.text = relativePath;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRabbis = ref.watch(allRabbisProvider);
    return AlertDialog(
      title: Text('עריכת הרשאות עבור ${widget.user.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : allRabbis.when(
                data: (rabbis) => ListView(
                  shrinkWrap: true,
                  children: rabbis.map<Widget>((rabbi) {
                    final isSelected = _selectedRabbiIds.contains(rabbi.id);
                    // יצירת בקר אם עדיין לא קיים (למקרה של הוספה חדשה)
                    _pathControllers.putIfAbsent(
                        rabbi.id, () => TextEditingController());
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          value: isSelected,
                          title: Text(rabbi.name),
                          subtitle: Text('נתיב בסיס: ${rabbi.targetPath}',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedRabbiIds.add(rabbi.id);
                                // בקר כבר קיים או נוצר הרגע באמצעות putIfAbsent
                              } else {
                                _selectedRabbiIds.remove(rabbi.id);
                                _pathControllers.remove(rabbi.id)?.dispose();
                              }
                            });
                          },
                        ),
                        if (isSelected)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                            child: TextFormField(
                              controller: _pathControllers[rabbi.id],
                              decoration: InputDecoration(
                                labelText: 'הגבלת תיקיה (אופציונלי)',
                                hintText: 'לדוגמה: תשפ״ד/שיעורים',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.folder_open),
                                  onPressed: () => _pickSpecificPath(rabbi),
                                  tooltip: 'בחר תיקיה מתוך תיקיית הרב',
                                ),
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('שגיאה בטעינת רבנים: $e')),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final permissionsToSet = <int, String?>{};
                  for (final rabbiId in _selectedRabbiIds) {
                    final path = _pathControllers[rabbiId]?.text.trim();
                    // שמירה כ-null אם ריק
                    permissionsToSet[rabbiId] =
                        (path != null && path.isNotEmpty) ? path : null;
                  }
                  await ref.read(databaseProvider).setPermissionsForUser(
                        widget.user.id,
                        permissionsToSet,
                      );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
          child: const Text('שמור'),
        ),
      ],
    );
  }
}

class _RabbisManagementTab extends ConsumerWidget {
  const _RabbisManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rabbisAsync = ref.watch(allRabbisProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף רב'),
        onPressed: () => _showRabbiDialog(context, ref),
      ),
      body: rabbisAsync.when(
        data: (rabbis) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: rabbis.length,
          itemBuilder: (context, index) {
            final rabbi = rabbis[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.folder_special_outlined),
                title: Text(rabbi.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('נתיב: ${rabbi.targetPath}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'מחק רב',
                  onPressed: () =>
                      _showDeleteConfirmation(context, 'רב', rabbi.name, () {
                    ref.read(databaseProvider).deleteRabbi(rabbi.id);
                  }),
                ),
                onTap: () => _showRabbiDialog(context, ref, rabbi: rabbi),
              ),
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
                decoration: const InputDecoration(
                    labelText: 'שם הרב', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pathController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'נתיב יעד (במחשב)',
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () async {
                      String? selectedDirectory =
                          await FilePicker.platform.getDirectoryPath();
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
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final companion = RabbisCompanion(
                  name: drift.Value(nameController.text),
                  targetPath: drift.Value(pathController.text),
                );
                if (rabbi == null) {
                  await ref.read(databaseProvider).insertRabbi(companion);
                } else {
                  await ref.read(databaseProvider).updateRabbi(
                      companion.copyWith(id: drift.Value(rabbi.id)));
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

class _DevicesManagementTab extends ConsumerWidget {
  const _DevicesManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(allDevicesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף התקן'),
        onPressed: () => _showDeviceDialog(context, ref),
      ),
      body: devicesAsync.when(
        data: (devices) => ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final deviceWithUser = devices[index];
            final device = deviceWithUser.device;
            final user = deviceWithUser.user;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.memory),
                title: Text('מספר סידורי: ${device.serialNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'משוייך ל: ${user.name}\nנתיב מקור: ${device.sourcePath.isEmpty ? 'שורש הכונן' : device.sourcePath}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'מחק התקן',
                  onPressed: () => _showDeleteConfirmation(
                      context, 'התקן', device.serialNumber, () {
                    ref.read(databaseProvider).deleteDevice(device.id);
                  }),
                ),
                onTap: () => _showDeviceDialog(context, ref, device: device),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDeviceDialog(BuildContext context, WidgetRef ref,
      {Device? device}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeviceDialog(device: device),
    );
  }
}

class _DeviceDialog extends ConsumerStatefulWidget {
  final Device? device;
  const _DeviceDialog({this.device});

  @override
  ConsumerState<_DeviceDialog> createState() => __DeviceDialogState();
}

class __DeviceDialogState extends ConsumerState<_DeviceDialog> {
  late TextEditingController _serialController;
  late TextEditingController _sourcePathController;
  int? _selectedUserId;
  final _formKey = GlobalKey<FormState>();

  String? _mountPath;
  bool _isLoading = false;
  bool _isChangingSerial = false;
  bool _isEditingSerial = false;

  @override
  void initState() {
    super.initState();
    _serialController =
        TextEditingController(text: widget.device?.serialNumber);
    _sourcePathController =
        TextEditingController(text: widget.device?.sourcePath);
    _selectedUserId = widget.device?.userId;
    _isEditingSerial = widget.device == null;

    if (widget.device != null) {
      _findCurrentMountPath();
    }
  }

  @override
  void dispose() {
    _serialController.dispose();
    _sourcePathController.dispose();
    super.dispose();
  }

  Future<void> _findCurrentMountPath() async {
    if (widget.device == null) return;
    try {
      final devices = await ref.read(connectedDevicesProvider.future);
      final connectedDevice = devices.firstWhere(
        (d) => d.serialNumber == widget.device!.serialNumber,
      );
      if (mounted) {
        setState(() {
          _mountPath = connectedDevice.mountPath;
        });
      }
    } catch (e) {
      // ייתכן וההתקן נותק או לא זוהה
    }
  }

  String _generateRandomSerial() {
    final random = Random();
    const chars = 'ABCDEF0123456789';
    final part1 = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    final part2 = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    return '$part1-$part2';
  }

  Future<void> _locateDevice() async {
    setState(() => _isLoading = true);
    try {
      final selectedPath = await FilePicker.platform.getDirectoryPath(
        lockParentWindow: true,
        dialogTitle: 'בחר תיקיית מקור מההתקן החיצוני',
      );
      if (selectedPath == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final devices = await ref.read(connectedDevicesProvider.future);
      if (!mounted) return;

      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("לא נמצאו כוננים חיצוניים.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      ConnectedDeviceInfo? drive;
      try {
        drive = devices.firstWhere((d) => selectedPath.startsWith(d.mountPath));
      } catch (e) {
        drive = null;
      }

      if (drive == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("התיקיה שנבחרה אינה נמצאת על כונן חיצוני מזוהה.")),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      String relativePath =
          selectedPath.substring(drive.mountPath.length).trim();
      if (relativePath.startsWith(r'\') || relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }

      if (mounted) {
        setState(() {
          _mountPath = drive!.mountPath;
          _serialController.text = drive.serialNumber;
          _sourcePathController.text = relativePath;
          _isLoading = false;
          _isEditingSerial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeDeviceSerial() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isChangingSerial = true);
    try {
      final resultMessage = await ref
          .read(deviceServiceProvider)
          .changeVolumeSerialNumber(_mountPath!, _serialController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('הפעולה הצליחה: $resultMessage'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingSerial = false);
      }
    }
  }

  Future<void> _saveDevice() async {
    if (_formKey.currentState!.validate()) {
      final serialNumber = _serialController.text;
      final companion = DevicesCompanion(
        serialNumber: drift.Value(serialNumber),
        sourcePath: drift.Value(_sourcePathController.text),
        userId: drift.Value(_selectedUserId!),
      );

      try {
        if (widget.device == null) {
          await ref.read(databaseProvider).insertDevice(companion);
        } else {
          await ref.read(databaseProvider).updateDevice(
              companion.copyWith(id: drift.Value(widget.device!.id)));
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה בשמירה: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return AlertDialog(
      title: Text(widget.device == null ? 'הוספת התקן חדש' : 'עריכת התקן'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.drive_folder_upload_outlined),
                label: Text(
                    _isLoading ? "נא המתן..." : "אתר התקן ובחר תיקיית מקור"),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                onPressed: _isLoading ? null : _locateDevice,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serialController,
                readOnly: !_isEditingSerial,
                decoration: InputDecoration(
                  labelText: 'מספר סידורי',
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(
                    icon: Icon(_isEditingSerial ? Icons.lock_open : Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingSerial = !_isEditingSerial;
                      });
                    },
                    tooltip:
                        _isEditingSerial ? 'נעל עריכה' : 'אפשר עריכה ידנית',
                  ),
                  suffixIcon: _isEditingSerial
                      ? IconButton(
                          icon: const Icon(Icons.casino_outlined),
                          tooltip: 'צור מספר אקראי',
                          onPressed: () {
                            _serialController.text = _generateRandomSerial();
                          },
                        )
                      : null,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'שדה חובה';
                  final sanitized = v.replaceAll('-', '');
                  if (!RegExp(r'^[0-9A-Fa-f]{8}$', caseSensitive: false)
                      .hasMatch(sanitized)) {
                    return 'פורמט לא תקין (8 תווים הקסדצימליים)';
                  }
                  return null;
                },
              ),
              if (Platform.isWindows && _mountPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OutlinedButton.icon(
                    icon: _isChangingSerial
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_alt),
                    label: const Text("שנה מספר סריאלי בהתקן"),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        foregroundColor: Theme.of(context).colorScheme.primary),
                    onPressed: _isChangingSerial ? null : _changeDeviceSerial,
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourcePathController,
                decoration: const InputDecoration(
                  labelText: 'נתיב מקור (יחסית לכונן)',
                  hintText: 'לדוגמה: records (או ריק לשורש)',
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
              usersAsync.when(
                data: (users) => DropdownButtonFormField<int>(
                  value: _selectedUserId,
                  hint: const Text('בחר משתמש לשיוך'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'משתמש משוייך',
                  ),
                  items: users
                      .where((u) => !u.isAdmin)
                      .map((u) =>
                          DropdownMenuItem(value: u.id, child: Text(u.name)))
                      .toList(),
                  onChanged: (id) => setState(() => _selectedUserId = id),
                  validator: (id) => id == null ? 'שדה חובה' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, st) => Text("Error: $e"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול')),
        FilledButton(
          onPressed: _saveDevice,
          child: const Text('שמירה'),
        ),
      ],
    );
  }
}

class _SettingsManagementTab extends ConsumerWidget {
  const _SettingsManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'הגדרות המרה ל-MP3',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        title: const Text('המר קבצים ל-MP3 בעת ההעתקה'),
                        subtitle: const Text(
                            'הפעלה תגרום להמרת כל קובץ שמע לפורמט MP3. דורש התקנת ffmpeg.'),
                        value: settings.convertToMp3,
                        onChanged: (value) {
                          ref.read(databaseProvider).updateAppSettings(
                                AppSettingsCompanion(
                                    convertToMp3: drift.Value(value)),
                              );
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: settings.convertToMp3 ? 1.0 : 0.4,
                        child: IgnorePointer(
                          ignoring: !settings.convertToMp3,
                          child: DropdownButtonFormField<int>(
                            value: settings.mp3Bitrate,
                            decoration: const InputDecoration(
                              labelText: 'איכות (Bitrate)',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 64, child: Text('נמוכה (64kbps)')),
                              DropdownMenuItem(
                                  value: 128, child: Text('בינונית (128kbps)')),
                              DropdownMenuItem(
                                  value: 192, child: Text('גבוהה (192kbps)')),
                              DropdownMenuItem(
                                  value: 256,
                                  child: Text('גבוהה מאוד (256kbps)')),
                              DropdownMenuItem(
                                  value: 320, child: Text('מעולה (320kbps)')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(databaseProvider).updateAppSettings(
                                      AppSettingsCompanion(
                                          mp3Bitrate: drift.Value(value)),
                                    );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }
}
