import 'package:kol_hashiurim/core/database/database.dart';

class PermissionSelectionResult {
  final UserPermissionInfo? permission;
  final String? specificPath;

  const PermissionSelectionResult({
    required this.permission,
    required this.specificPath,
  });

  bool get isPathSelectionRequired =>
      permission != null && permission!.specificPaths.length > 1;
}

PermissionSelectionResult resolvePermissionSelection({
  required UserPermissionInfo? selectedPermission,
  required String? selectedSpecificPath,
  required List<UserPermissionInfo> availablePermissions,
}) {
  if (availablePermissions.isEmpty) {
    return const PermissionSelectionResult(
      permission: null,
      specificPath: null,
    );
  }

  UserPermissionInfo? resolvedPermission;
  if (selectedPermission != null) {
    for (final permission in availablePermissions) {
      if (permission.rabbi.id == selectedPermission.rabbi.id) {
        resolvedPermission = permission;
        break;
      }
    }
  }

  if (resolvedPermission == null) {
    return const PermissionSelectionResult(
      permission: null,
      specificPath: null,
    );
  }

  final paths = resolvedPermission.specificPaths;
  if (paths.isEmpty) {
    return PermissionSelectionResult(
      permission: resolvedPermission,
      specificPath: null,
    );
  }

  if (paths.length == 1) {
    return PermissionSelectionResult(
      permission: resolvedPermission,
      specificPath: paths.first,
    );
  }

  final resolvedPath = paths.contains(selectedSpecificPath)
      ? selectedSpecificPath
      : null;
  return PermissionSelectionResult(
    permission: resolvedPermission,
    specificPath: resolvedPath,
  );
}
