import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/features/admin_panel/user_management_tab.dart';

import 'helpers/test_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adding multiple specific paths saves without crashing', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final userId = await database.insertUser(
      UsersCompanion(name: const Value('Tester'), additionalInfo: const Value(null)),
    );
    await database.insertRabbi(
      RabbisCompanion(
        name: const Value('Rabbi A'),
        targetPath: const Value('/base/path'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          logServiceProvider.overrideWithValue(TestLogService()),
        ],
        child: const MaterialApp(home: UserManagementTab()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('הרשאות'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('הוסף הגבלת תיקיה'));
    await tester.tap(find.text('הוסף הגבלת תיקיה'));
    await tester.pumpAndSettle();

    final pathFields = find.byType(TextFormField);
    expect(pathFields, findsNWidgets(2));

    await tester.enterText(pathFields.at(0), 'folder/one');
    await tester.enterText(pathFields.at(1), 'folder/two');

    await tester.tap(find.text('שמור'));
    await tester.pumpAndSettle();

    final savedPermissions = await database.getPermissionsForUser(userId);
    expect(savedPermissions, hasLength(1));
    final savedPaths =
        json.decode(savedPermissions.first.specificPath!) as List<dynamic>;
    expect(savedPaths, ['folder/one', 'folder/two']);
  });
}
