import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:path/path.dart' as p;

Future<AppDatabase> createLegacyDatabase(Directory directory) async {
  final database = AppDatabase.forTesting(
    NativeDatabase(
      File(p.join(directory.path, 'torah_shiurim.sqlite')),
      setup: (database) => database.execute('PRAGMA journal_mode=WAL;'),
    ),
  );
  await database.getAllUsers();
  // Recreate the schema difference between v5 and v6: v5 had mount_path.
  await database.customStatement(
    "ALTER TABLE devices ADD COLUMN mount_path TEXT NOT NULL DEFAULT 'E:'",
  );
  await database.customStatement(
    "INSERT INTO users (id, name, additional_info) VALUES (1, 'Old user', 'note')",
  );
  await database.customStatement(
    "INSERT INTO devices (user_id, serial_number, source_path) "
    "VALUES (1, 'OLD-DEVICE', 'recordings')",
  );
  await database.customStatement(
    "INSERT INTO rabbis (id, name, target_path) VALUES (1, 'Rabbi', 'D:/lessons')",
  );
  await database.customStatement(
    "INSERT INTO user_rabbi_permissions (user_id, rabbi_id, specific_path) "
    "VALUES (1, 1, '[\"weekly\"]')",
  );
  await database.customStatement(
    "INSERT INTO transfers (user_id, source_file, destination_file, timestamp) "
    "VALUES (1, 'source.mp3', 'D:/lessons/target.mp3', 1)",
  );
  await database.customStatement(
    'INSERT INTO app_settings (id, convert_to_mp3, mp3_bitrate) '
    'VALUES (1, 1, 192)',
  );
  await database.customStatement('PRAGMA user_version = 5');
  return database;
}

void main() {
  final previousWarningSetting =
      driftRuntimeOptions.dontWarnAboutMultipleDatabases;
  setUpAll(() {
    // These tests intentionally open separate connections to preserve a WAL.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = previousWarningSetting;
  });

  test(
    'opens and upgrades the legacy database without losing its data',
    () async {
      final directory = await Directory.systemTemp.createTemp('shiurim-db-');
      final legacy = await createLegacyDatabase(directory);
      final database = AppDatabase.forDirectory(directory);
      try {
        expect((await database.getAllUsers()).single.name, 'Old user');
        expect(
          (await database.getDeviceBySerial('OLD-DEVICE'))?.sourcePath,
          'recordings',
        );
        expect((await database.getAppSettings()).mp3Bitrate, 192);
        expect((await database.getAppSettings()).convertToMp3, isTrue);
        expect((await database.watchAllRabbis().first).single.name, 'Rabbi');
        expect(
          (await database.getPermissionsForUser(1)).single.specificPath,
          '["weekly"]',
        );
        expect(
          (await database
                  .customSelect('SELECT source_file FROM transfers')
                  .get())
              .single
              .read<String>('source_file'),
          'source.mp3',
        );
        expect(
          (await database.customSelect('PRAGMA user_version').getSingle())
              .read<int>('user_version'),
          6,
        );
        expect(
          File(p.join(directory.path, 'torah_shiurim.sqlite')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(directory.path, 'kol_hashiurim.sqlite')).existsSync(),
          isFalse,
        );
      } finally {
        await database.close();
        await legacy.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test('prefers an existing database under the current filename', () async {
    final directory = await Directory.systemTemp.createTemp('shiurim-db-');
    final firstOpen = AppDatabase.forDirectory(directory);
    await firstOpen.getAllUsers();
    await firstOpen.customStatement(
      "INSERT INTO users (name) VALUES ('Current user')",
    );
    await firstOpen.close();
    final legacy = await createLegacyDatabase(directory);
    final current = AppDatabase.forDirectory(directory);
    try {
      expect((await current.getAllUsers()).single.name, 'Current user');
    } finally {
      await current.close();
      await legacy.close();
      await directory.delete(recursive: true);
    }
  });

  test('creates the current filename for a fresh installation', () async {
    final directory = await Directory.systemTemp.createTemp('shiurim-db-');
    final database = AppDatabase.forDirectory(directory);
    try {
      expect(await database.getAllUsers(), isEmpty);
      expect(
        File(p.join(directory.path, 'kol_hashiurim.sqlite')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(directory.path, 'torah_shiurim.sqlite')).existsSync(),
        isFalse,
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
