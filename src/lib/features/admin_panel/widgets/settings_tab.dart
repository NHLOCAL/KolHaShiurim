import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});
  Future<void> _backupSettings(BuildContext context, WidgetRef ref) async {
    final logService = ref.read(logServiceProvider);
    logService.logUserActivity('Admin initiated settings backup.');
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(databaseProvider);
      final users = await db.select(db.users).get();
      final devices = await db.select(db.devices).get();
      final rabbis = await db.select(db.rabbis).get();
      final permissions = await db.select(db.userRabbiPermissions).get();
      final settings = await db.getAppSettings();
      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'users': users.map((u) => u.toJson()).toList(),
        'devices': devices.map((d) => d.toJson()).toList(),
        'rabbis': rabbis.map((r) => r.toJson()).toList(),
        'userRabbiPermissions': permissions.map((p) => p.toJson()).toList(),
        'appSettings': settings.toJson(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final fileName =
          'torah_shiurim_backup_${DateTime.now().toIso8601String().split('T').first}.json';
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'שמור קובץ גיבוי',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        logService.logInfo('Settings backup saved to: $result');
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('הגיבוי נשמר בהצלחה: $result'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        logService.logInfo(
          'Settings backup was cancelled or no file selected.',
        );
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('גיבוי בוטל או לא נבחר קובץ.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, st) {
      logService.logError('Failed to backup settings', e, st);
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת הגיבוי: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreSettings(BuildContext context, WidgetRef ref) async {
    final logService = ref.read(logServiceProvider);
    logService.logUserActivity('Admin initiated settings restore.');
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('אזהרה: שחזור הגדרות'),
        content: const Text(
          'פעולה זו תמחק את כל המשתמשים, ההתקנים, הרבנים וההרשאות הנוכחיים ותחליף אותם בנתונים מקובץ הגיבוי.\n\nהאם אתה בטוח שברצונך להמשיך?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('אני מאשר, המשך'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      logService.logInfo(
        'Settings restore was cancelled by user at confirmation dialog.',
      );
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) {
        logService.logInfo('Settings restore file picker was cancelled.');
        return;
      }
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString);
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        logService.logInfo("Starting database restore transaction.");
        await db.delete(db.userRabbiPermissions).go();
        await db.delete(db.devices).go();
        await db.delete(db.rabbis).go();
        await db.delete(db.users).go();
        logService.logInfo(
          "Cleared all users, devices, rabbis, and permissions.",
        );
        final settingsMap = backupData['appSettings'] as Map<String, dynamic>;
        await db.updateAppSettings(
          AppSettingsCompanion(
            convertToMp3: drift.Value(settingsMap['convertToMp3']),
            mp3Bitrate: drift.Value(settingsMap['mp3Bitrate']),
          ),
        );
        logService.logInfo("Restored app settings.");
        final oldNewRabbiIdMap = <int, int>{};
        final rabbisList = backupData['rabbis'] as List;
        for (final rabbiMap in rabbisList) {
          final oldId = rabbiMap['id'] as int;
          final newId = await db
              .into(db.rabbis)
              .insert(
                RabbisCompanion.insert(
                  name: rabbiMap['name'],
                  targetPath: rabbiMap['targetPath'],
                ),
              );
          oldNewRabbiIdMap[oldId] = newId;
        }
        logService.logInfo("Restored ${rabbisList.length} rabbis.");
        final oldNewUserIdMap = <int, int>{};
        final usersList = backupData['users'] as List;
        for (final userMap in usersList) {
          final oldId = userMap['id'] as int;
          final newId = await db
              .into(db.users)
              .insert(
                UsersCompanion.insert(
                  name: userMap['name'],
                  additionalInfo: drift.Value(userMap['additionalInfo']),
                ),
              );
          oldNewUserIdMap[oldId] = newId;
        }
        logService.logInfo("Restored ${oldNewUserIdMap.length} users.");
        final devicesList = backupData['devices'] as List;
        for (final deviceMap in devicesList) {
          final oldUserId = deviceMap['userId'] as int;
          final newUserId = oldNewUserIdMap[oldUserId];
          if (newUserId != null) {
            await db
                .into(db.devices)
                .insert(
                  DevicesCompanion.insert(
                    userId: newUserId,
                    serialNumber: deviceMap['serialNumber'] ?? '',
                    sourcePath: deviceMap['sourcePath'] ?? '',
                  ),
                );
          }
        }
        logService.logInfo("Restored devices.");
        final permissionsList = backupData['userRabbiPermissions'] as List;
        for (final permMap in permissionsList) {
          final oldUserId = permMap['userId'] as int;
          final oldRabbiId = permMap['rabbiId'] as int;
          final newUserId = oldNewUserIdMap[oldUserId];
          final newRabbiId = oldNewRabbiIdMap[oldRabbiId];
          if (newUserId != null && newRabbiId != null) {
            await db
                .into(db.userRabbiPermissions)
                .insert(
                  UserRabbiPermissionsCompanion.insert(
                    userId: newUserId,
                    rabbiId: newRabbiId,
                    specificPath: drift.Value(permMap['specificPath']),
                  ),
                );
          }
        }
        logService.logInfo("Restored permissions.");
      });
      logService.logUserActivity(
        'Settings successfully restored from ${file.path}.',
      );
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('ההגדרות שוחזרו בהצלחה. הנתונים מתרעננים.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, st) {
      logService.logError('Failed to restore settings', e, st);
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('שגיאה בשחזור ההגדרות: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final logService = ref.read(logServiceProvider);
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
                          'הפעלה תגרום להמרת כל קובץ שמע לפורמט MP3. דורש התקנת ffmpeg.',
                        ),
                        value: settings.convertToMp3,
                        onChanged: (value) async {
                          try {
                            await ref
                                .read(databaseProvider)
                                .updateAppSettings(
                                  AppSettingsCompanion(
                                    convertToMp3: drift.Value(value),
                                  ),
                                );
                            logService.logUserActivity(
                              'Admin changed "Convert to MP3" setting to: $value.',
                            );
                          } catch (e, st) {
                            logService.logError(
                              'Failed to update "Convert to MP3" setting',
                              e,
                              st,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('שגיאה בעדכון הגדרה: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: settings.convertToMp3 ? 1.0 : 0.4,
                        child: IgnorePointer(
                          ignoring: !settings.convertToMp3,
                          child: DropdownButtonFormField<int>(
                            initialValue: settings.mp3Bitrate,
                            decoration: const InputDecoration(
                              labelText: 'איכות (Bitrate)',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 32,
                                child: Text('נמוכה מאוד (32kbps)'),
                              ),
                              DropdownMenuItem(
                                value: 64,
                                child: Text('נמוכה (64kbps)'),
                              ),
                              DropdownMenuItem(
                                value: 128,
                                child: Text('בינונית (128kbps)'),
                              ),
                              DropdownMenuItem(
                                value: 192,
                                child: Text('גבוהה (192kbps)'),
                              ),
                              DropdownMenuItem(
                                value: 256,
                                child: Text('גבוהה מאוד (256kbps)'),
                              ),
                              DropdownMenuItem(
                                value: 320,
                                child: Text('מעולה (320kbps)'),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value != null) {
                                try {
                                  await ref
                                      .read(databaseProvider)
                                      .updateAppSettings(
                                        AppSettingsCompanion(
                                          mp3Bitrate: drift.Value(value),
                                        ),
                                      );
                                  logService.logUserActivity(
                                    'Admin changed MP3 bitrate setting to: ${value}kbps.',
                                  );
                                } catch (e, st) {
                                  logService.logError(
                                    'Failed to update MP3 bitrate setting',
                                    e,
                                    st,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('שגיאה בעדכון הגדרה: $e'),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'גיבוי ושחזור',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      ListTile(
                        leading: const Icon(Icons.backup_outlined),
                        title: const Text('גיבוי הגדרות והרשאות'),
                        subtitle: const Text(
                          'שמור את כלל הגדרות המערכת לקובץ גיבוי.',
                        ),
                        onTap: () => _backupSettings(context, ref),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: Icon(
                          Icons.restore_page_outlined,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          'שחזור הגדרות מקובץ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        subtitle: Text(
                          'פעולה זו תחליף את כל ההגדרות הנוכחיות.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        onTap: () => _restoreSettings(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logService.logError('Error loading app settings', e, st);
          return Center(child: Text('Error loading settings: $e'));
        },
      ),
    );
  }
}
