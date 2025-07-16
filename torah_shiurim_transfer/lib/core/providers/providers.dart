import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/models/app_user.dart';
import 'package:torah_shiurim_transfer/services/device_service.dart';
import 'package:torah_shiurim_transfer/services/file_service.dart';
import 'package:drift/drift.dart';


// --- SERVICE PROVIDERS ---
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final deviceServiceProvider = Provider<DeviceService>((ref) => DeviceService());
final fileServiceProvider = Provider<FileService>((ref) => FileService());

// --- AUTHENTICATION & DEVICE DETECTION ---
final connectedDevicesProvider = StreamProvider((ref) {
  return ref.watch(deviceServiceProvider).watchConnectedDevices();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AppUserState>((ref) {
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
        if (state.isUser) return; // Don't re-authenticate if a user is already in

        for (final connectedDevice in devices) {
          final dbDevice = await _ref.read(databaseProvider).getDeviceBySerial(connectedDevice.serialNumber);
          if (dbDevice != null) {
            final user = await (_ref.read(databaseProvider).select(_ref.read(databaseProvider).users)..where((u) => u.id.equals(dbDevice.userId))).getSingle();
            state = AppUserState.user(user: user, device: dbDevice);
            return; // Found a match, stop searching
          }
        }
      });
    });
  }

  void loginAsAdmin() async {
    // In a real app, this would involve a password.
    // Here, we just find or create a default admin.
    var admin = await (_ref.read(databaseProvider).select(_ref.read(databaseProvider).users)..where((u) => u.isAdmin.equals(true))).getSingleOrNull();
    if (admin == null) {
      final adminId = await _ref.read(databaseProvider).insertUser(const UsersCompanion(name: Value('Admin'), isAdmin: Value(true)));
      admin = await (_ref.read(databaseProvider).select(_ref.read(databaseProvider).users)..where((u) => u.id.equals(adminId))).getSingle();
    }
    state = AppUserState.admin(admin);
  }

  void logout() {
    state = const AppUserState.loggedOut();
  }
}