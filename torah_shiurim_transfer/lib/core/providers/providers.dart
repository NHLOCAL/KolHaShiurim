import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/models/app_user.dart';
import 'package:torah_shiurim_transfer/services/device_service.dart';
import 'package:torah_shiurim_transfer/services/file_service.dart';
import 'package:drift/drift.dart';
import 'package:torah_shiurim_transfer/tray/window_actions.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final deviceServiceProvider = Provider<DeviceService>((ref) => DeviceService());
final fileServiceProvider = Provider<FileService>((ref) => FileService());

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
  AuthStateNotifier(this._ref) : super(const AppUserState.loggedOut()) {
    _listenForDevices();
  }

  void _listenForDevices() {
    _ref.listen(connectedDevicesProvider, (_, asyncValue) {
      asyncValue.whenData((devices) async {
        state.whenOrNull(user: (user, device, mountPath) {
          final isConnected =
              devices.any((d) => d.serialNumber == device.serialNumber);
          if (!isConnected) {
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

            WindowActions.showUserPanel();
            return;
          }
        }
      });
    });
  }

  Future<void> loginAsAdmin() async {
    var admin = await (_ref
            .read(databaseProvider)
            .select(_ref.read(databaseProvider).users)
          ..where((u) => u.isAdmin.equals(true)))
        .getSingleOrNull();

    if (admin == null) {
      final adminId = await _ref.read(databaseProvider).insertUser(
            const UsersCompanion(name: Value('Admin'), isAdmin: Value(true)),
          );
      admin = await (_ref
              .read(databaseProvider)
              .select(_ref.read(databaseProvider).users)
            ..where((u) => u.id.equals(adminId)))
          .getSingle();
    }
    state = AppUserState.admin(admin);

    WindowActions.showAdminPanel();
  }

  void logout() {
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
