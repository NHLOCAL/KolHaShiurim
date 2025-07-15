class ConnectedDeviceInfo {
  final String mountPath; // e.g., E:\
  final String serialNumber; // In real app, the hardware serial. Here, it's also the mount path.

  ConnectedDeviceInfo({required this.mountPath, required this.serialNumber});
}