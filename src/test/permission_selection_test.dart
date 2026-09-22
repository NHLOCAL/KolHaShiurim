import 'package:flutter_test/flutter_test.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/features/user_panel/utils/permission_selection.dart';

Rabbi _buildRabbi(int id) {
  return Rabbi(id: id, name: 'Rabbi $id', targetPath: 'C:\\target$id');
}

UserPermissionInfo _permission(int id, List<String?> paths) {
  return UserPermissionInfo(rabbi: _buildRabbi(id), specificPaths: paths);
}

void main() {
  group('resolvePermissionSelection', () {
    test('returns null selection when no permissions are available', () {
      final result = resolvePermissionSelection(
        selectedPermission: null,
        selectedSpecificPath: null,
        availablePermissions: const [],
      );

      expect(result.permission, isNull);
      expect(result.specificPath, isNull);
      expect(result.isPathSelectionRequired, isFalse);
    });

    test('resolves permission by rabbi id even with new instances', () {
      final selected = _permission(1, [null]);
      final available = [_permission(1, [null]), _permission(2, [null])];

      final result = resolvePermissionSelection(
        selectedPermission: selected,
        selectedSpecificPath: null,
        availablePermissions: available,
      );

      expect(result.permission, same(available.first));
    });

    test('clears selection when permission no longer exists', () {
      final selected = _permission(3, [null]);
      final available = [_permission(1, [null]), _permission(2, [null])];

      final result = resolvePermissionSelection(
        selectedPermission: selected,
        selectedSpecificPath: null,
        availablePermissions: available,
      );

      expect(result.permission, isNull);
      expect(result.specificPath, isNull);
    });

    test('auto-selects the single available path', () {
      final available = [_permission(1, ['year-1'])];

      final result = resolvePermissionSelection(
        selectedPermission: available.first,
        selectedSpecificPath: null,
        availablePermissions: available,
      );

      expect(result.permission, same(available.first));
      expect(result.specificPath, 'year-1');
      expect(result.isPathSelectionRequired, isFalse);
    });

    test('drops invalid specific path when multiple options exist', () {
      final available = [_permission(1, ['a', 'b'])];

      final result = resolvePermissionSelection(
        selectedPermission: available.first,
        selectedSpecificPath: 'missing',
        availablePermissions: available,
      );

      expect(result.permission, same(available.first));
      expect(result.specificPath, isNull);
      expect(result.isPathSelectionRequired, isTrue);
    });

    test('keeps valid specific path when multiple options exist', () {
      final available = [_permission(1, ['a', 'b'])];

      final result = resolvePermissionSelection(
        selectedPermission: available.first,
        selectedSpecificPath: 'b',
        availablePermissions: available,
      );

      expect(result.permission, same(available.first));
      expect(result.specificPath, 'b');
      expect(result.isPathSelectionRequired, isTrue);
    });

    test('returns null specific path when permission paths are empty', () {
      final available = [_permission(1, const [])];

      final result = resolvePermissionSelection(
        selectedPermission: available.first,
        selectedSpecificPath: 'anything',
        availablePermissions: available,
      );

      expect(result.permission, same(available.first));
      expect(result.specificPath, isNull);
      expect(result.isPathSelectionRequired, isFalse);
    });
  });
}
