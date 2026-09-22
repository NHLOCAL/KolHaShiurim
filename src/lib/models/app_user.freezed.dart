// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppUserState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AppUserState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUserState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AppUserState()';
}


}

/// @nodoc
class $AppUserStateCopyWith<$Res>  {
$AppUserStateCopyWith(AppUserState _, $Res Function(AppUserState) __);
}


/// Adds pattern-matching-related methods to [AppUserState].
extension AppUserStatePatterns on AppUserState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoggedOut value)?  loggedOut,TResult Function( _Admin value)?  admin,TResult Function( _User value)?  user,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoggedOut() when loggedOut != null:
return loggedOut(_that);case _Admin() when admin != null:
return admin(_that);case _User() when user != null:
return user(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoggedOut value)  loggedOut,required TResult Function( _Admin value)  admin,required TResult Function( _User value)  user,}){
final _that = this;
switch (_that) {
case _LoggedOut():
return loggedOut(_that);case _Admin():
return admin(_that);case _User():
return user(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoggedOut value)?  loggedOut,TResult? Function( _Admin value)?  admin,TResult? Function( _User value)?  user,}){
final _that = this;
switch (_that) {
case _LoggedOut() when loggedOut != null:
return loggedOut(_that);case _Admin() when admin != null:
return admin(_that);case _User() when user != null:
return user(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loggedOut,TResult Function()?  admin,TResult Function( User user,  Device device,  String mountPath)?  user,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoggedOut() when loggedOut != null:
return loggedOut();case _Admin() when admin != null:
return admin();case _User() when user != null:
return user(_that.user,_that.device,_that.mountPath);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loggedOut,required TResult Function()  admin,required TResult Function( User user,  Device device,  String mountPath)  user,}) {final _that = this;
switch (_that) {
case _LoggedOut():
return loggedOut();case _Admin():
return admin();case _User():
return user(_that.user,_that.device,_that.mountPath);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loggedOut,TResult? Function()?  admin,TResult? Function( User user,  Device device,  String mountPath)?  user,}) {final _that = this;
switch (_that) {
case _LoggedOut() when loggedOut != null:
return loggedOut();case _Admin() when admin != null:
return admin();case _User() when user != null:
return user(_that.user,_that.device,_that.mountPath);case _:
  return null;

}
}

}

/// @nodoc


class _LoggedOut extends AppUserState with DiagnosticableTreeMixin {
  const _LoggedOut(): super._();






@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AppUserState.loggedOut'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoggedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AppUserState.loggedOut()';
}


}




/// @nodoc


class _Admin extends AppUserState with DiagnosticableTreeMixin {
  const _Admin(): super._();






@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AppUserState.admin'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Admin);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AppUserState.admin()';
}


}




/// @nodoc


class _User extends AppUserState with DiagnosticableTreeMixin {
  const _User({required this.user, required this.device, required this.mountPath}): super._();


 final  User user;
 final  Device device;
 final  String mountPath;

/// Create a copy of AppUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AppUserState.user'))
    ..add(DiagnosticsProperty('user', user))..add(DiagnosticsProperty('device', device))..add(DiagnosticsProperty('mountPath', mountPath));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.user, user) || other.user == user)&&(identical(other.device, device) || other.device == device)&&(identical(other.mountPath, mountPath) || other.mountPath == mountPath));
}


@override
int get hashCode => Object.hash(runtimeType,user,device,mountPath);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AppUserState.user(user: $user, device: $device, mountPath: $mountPath)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $AppUserStateCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@useResult
$Res call({
 User user, Device device, String mountPath
});




}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of AppUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,Object? device = null,Object? mountPath = null,}) {
  return _then(_User(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,device: null == device ? _self.device : device // ignore: cast_nullable_to_non_nullable
as Device,mountPath: null == mountPath ? _self.mountPath : mountPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
