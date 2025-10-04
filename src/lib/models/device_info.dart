// models/device_info.dart

class ConnectedDeviceInfo {
  /// The root path of the drive, e.g. `E:\`
  final String mountPath;

  /// The volume serial number in the format `1234-ABCD`
  final String serialNumber;

  ConnectedDeviceInfo({
    required this.mountPath,
    required this.serialNumber,
  });
}
