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
  // Prevent the stream from being disposed when no longer listened to,
  // so it keeps running in the background.
  final controller = ref.watch(deviceServiceProvider).watchConnectedDevices();
  ref.onDispose(() {
    // This might not be strictly necessary with asBroadcastStream, but good practice.
  });
  return controller;
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
        // If a user is already logged in, check if their device is still connected.
        // If not, log them out.
        state.whenOrNull(user: (user, device, mountPath) {
          final isConnected = devices.any((d) => d.serialNumber == device.serialNumber);
          if (!isConnected) {
            logout();
          }
        });

        // Don't try to log in a new user if one is already in.
        if (state.isUser) return;

        // Try to log in based on newly connected devices.
        for (final connectedDevice in devices) {
          final dbDevice = await _ref.read(databaseProvider).getDeviceBySerial(connectedDevice.serialNumber);
          
          if (dbDevice != null) {
            final user = await (_ref.read(databaseProvider).select(_ref.read(databaseProvider).users)
                  ..where((u) => u.id.equals(dbDevice.userId)))
                .getSingle();
            
            // CHANGED: Set state with user, db device config, AND runtime mount path.
            state = AppUserState.user(
              user: user,
              device: dbDevice,
              mountPath: connectedDevice.mountPath,
            );
            return; // Found a match, stop searching
          }
        }
      });
    });
  }

  Future<void> loginAsAdmin() async {
    // In a real app, this would involve a password.
    var admin = await (_ref.read(databaseProvider).select(_ref.read(databaseProvider).users)
          ..where((u) => u.isAdmin.equals(true)))
        .getSingleOrNull();
        
    if (admin == null) {
      final adminId = await _ref.read(databaseProvider).insertUser(
            const UsersCompanion(name: Value('Admin'), isAdmin: Value(true)),
          );
      admin = await (_ref.read(databaseProvider).select(_ref.read(databaseProvider).users)
            ..where((u) => u.id.equals(adminId)))
          .getSingle();
    }
    state = AppUserState.admin(admin);
  }

  void logout() {
    state = const AppUserState.loggedOut();
  }
}

// --- ADMIN PANEL PROVIDERS ---

final allUsersProvider = StreamProvider<List<User>>((ref) {
  return ref.watch(databaseProvider).watchAllUsers();
});

final allRabbisProvider = StreamProvider<List<Rabbi>>((ref) {
  return ref.watch(databaseProvider).watchAllRabbis();
});

// NEW: Provider for devices joined with their user names.
final allDevicesProvider = StreamProvider<List<DeviceWithUser>>((ref) {
  return ref.watch(databaseProvider).watchAllDevicesWithUser();
});