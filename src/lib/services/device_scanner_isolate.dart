import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class IsolateDeviceInfo {
  final String path;
  final String serial;

  IsolateDeviceInfo(this.path, this.serial);
}

List<IsolateDeviceInfo> scanDevicesSync(void _) {
  final devices = <IsolateDeviceInfo>[];
  
  int oldMode = SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOOPENFILEERRORBOX);
  
  try {
    final mask = GetLogicalDrives();
    if (mask == 0) return [];

    for (var i = 0; i < 26; i++) {
      if ((mask & (1 << i)) == 0) continue;
      
      final root = '${String.fromCharCode(65 + i)}:\\';
      final rootPtr = root.toNativeUtf16(allocator: calloc);
      
      try {
        if (GetDriveType(rootPtr) == DRIVE_REMOVABLE) {
          final volName = calloc<Uint16>(MAX_PATH);
          final fsName = calloc<Uint16>(MAX_PATH);
          final serialPtr = calloc<Uint32>();
          final maxComp = calloc<Uint32>();
          final flags = calloc<Uint32>();

          try {
            final result = GetVolumeInformation(
              rootPtr, 
              volName, 
              MAX_PATH, 
              serialPtr, 
              maxComp, 
              flags, 
              fsName, 
              MAX_PATH
            );

            if (result != 0) {
              final serialHex = serialPtr.value.toRadixString(16).toUpperCase().padLeft(8, '0');
              final formattedSerial = '${serialHex.substring(0, 4)}-${serialHex.substring(4)}';
              devices.add(IsolateDeviceInfo(root, formattedSerial));
            }
          } finally {
            calloc.free(volName);
            calloc.free(fsName);
            calloc.free(serialPtr);
            calloc.free(maxComp);
            calloc.free(flags);
          }
        }
      } catch (e) {
      } finally {
        calloc.free(rootPtr);
      }
    }
  } finally {
    SetErrorMode(oldMode);
  }
  
  return devices;
}