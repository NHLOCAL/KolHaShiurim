// core/providers/providers.dart

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/license/license_manager.dart';
import 'package:kol_hashiurim/models/app_user.dart';
import 'package:kol_hashiurim/services/device_service.dart';
import 'package:kol_hashiurim/services/file_service.dart';
import 'package:kol_hashiurim/services/log_service.dart';
import 'package:kol_hashiurim/models/device_info.dart';
import 'package:kol_hashiurim/tray/window_actions.dart';

final licenseManagerProvider = FutureProvider<LicenseManager>((ref) async {
  final pubPem = await rootBundle.loadString('assets/keys/public.pem');
  final publicKey = parsePublicKeyFromPem(pubPem);
  return LicenseManager(publicKey);
});

final licenseStatusProvider = FutureProvider<bool>((ref) async {
  final licenseManager = await ref.watch(licenseManagerProvider.future);
  final logService = ref.read(logServiceProvider);
  return licenseManager.hasValidLicense(logService);
});

final databaseProvider = Provider<AppDatabase>((_) => AppDatabase());
final logServiceProvider = Provider<LogService>((_) => LogService());

final deviceServiceProvider = Provider<DeviceService>((ref) {
  final logService = ref.watch(logServiceProvider);
  return DeviceService(logService);
});

final fileServiceProvider = Provider<FileService>((ref) {
  final logService = ref.watch(logServiceProvider);
  return FileService(logService);
});

final connectedDevicesProvider = StreamProvider<List<ConnectedDeviceInfo>>((ref) {
  return ref.watch(deviceServiceProvider).watchConnectedDevices();
});

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AppUserState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AppUserState> {
  final Ref _ref;
  late final LogService _logService;

  AuthStateNotifier(this._ref) : super(const AppUserState.loggedOut()) {
    _logService = _ref.read(logServiceProvider);
    _listenForDevices();
    _logService.logInfo('Application started, listening for device changes.');
  }

  void _listenForDevices() {
    _ref.listen<AsyncValue<List<ConnectedDeviceInfo>>>(
      connectedDevicesProvider,
      (_, asyncValue) {
        asyncValue.when(
          data: (List<ConnectedDeviceInfo> devices) async {
            _logService.logInfo(
              'Connected devices: ${devices.map((d) => d.serialNumber).join(', ')}'
            );

            // If currently logged in as a user, ensure their device is still connected
            state.whenOrNull(user: (user, device, mountPath) {
              final stillConnected = devices.any(
                (d) => d.serialNumber == device.serialNumber
              );
              if (!stillConnected) {
                _logService.logUserActivity(
                  'User ${user.name} disconnected (device ${device.serialNumber}). Logging out.'
                );
                logout();
              }
            });

            // Auto-login logic if not already logged in
            if (!state.isUser && !state.isAdmin) {
              for (final dev in devices) {
                final db = _ref.read(databaseProvider);
                final dbDevice = await db.getDeviceBySerial(dev.serialNumber);
                if (dbDevice != null) {
                  final user = await (db.select(db.users)
                        ..where((u) => u.id.equals(dbDevice.userId)))
                      .getSingle();
                  state = AppUserState.user(
                    user: user,
                    device: dbDevice,
                    mountPath: dev.mountPath,
                  );
                  _logService.logUserActivity(
                    'User ${user.name} auto-logged in via device ${dev.serialNumber}.'
                  );
                  WindowActions.showUserPanel();
                  break;
                }
              }
            }
          },
          loading: () {
            _logService.logInfo('Waiting for device stream...');
          },
          error: (err, st) {
            _logService.logError('Error in device stream', err, st);
          },
        );
      },
    );
  }

  Future<void> loginAsAdmin() async {
    _logService.logUserActivity('Admin login requested.');
    state = const AppUserState.admin();
    WindowActions.showAdminPanel();
  }

  void logout() {
    _logService.logUserActivity('User logged out.');
    state = const AppUserState.loggedOut();
    WindowActions.hide(resizeToAdmin: false);
  }
}

final allUsersProvider = StreamProvider<List<User>>((ref) {
  return ref.watch(databaseProvider).watchAllUsers();
});

final allRabbisProvider = StreamProvider<List<Rabbi>>((ref) {
  return ref.watch(databaseProvider).watchAllRabbis();
});

final allDevicesProvider = StreamProvider<List<DeviceWithUser>>((ref) {
  return ref.watch(databaseProvider).watchAllDevicesWithUser();
});

final appSettingsProvider = StreamProvider<AppSetting>((ref) {
  return ref.watch(databaseProvider).watchAppSettings();
});
