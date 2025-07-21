import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/license/license_manager.dart'; // Import חדש
import 'package:torah_shiurim_transfer/models/app_user.dart';
import 'package:torah_shiurim_transfer/services/device_service.dart';
import 'package:torah_shiurim_transfer/services/file_service.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';
import 'package:torah_shiurim_transfer/tray/window_actions.dart';

final licenseManagerProvider = FutureProvider<LicenseManager>((ref) async {
  final pubPem = await rootBundle.loadString('assets/keys/public.pem');
  final publicKey = parsePublicKeyFromPem(pubPem);
  return LicenseManager(publicKey);
});

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final logServiceProvider = Provider<LogService>((ref) => LogService());

final deviceServiceProvider = Provider<DeviceService>((ref) {
  final logService = ref.watch(logServiceProvider);
  return DeviceService(logService);
});
final fileServiceProvider = Provider<FileService>((ref) {
  final logService = ref.watch(logServiceProvider);
  return FileService(logService);
});

final connectedDevicesProvider = StreamProvider((ref) {
  final controller = ref.watch(deviceServiceProvider).watchConnectedDevices();
  ref.onDispose(() {});
  return controller;
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
    _logService.logInfo(
        'Application started, listening for authentication state changes.');
  }

  void _listenForDevices() {
    _ref.listen(connectedDevicesProvider, (_, asyncValue) {
      asyncValue.maybeWhen(
        data: (devices) async {
          _logService.logInfo(
              'Connected devices updated: ${devices.map((d) => d.serialNumber).join(', ')}');

          state.whenOrNull(user: (user, device, mountPath) {
            final isConnected =
                devices.any((d) => d.serialNumber == device.serialNumber);
            if (!isConnected) {
              _logService.logUserActivity(
                  'User ${user.name} (device ${device.serialNumber}) disconnected. Logging out.');
              logout();
            }
          });

          if (state.isUser) return;
          if (state.isAdmin) return;

          for (final connectedDevice in devices) {
            final dbDevice = await _ref
                .read(databaseProvider)
                .getDeviceBySerial(connectedDevice.serialNumber);

            if (dbDevice != null) {
              final user = await (_ref
                      .read(databaseProvider)
                      .select(_ref.read(databaseProvider).users)
                    ..where((u) => u.id.equals(dbDevice.userId)))
                  .getSingle();

              state = AppUserState.user(
                user: user,
                device: dbDevice,
                mountPath: connectedDevice.mountPath,
              );
              _logService.logUserActivity(
                  'User ${user.name} logged in automatically via device ${dbDevice.serialNumber}.');

              WindowActions.showUserPanel();
              return;
            }
          }
          _logService.logInfo('No user device found, staying logged out.');
        },
        error: (error, stackTrace) {
          _logService.logError(
              'Error watching connected devices', error, stackTrace);
        },
        orElse: () {
          _logService.logInfo(
              'Connected devices stream is in a non-data/non-error state (e.g., loading).');
        },
      );
    });
  }

  Future<void> loginAsAdmin() async {
    _logService.logUserActivity('Attempting to log in as Admin.');
    try {
      state = const AppUserState.admin();
      _logService.logUserActivity('Admin logged in.');
      WindowActions.showAdminPanel();
    } catch (e, st) {
      _logService.logError('Failed to login as Admin.', e, st);
    }
  }

  void logout() {
    _logService.logUserActivity(
        'User logged out manually or due to device disconnection.');
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
