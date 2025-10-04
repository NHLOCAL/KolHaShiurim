import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';

final sourceFilesProvider = FutureProvider.autoDispose<List<File>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final fileService = ref.watch(fileServiceProvider);
  final logService = ref.read(logServiceProvider);

  ref.watch(lastCopiedFileNameProvider);

  return authState.maybeMap(
    user: (userState) async {
      final sourcePath = p.join(
        userState.mountPath,
        userState.device.sourcePath,
      );
      logService.logInfo(
        'Fetching audio files from device source path: $sourcePath for user: ${userState.user.name}',
      );
      try {
        return await fileService.getAudioFiles(sourcePath);
      } catch (e, st) {
        logService.logError(
          'Failed to get audio files from $sourcePath',
          e,
          st,
        );
        return [];
      }
    },
    orElse: () {
      logService.logInfo(
        'No user logged in, returning empty list for source files.',
      );
      return [];
    },
  );
});

final allowedRabbisProvider =
    StreamProvider.autoDispose<List<UserPermissionInfo>>((ref) {
      final authState = ref.watch(authStateProvider);
      final db = ref.watch(databaseProvider);
      final logService = ref.read(logServiceProvider);

      return authState.maybeMap(
        user: (userState) {
          logService.logInfo(
            'Watching permissions for user: ${userState.user.name}',
          );
          return db.watchPermissionsForUser(userState.user.id);
        },
        orElse: () {
          logService.logInfo(
            'No user logged in, returning empty stream for allowed rabbis.',
          );
          return Stream.value([]);
        },
      );
    });

final lastCopiedFileNameProvider = StateProvider<String?>((ref) => null);
