import 'package:kol_hashiurim/services/device_service.dart';
import 'package:kol_hashiurim/services/log_service.dart';

class PollingManager {
  final DeviceService _deviceService;
  final LogService _logService;
  PollingManager(this._deviceService, this._logService);
  void pausePollingForOperation() {
    _logService.logInfo(
      'Pausing background polling for a native file operation.',
    );
    _deviceService.pausePolling();
  }

  void resumePollingAfterOperation() {
    _logService.logInfo(
      'Resuming background polling after a native file operation.',
    );
    _deviceService.resumePolling();
  }
}
