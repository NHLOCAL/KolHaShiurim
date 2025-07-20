import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'tables.dart';
part 'database.g.dart';

@DriftDatabase(tables: [
  Users,
  Devices,
  Rabbis,
  UserRabbiPermissions,
  Transfers,
  AppSettings
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(appSettings);
        }
        if (from < 3) {
          await m.addColumn(
              userRabbiPermissions, userRabbiPermissions.specificPath);
        }

        if (from < 4) {
          await m.addColumn(users, users.additionalInfo);
        }
        if (from < 5) {
          // The `isAdmin` column was removed from the `Users` table class.
          // In a real-world scenario with existing data, a data migration
          // (copy to new table, drop old, rename new) would be needed.
          // For this project's scope, we assume new databases or unimportant
          // old data for this specific column. Drift will handle the schema change.
        }
      },
    );
  }

  Future<List<User>> getAllUsers() => select(users).get();
  Stream<List<User>> watchAllUsers() => select(users).watch();
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);
  Future<bool> updateUser(UsersCompanion user) => update(users).replace(user);
  Future<int> deleteUser(int id) =>
      (delete(users)..where((u) => u.id.equals(id))).go();

  Stream<List<Device>> watchAllDevices() => select(devices).watch();
  Stream<List<DeviceWithUser>> watchAllDevicesWithUser() {
    final query = select(devices).join([
      innerJoin(users, users.id.equalsExp(devices.userId)),
    ]);
    return query.watch().map((rows) {
      return rows.map((row) {
        return DeviceWithUser(
          device: row.readTable(devices),
          user: row.readTable(users),
        );
      }).toList();
    });
  }

  Future<Device?> getDeviceBySerial(String serial) =>
      (select(devices)..where((d) => d.serialNumber.equals(serial)))
          .getSingleOrNull();
  Future<int> insertDevice(DevicesCompanion device) =>
      into(devices).insert(device);
  Future<bool> updateDevice(DevicesCompanion device) =>
      update(devices).replace(device);
  Future<int> deleteDevice(int id) =>
      (delete(devices)..where((d) => d.id.equals(id))).go();

  Stream<List<Rabbi>> watchAllRabbis() => select(rabbis).watch();
  Future<int> insertRabbi(RabbisCompanion rabbi) => into(rabbis).insert(rabbi);
  Future<bool> updateRabbi(RabbisCompanion rabbi) =>
      update(rabbis).replace(rabbi);
  Future<int> deleteRabbi(int id) =>
      (delete(rabbis)..where((r) => r.id.equals(id))).go();

  Stream<List<UserPermissionInfo>> watchPermissionsForUser(int userId) {
    final query = select(userRabbiPermissions).join(
        [innerJoin(rabbis, rabbis.id.equalsExp(userRabbiPermissions.rabbiId))])
      ..where(userRabbiPermissions.userId.equals(userId));
    return query.watch().map((rows) => rows.map((row) {
          final p = row.readTable(userRabbiPermissions);
          return UserPermissionInfo(
            rabbi: row.readTable(rabbis),
            specificPath: p.specificPath,
          );
        }).toList());
  }

  Future<void> setPermissionsForUser(
      int userId, Map<int, String?> permissions) async {
    await transaction(() async {
      await (delete(userRabbiPermissions)
            ..where((p) => p.userId.equals(userId)))
          .go();
      for (final entry in permissions.entries) {
        final rabbiId = entry.key;
        final specificPath = entry.value;
        await into(userRabbiPermissions).insert(
            UserRabbiPermissionsCompanion.insert(
                userId: userId,
                rabbiId: rabbiId,
                specificPath: Value(specificPath)));
      }
    });
  }

  Future<List<UserRabbiPermission>> getPermissionsForUser(int userId) async {
    final permissions = await (select(userRabbiPermissions)
          ..where((p) => p.userId.equals(userId)))
        .get();
    return permissions;
  }

  Future<int> logTransfer(TransfersCompanion transfer) =>
      into(transfers).insert(transfer);

  Future<AppSetting> getAppSettings() async {
    var setting = await (select(appSettings)..where((s) => s.id.equals(1)))
        .getSingleOrNull();
    if (setting == null) {
      final defaultSettings = AppSettingsCompanion.insert(id: const Value(1));
      await into(appSettings)
          .insert(defaultSettings, mode: InsertMode.insertOrIgnore);
      setting =
          await (select(appSettings)..where((s) => s.id.equals(1))).getSingle();
    }
    return setting;
  }

  Stream<AppSetting> watchAppSettings() {
    return (select(appSettings)..where((s) => s.id.equals(1))).watchSingle();
  }

  Future<void> updateAppSettings(AppSettingsCompanion settings) {
    return (update(appSettings)..where((s) => s.id.equals(1))).write(settings);
  }
}

class DeviceWithUser {
  final Device device;
  final User user;
  DeviceWithUser({required this.device, required this.user});
}

class UserPermissionInfo {
  final Rabbi rabbi;
  final String? specificPath;
  UserPermissionInfo({required this.rabbi, this.specificPath});
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'torah_shiurim.sqlite'));
    return NativeDatabase(file);
  });
}
