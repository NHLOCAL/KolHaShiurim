import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';

part 'app_user.freezed.dart';

@freezed
class AppUserState with _$AppUserState {
  const factory AppUserState.loggedOut() = _LoggedOut;
  const factory AppUserState.admin() = _Admin;

  const factory AppUserState.user({
    required User user,
    required Device device,
    required String mountPath,
  }) = _User;

  const AppUserState._();

  bool get isAdmin => this is _Admin;
  bool get isUser => this is _User;
  bool get isLoggedOut => this is _LoggedOut;
}
