import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

class DeviceManagementTab extends ConsumerWidget {
  const DeviceManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(allDevicesProvider);
    final logService = ref.read(logServiceProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף התקן'),
        onPressed: () {
          logService.logUserActivity('Admin opened "Add Device" dialog.');
          _showDeviceDialog(context, ref);
        },
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
                      context, 'התקן', device.serialNumber, () async {
                    try {
                      await ref.read(databaseProvider).deleteDevice(device.id);
                      logService.logUserActivity(
                          'Admin deleted device: ${device.serialNumber} (ID: ${device.id})');
                    } catch (e, st) {
                      logService.logError(
                          'Failed to delete device: ${device.serialNumber}',
                          e,
                          st);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('שגיאה במחיקת התקן: $e')));
                      }
                    }
                  }),
                ),
                onTap: () {
                  logService.logUserActivity(
                      'Admin opened "Edit Device" dialog for device: ${device.serialNumber}');
                  _showDeviceDialog(context, ref, device: device);
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logService.logError('Error loading devices data', e, st);
          return Center(child: Text('Error: $e'));
        },
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
  late final LogService _logService;

  @override
  void initState() {
    super.initState();
    _logService = ref.read(logServiceProvider);
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
    _logService.logInfo(
        'Attempting to find current mount path for device serial: ${widget.device!.serialNumber}');
    try {
      final devices = await ref.read(connectedDevicesProvider.future);
      final connectedDevice = devices.firstWhere(
        (d) => d.serialNumber == widget.device!.serialNumber,
      );
      if (mounted) {
        setState(() {
          _mountPath = connectedDevice.mountPath;
        });
        _logService.logInfo(
            'Found mount path for ${widget.device!.serialNumber}: $_mountPath');
      }
    } catch (e) {
      _logService.logInfo(
          'Mount path not found for device ${widget.device!.serialNumber}: $e');
    }
  }

  String _generateRandomSerial() {
    final random = Random();
    const chars = 'ABCDEF0123456789';
    final part1 = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    final part2 = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    final generatedSerial = '$part1-$part2';
    _logService.logInfo('Generated random serial number: $generatedSerial');
    return generatedSerial;
  }

  Future<void> _locateDevice() async {
    setState(() => _isLoading = true);
    _logService.logUserActivity('Admin initiated device location process.');
    try {
      final selectedPath = await FilePicker.platform.getDirectoryPath(
        lockParentWindow: true,
        dialogTitle: 'בחר תיקיית מקור מההתקן החיצוני',
      );
      if (selectedPath == null) {
        _logService.logInfo('Device location cancelled by user.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      _logService.logInfo('User selected path: $selectedPath');

      final devices = await ref.read(connectedDevicesProvider.future);
      if (!mounted) return;

      if (devices.isEmpty) {
        _logService
            .logWarning('No external drives found during device location.');
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
          _logService.logWarning(
              'Selected path ($selectedPath) is not on a recognized external drive.');
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
        _logService.logInfo(
            'Device located successfully. MountPath: $_mountPath, Serial: ${_serialController.text}, SourcePath: ${_sourcePathController.text}');
      }
    } catch (e, st) {
      _logService.logError('Error during device location process.', e, st);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeDeviceSerial() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _logService.logWarning(
          'Attempted to change device serial with invalid form data.');
      return;
    }

    setState(() => _isChangingSerial = true);
    _logService.logUserActivity(
        'Admin attempting to change serial for device at $_mountPath to ${_serialController.text}.');
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
        _logService.logUserActivity(
            'Successfully changed serial number for device: $_mountPath to ${_serialController.text}. Message: $resultMessage');
      }
    } catch (e, st) {
      _logService.logError(
          'Failed to change serial number for device at $_mountPath to ${_serialController.text}.',
          e,
          st);
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
      if (_mountPath == null) {
        _logService.logWarning(
            'Attempted to save device without a mount path. Please locate the device first.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('יש לאתר את ההתקן לפני השמירה.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final serialNumber = _serialController.text;
      final companion = DevicesCompanion(
        serialNumber: drift.Value(serialNumber),
        sourcePath: drift.Value(_sourcePathController.text),
        userId: drift.Value(_selectedUserId!),
      );

      try {
        if (widget.device == null) {
          final newDeviceId =
              await ref.read(databaseProvider).insertDevice(companion);
          _logService.logUserActivity(
              'Admin added new device: $serialNumber (ID: $newDeviceId), assigned to user ID: $_selectedUserId, SourcePath: ${_sourcePathController.text}');
        } else {
          await ref.read(databaseProvider).updateDevice(
              companion.copyWith(id: drift.Value(widget.device!.id)));
          _logService.logUserActivity(
              'Admin updated device: ${widget.device!.serialNumber} (ID: ${widget.device!.id}) to $serialNumber, assigned to user ID: $_selectedUserId, SourcePath: ${_sourcePathController.text}');
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, st) {
        _logService.logError('Failed to save device: $serialNumber', e, st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה בשמירה: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      _logService
          .logWarning('Attempted to save device with invalid form data.');
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
                        _logService.logInfo(
                            'Admin toggled serial number editing for device dialog. Now: $_isEditingSerial');
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
                      .map((u) =>
                          DropdownMenuItem(value: u.id, child: Text(u.name)))
                      .toList(),
                  onChanged: (id) {
                    setState(() => _selectedUserId = id);
                    final selectedUser = users.firstWhere((u) => u.id == id);
                    _logService.logInfo(
                        'Admin selected user ${selectedUser.name} (ID: $id) for device association.');
                  },
                  validator: (id) => id == null ? 'שדה חובה' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, st) {
                  _logService.logError(
                      'Error loading users for device dialog', e, st);
                  return Text("Error: $e");
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              _logService.logUserActivity('Admin cancelled device dialog.');
              Navigator.of(context).pop();
            },
            child: const Text('ביטול')),
        FilledButton(
          onPressed: _saveDevice,
          child: const Text('שמירה'),
        ),
      ],
    );
  }
}