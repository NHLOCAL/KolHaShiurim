import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'tables.dart';
part 'database.g.dart';

// The list of tables for the database.
@DriftDatabase(tables: [Users, Devices, Rabbis, UserRabbiPermissions, Transfers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- User Queries ---
  Future<List<User>> getAllUsers() => select(users).get();
  Stream<List<User>> watchAllUsers() => select(users).watch();
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);
  Future<bool> updateUser(UsersCompanion user) => update(users).replace(user);
  Future<int> deleteUser(int id) => (delete(users)..where((u) => u.id.equals(id))).go();

  // --- Device Queries ---
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
  Future<Device?> getDeviceBySerial(String serial) => (select(devices)..where((d) => d.serialNumber.equals(serial))).getSingleOrNull();
  Future<int> insertDevice(DevicesCompanion device) => into(devices).insert(device);
  Future<bool> updateDevice(DevicesCompanion device) => update(devices).replace(device);
  Future<int> deleteDevice(int id) => (delete(devices)..where((d) => d.id.equals(id))).go();

  // --- Rabbi Queries ---
  Stream<List<Rabbi>> watchAllRabbis() => select(rabbis).watch();
  Future<int> insertRabbi(RabbisCompanion rabbi) => into(rabbis).insert(rabbi);
  Future<bool> updateRabbi(RabbisCompanion rabbi) => update(rabbis).replace(rabbi);
  Future<int> deleteRabbi(int id) => (delete(rabbis)..where((r) => r.id.equals(id))).go();

  // --- Permission Queries ---
  Stream<List<Rabbi>> watchPermissionsForUser(int userId) {
    final query = select(userRabbiPermissions).join([
      innerJoin(rabbis, rabbis.id.equalsExp(userRabbiPermissions.rabbiId))
    ])
    ..where(userRabbiPermissions.userId.equals(userId));
    return query.watch().map((rows) => rows.map((row) => row.readTable(rabbis)).toList());
  }

  Future<void> setPermissionsForUser(int userId, List<int> rabbiIds) async {
    await transaction(() async {
      await (delete(userRabbiPermissions)..where((p) => p.userId.equals(userId))).go();
      for (final rabbiId in rabbiIds) {
        await into(userRabbiPermissions).insert(UserRabbiPermissionsCompanion.insert(userId: userId, rabbiId: rabbiId));
      }
    });
  }

  Future<List<int>> getPermissionIdsForUser(int userId) async {
      final permissions = await (select(userRabbiPermissions)..where((p) => p.userId.equals(userId))).get();
      return permissions.map((p) => p.rabbiId).toList();
  }

  // --- Transfer Log Queries ---
  Future<int> logTransfer(TransfersCompanion transfer) => into(transfers).insert(transfer);
}

// Helper class to combine Device and User data for the admin panel.
class DeviceWithUser {
  final Device device;
  final User user;
  DeviceWithUser({required this.device, required this.user});
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'torah_shiurim.sqlite'));
    return NativeDatabase(file);
  });
}