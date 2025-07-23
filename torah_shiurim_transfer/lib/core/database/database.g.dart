// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 2,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _additionalInfoMeta = const VerificationMeta(
    'additionalInfo',
  );
  @override
  late final GeneratedColumn<String> additionalInfo = GeneratedColumn<String>(
    'additional_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, additionalInfo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('additional_info')) {
      context.handle(
        _additionalInfoMeta,
        additionalInfo.isAcceptableOrUnknown(
          data['additional_info']!,
          _additionalInfoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      additionalInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}additional_info'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final String? additionalInfo;
  const User({required this.id, required this.name, this.additionalInfo});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || additionalInfo != null) {
      map['additional_info'] = Variable<String>(additionalInfo);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      additionalInfo: additionalInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(additionalInfo),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      additionalInfo: serializer.fromJson<String?>(json['additionalInfo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'additionalInfo': serializer.toJson<String?>(additionalInfo),
    };
  }

  User copyWith({
    int? id,
    String? name,
    Value<String?> additionalInfo = const Value.absent(),
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    additionalInfo: additionalInfo.present
        ? additionalInfo.value
        : this.additionalInfo,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      additionalInfo: data.additionalInfo.present
          ? data.additionalInfo.value
          : this.additionalInfo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('additionalInfo: $additionalInfo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, additionalInfo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.additionalInfo == this.additionalInfo);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> additionalInfo;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.additionalInfo = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.additionalInfo = const Value.absent(),
  }) : name = Value(name);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? additionalInfo,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (additionalInfo != null) 'additional_info': additionalInfo,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? additionalInfo,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (additionalInfo.present) {
      map['additional_info'] = Variable<String>(additionalInfo.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('additionalInfo: $additionalInfo')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _mountPathMeta = const VerificationMeta(
    'mountPath',
  );
  @override
  late final GeneratedColumn<String> mountPath = GeneratedColumn<String>(
    'mount_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    serialNumber,
    mountPath,
    sourcePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serialNumberMeta);
    }
    if (data.containsKey('mount_path')) {
      context.handle(
        _mountPathMeta,
        mountPath.isAcceptableOrUnknown(data['mount_path']!, _mountPathMeta),
      );
    } else if (isInserting) {
      context.missing(_mountPathMeta);
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcePathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      )!,
      mountPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mount_path'],
      )!,
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final int id;
  final int userId;
  final String serialNumber;
  final String mountPath;
  final String sourcePath;
  const Device({
    required this.id,
    required this.userId,
    required this.serialNumber,
    required this.mountPath,
    required this.sourcePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['serial_number'] = Variable<String>(serialNumber);
    map['mount_path'] = Variable<String>(mountPath);
    map['source_path'] = Variable<String>(sourcePath);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      userId: Value(userId),
      serialNumber: Value(serialNumber),
      mountPath: Value(mountPath),
      sourcePath: Value(sourcePath),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      serialNumber: serializer.fromJson<String>(json['serialNumber']),
      mountPath: serializer.fromJson<String>(json['mountPath']),
      sourcePath: serializer.fromJson<String>(json['sourcePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'serialNumber': serializer.toJson<String>(serialNumber),
      'mountPath': serializer.toJson<String>(mountPath),
      'sourcePath': serializer.toJson<String>(sourcePath),
    };
  }

  Device copyWith({
    int? id,
    int? userId,
    String? serialNumber,
    String? mountPath,
    String? sourcePath,
  }) => Device(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    serialNumber: serialNumber ?? this.serialNumber,
    mountPath: mountPath ?? this.mountPath,
    sourcePath: sourcePath ?? this.sourcePath,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      mountPath: data.mountPath.present ? data.mountPath.value : this.mountPath,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('mountPath: $mountPath, ')
          ..write('sourcePath: $sourcePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, serialNumber, mountPath, sourcePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.serialNumber == this.serialNumber &&
          other.mountPath == this.mountPath &&
          other.sourcePath == this.sourcePath);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> serialNumber;
  final Value<String> mountPath;
  final Value<String> sourcePath;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.mountPath = const Value.absent(),
    this.sourcePath = const Value.absent(),
  });
  DevicesCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String serialNumber,
    required String mountPath,
    required String sourcePath,
  }) : userId = Value(userId),
       serialNumber = Value(serialNumber),
       mountPath = Value(mountPath),
       sourcePath = Value(sourcePath);
  static Insertable<Device> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? serialNumber,
    Expression<String>? mountPath,
    Expression<String>? sourcePath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (mountPath != null) 'mount_path': mountPath,
      if (sourcePath != null) 'source_path': sourcePath,
    });
  }

  DevicesCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? serialNumber,
    Value<String>? mountPath,
    Value<String>? sourcePath,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serialNumber: serialNumber ?? this.serialNumber,
      mountPath: mountPath ?? this.mountPath,
      sourcePath: sourcePath ?? this.sourcePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (mountPath.present) {
      map['mount_path'] = Variable<String>(mountPath.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('mountPath: $mountPath, ')
          ..write('sourcePath: $sourcePath')
          ..write(')'))
        .toString();
  }
}

class $RabbisTable extends Rabbis with TableInfo<$RabbisTable, Rabbi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RabbisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _targetPathMeta = const VerificationMeta(
    'targetPath',
  );
  @override
  late final GeneratedColumn<String> targetPath = GeneratedColumn<String>(
    'target_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, targetPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rabbis';
  @override
  VerificationContext validateIntegrity(
    Insertable<Rabbi> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_path')) {
      context.handle(
        _targetPathMeta,
        targetPath.isAcceptableOrUnknown(data['target_path']!, _targetPathMeta),
      );
    } else if (isInserting) {
      context.missing(_targetPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Rabbi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rabbi(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_path'],
      )!,
    );
  }

  @override
  $RabbisTable createAlias(String alias) {
    return $RabbisTable(attachedDatabase, alias);
  }
}

class Rabbi extends DataClass implements Insertable<Rabbi> {
  final int id;
  final String name;
  final String targetPath;
  const Rabbi({required this.id, required this.name, required this.targetPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['target_path'] = Variable<String>(targetPath);
    return map;
  }

  RabbisCompanion toCompanion(bool nullToAbsent) {
    return RabbisCompanion(
      id: Value(id),
      name: Value(name),
      targetPath: Value(targetPath),
    );
  }

  factory Rabbi.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rabbi(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetPath: serializer.fromJson<String>(json['targetPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'targetPath': serializer.toJson<String>(targetPath),
    };
  }

  Rabbi copyWith({int? id, String? name, String? targetPath}) => Rabbi(
    id: id ?? this.id,
    name: name ?? this.name,
    targetPath: targetPath ?? this.targetPath,
  );
  Rabbi copyWithCompanion(RabbisCompanion data) {
    return Rabbi(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetPath: data.targetPath.present
          ? data.targetPath.value
          : this.targetPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Rabbi(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetPath: $targetPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, targetPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rabbi &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetPath == this.targetPath);
}

class RabbisCompanion extends UpdateCompanion<Rabbi> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> targetPath;
  const RabbisCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetPath = const Value.absent(),
  });
  RabbisCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String targetPath,
  }) : name = Value(name),
       targetPath = Value(targetPath);
  static Insertable<Rabbi> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? targetPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetPath != null) 'target_path': targetPath,
    });
  }

  RabbisCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? targetPath,
  }) {
    return RabbisCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetPath: targetPath ?? this.targetPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetPath.present) {
      map['target_path'] = Variable<String>(targetPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RabbisCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetPath: $targetPath')
          ..write(')'))
        .toString();
  }
}

class $UserRabbiPermissionsTable extends UserRabbiPermissions
    with TableInfo<$UserRabbiPermissionsTable, UserRabbiPermission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRabbiPermissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _rabbiIdMeta = const VerificationMeta(
    'rabbiId',
  );
  @override
  late final GeneratedColumn<int> rabbiId = GeneratedColumn<int>(
    'rabbi_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rabbis (id)',
    ),
  );
  static const VerificationMeta _specificPathMeta = const VerificationMeta(
    'specificPath',
  );
  @override
  late final GeneratedColumn<String> specificPath = GeneratedColumn<String>(
    'specific_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, rabbiId, specificPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_rabbi_permissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRabbiPermission> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('rabbi_id')) {
      context.handle(
        _rabbiIdMeta,
        rabbiId.isAcceptableOrUnknown(data['rabbi_id']!, _rabbiIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rabbiIdMeta);
    }
    if (data.containsKey('specific_path')) {
      context.handle(
        _specificPathMeta,
        specificPath.isAcceptableOrUnknown(
          data['specific_path']!,
          _specificPathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, rabbiId};
  @override
  UserRabbiPermission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRabbiPermission(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      rabbiId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rabbi_id'],
      )!,
      specificPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specific_path'],
      ),
    );
  }

  @override
  $UserRabbiPermissionsTable createAlias(String alias) {
    return $UserRabbiPermissionsTable(attachedDatabase, alias);
  }
}

class UserRabbiPermission extends DataClass
    implements Insertable<UserRabbiPermission> {
  final int userId;
  final int rabbiId;
  final String? specificPath;
  const UserRabbiPermission({
    required this.userId,
    required this.rabbiId,
    this.specificPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['rabbi_id'] = Variable<int>(rabbiId);
    if (!nullToAbsent || specificPath != null) {
      map['specific_path'] = Variable<String>(specificPath);
    }
    return map;
  }

  UserRabbiPermissionsCompanion toCompanion(bool nullToAbsent) {
    return UserRabbiPermissionsCompanion(
      userId: Value(userId),
      rabbiId: Value(rabbiId),
      specificPath: specificPath == null && nullToAbsent
          ? const Value.absent()
          : Value(specificPath),
    );
  }

  factory UserRabbiPermission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRabbiPermission(
      userId: serializer.fromJson<int>(json['userId']),
      rabbiId: serializer.fromJson<int>(json['rabbiId']),
      specificPath: serializer.fromJson<String?>(json['specificPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'rabbiId': serializer.toJson<int>(rabbiId),
      'specificPath': serializer.toJson<String?>(specificPath),
    };
  }

  UserRabbiPermission copyWith({
    int? userId,
    int? rabbiId,
    Value<String?> specificPath = const Value.absent(),
  }) => UserRabbiPermission(
    userId: userId ?? this.userId,
    rabbiId: rabbiId ?? this.rabbiId,
    specificPath: specificPath.present ? specificPath.value : this.specificPath,
  );
  UserRabbiPermission copyWithCompanion(UserRabbiPermissionsCompanion data) {
    return UserRabbiPermission(
      userId: data.userId.present ? data.userId.value : this.userId,
      rabbiId: data.rabbiId.present ? data.rabbiId.value : this.rabbiId,
      specificPath: data.specificPath.present
          ? data.specificPath.value
          : this.specificPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRabbiPermission(')
          ..write('userId: $userId, ')
          ..write('rabbiId: $rabbiId, ')
          ..write('specificPath: $specificPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, rabbiId, specificPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRabbiPermission &&
          other.userId == this.userId &&
          other.rabbiId == this.rabbiId &&
          other.specificPath == this.specificPath);
}

class UserRabbiPermissionsCompanion
    extends UpdateCompanion<UserRabbiPermission> {
  final Value<int> userId;
  final Value<int> rabbiId;
  final Value<String?> specificPath;
  final Value<int> rowid;
  const UserRabbiPermissionsCompanion({
    this.userId = const Value.absent(),
    this.rabbiId = const Value.absent(),
    this.specificPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserRabbiPermissionsCompanion.insert({
    required int userId,
    required int rabbiId,
    this.specificPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       rabbiId = Value(rabbiId);
  static Insertable<UserRabbiPermission> custom({
    Expression<int>? userId,
    Expression<int>? rabbiId,
    Expression<String>? specificPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (rabbiId != null) 'rabbi_id': rabbiId,
      if (specificPath != null) 'specific_path': specificPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserRabbiPermissionsCompanion copyWith({
    Value<int>? userId,
    Value<int>? rabbiId,
    Value<String?>? specificPath,
    Value<int>? rowid,
  }) {
    return UserRabbiPermissionsCompanion(
      userId: userId ?? this.userId,
      rabbiId: rabbiId ?? this.rabbiId,
      specificPath: specificPath ?? this.specificPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (rabbiId.present) {
      map['rabbi_id'] = Variable<int>(rabbiId.value);
    }
    if (specificPath.present) {
      map['specific_path'] = Variable<String>(specificPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserRabbiPermissionsCompanion(')
          ..write('userId: $userId, ')
          ..write('rabbiId: $rabbiId, ')
          ..write('specificPath: $specificPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, Transfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _sourceFileMeta = const VerificationMeta(
    'sourceFile',
  );
  @override
  late final GeneratedColumn<String> sourceFile = GeneratedColumn<String>(
    'source_file',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationFileMeta = const VerificationMeta(
    'destinationFile',
  );
  @override
  late final GeneratedColumn<String> destinationFile = GeneratedColumn<String>(
    'destination_file',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    sourceFile,
    destinationFile,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('source_file')) {
      context.handle(
        _sourceFileMeta,
        sourceFile.isAcceptableOrUnknown(data['source_file']!, _sourceFileMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceFileMeta);
    }
    if (data.containsKey('destination_file')) {
      context.handle(
        _destinationFileMeta,
        destinationFile.isAcceptableOrUnknown(
          data['destination_file']!,
          _destinationFileMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationFileMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      sourceFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_file'],
      )!,
      destinationFile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_file'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }
}

class Transfer extends DataClass implements Insertable<Transfer> {
  final int id;
  final int userId;
  final String sourceFile;
  final String destinationFile;
  final DateTime timestamp;
  const Transfer({
    required this.id,
    required this.userId,
    required this.sourceFile,
    required this.destinationFile,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['source_file'] = Variable<String>(sourceFile);
    map['destination_file'] = Variable<String>(destinationFile);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      id: Value(id),
      userId: Value(userId),
      sourceFile: Value(sourceFile),
      destinationFile: Value(destinationFile),
      timestamp: Value(timestamp),
    );
  }

  factory Transfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transfer(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      sourceFile: serializer.fromJson<String>(json['sourceFile']),
      destinationFile: serializer.fromJson<String>(json['destinationFile']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'sourceFile': serializer.toJson<String>(sourceFile),
      'destinationFile': serializer.toJson<String>(destinationFile),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  Transfer copyWith({
    int? id,
    int? userId,
    String? sourceFile,
    String? destinationFile,
    DateTime? timestamp,
  }) => Transfer(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    sourceFile: sourceFile ?? this.sourceFile,
    destinationFile: destinationFile ?? this.destinationFile,
    timestamp: timestamp ?? this.timestamp,
  );
  Transfer copyWithCompanion(TransfersCompanion data) {
    return Transfer(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      sourceFile: data.sourceFile.present
          ? data.sourceFile.value
          : this.sourceFile,
      destinationFile: data.destinationFile.present
          ? data.destinationFile.value
          : this.destinationFile,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transfer(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('sourceFile: $sourceFile, ')
          ..write('destinationFile: $destinationFile, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, sourceFile, destinationFile, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transfer &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.sourceFile == this.sourceFile &&
          other.destinationFile == this.destinationFile &&
          other.timestamp == this.timestamp);
}

class TransfersCompanion extends UpdateCompanion<Transfer> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> sourceFile;
  final Value<String> destinationFile;
  final Value<DateTime> timestamp;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.sourceFile = const Value.absent(),
    this.destinationFile = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  TransfersCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String sourceFile,
    required String destinationFile,
    required DateTime timestamp,
  }) : userId = Value(userId),
       sourceFile = Value(sourceFile),
       destinationFile = Value(destinationFile),
       timestamp = Value(timestamp);
  static Insertable<Transfer> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? sourceFile,
    Expression<String>? destinationFile,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (sourceFile != null) 'source_file': sourceFile,
      if (destinationFile != null) 'destination_file': destinationFile,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  TransfersCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<String>? sourceFile,
    Value<String>? destinationFile,
    Value<DateTime>? timestamp,
  }) {
    return TransfersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sourceFile: sourceFile ?? this.sourceFile,
      destinationFile: destinationFile ?? this.destinationFile,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (sourceFile.present) {
      map['source_file'] = Variable<String>(sourceFile.value);
    }
    if (destinationFile.present) {
      map['destination_file'] = Variable<String>(destinationFile.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransfersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('sourceFile: $sourceFile, ')
          ..write('destinationFile: $destinationFile, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _convertToMp3Meta = const VerificationMeta(
    'convertToMp3',
  );
  @override
  late final GeneratedColumn<bool> convertToMp3 = GeneratedColumn<bool>(
    'convert_to_mp3',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("convert_to_mp3" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mp3BitrateMeta = const VerificationMeta(
    'mp3Bitrate',
  );
  @override
  late final GeneratedColumn<int> mp3Bitrate = GeneratedColumn<int>(
    'mp3_bitrate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(128),
  );
  @override
  List<GeneratedColumn> get $columns => [id, convertToMp3, mp3Bitrate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('convert_to_mp3')) {
      context.handle(
        _convertToMp3Meta,
        convertToMp3.isAcceptableOrUnknown(
          data['convert_to_mp3']!,
          _convertToMp3Meta,
        ),
      );
    }
    if (data.containsKey('mp3_bitrate')) {
      context.handle(
        _mp3BitrateMeta,
        mp3Bitrate.isAcceptableOrUnknown(data['mp3_bitrate']!, _mp3BitrateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      convertToMp3: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}convert_to_mp3'],
      )!,
      mp3Bitrate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mp3_bitrate'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final bool convertToMp3;
  final int mp3Bitrate;
  const AppSetting({
    required this.id,
    required this.convertToMp3,
    required this.mp3Bitrate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['convert_to_mp3'] = Variable<bool>(convertToMp3);
    map['mp3_bitrate'] = Variable<int>(mp3Bitrate);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      convertToMp3: Value(convertToMp3),
      mp3Bitrate: Value(mp3Bitrate),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      convertToMp3: serializer.fromJson<bool>(json['convertToMp3']),
      mp3Bitrate: serializer.fromJson<int>(json['mp3Bitrate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'convertToMp3': serializer.toJson<bool>(convertToMp3),
      'mp3Bitrate': serializer.toJson<int>(mp3Bitrate),
    };
  }

  AppSetting copyWith({int? id, bool? convertToMp3, int? mp3Bitrate}) =>
      AppSetting(
        id: id ?? this.id,
        convertToMp3: convertToMp3 ?? this.convertToMp3,
        mp3Bitrate: mp3Bitrate ?? this.mp3Bitrate,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      convertToMp3: data.convertToMp3.present
          ? data.convertToMp3.value
          : this.convertToMp3,
      mp3Bitrate: data.mp3Bitrate.present
          ? data.mp3Bitrate.value
          : this.mp3Bitrate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('convertToMp3: $convertToMp3, ')
          ..write('mp3Bitrate: $mp3Bitrate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, convertToMp3, mp3Bitrate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.convertToMp3 == this.convertToMp3 &&
          other.mp3Bitrate == this.mp3Bitrate);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<bool> convertToMp3;
  final Value<int> mp3Bitrate;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.convertToMp3 = const Value.absent(),
    this.mp3Bitrate = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.convertToMp3 = const Value.absent(),
    this.mp3Bitrate = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<bool>? convertToMp3,
    Expression<int>? mp3Bitrate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (convertToMp3 != null) 'convert_to_mp3': convertToMp3,
      if (mp3Bitrate != null) 'mp3_bitrate': mp3Bitrate,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<bool>? convertToMp3,
    Value<int>? mp3Bitrate,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      convertToMp3: convertToMp3 ?? this.convertToMp3,
      mp3Bitrate: mp3Bitrate ?? this.mp3Bitrate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (convertToMp3.present) {
      map['convert_to_mp3'] = Variable<bool>(convertToMp3.value);
    }
    if (mp3Bitrate.present) {
      map['mp3_bitrate'] = Variable<int>(mp3Bitrate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('convertToMp3: $convertToMp3, ')
          ..write('mp3Bitrate: $mp3Bitrate')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $RabbisTable rabbis = $RabbisTable(this);
  late final $UserRabbiPermissionsTable userRabbiPermissions =
      $UserRabbiPermissionsTable(this);
  late final $TransfersTable transfers = $TransfersTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    devices,
    rabbis,
    userRabbiPermissions,
    transfers,
    appSettings,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> additionalInfo,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> additionalInfo,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DevicesTable, List<Device>> _devicesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.devices,
    aliasName: $_aliasNameGenerator(db.users.id, db.devices.userId),
  );

  $$DevicesTableProcessedTableManager get devicesRefs {
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_devicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $UserRabbiPermissionsTable,
    List<UserRabbiPermission>
  >
  _userRabbiPermissionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userRabbiPermissions,
        aliasName: $_aliasNameGenerator(
          db.users.id,
          db.userRabbiPermissions.userId,
        ),
      );

  $$UserRabbiPermissionsTableProcessedTableManager
  get userRabbiPermissionsRefs {
    final manager = $$UserRabbiPermissionsTableTableManager(
      $_db,
      $_db.userRabbiPermissions,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userRabbiPermissionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransfersTable, List<Transfer>>
  _transfersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transfers,
    aliasName: $_aliasNameGenerator(db.users.id, db.transfers.userId),
  );

  $$TransfersTableProcessedTableManager get transfersRefs {
    final manager = $$TransfersTableTableManager(
      $_db,
      $_db.transfers,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transfersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get additionalInfo => $composableBuilder(
    column: $table.additionalInfo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> devicesRefs(
    Expression<bool> Function($$DevicesTableFilterComposer f) f,
  ) {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userRabbiPermissionsRefs(
    Expression<bool> Function($$UserRabbiPermissionsTableFilterComposer f) f,
  ) {
    final $$UserRabbiPermissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userRabbiPermissions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserRabbiPermissionsTableFilterComposer(
            $db: $db,
            $table: $db.userRabbiPermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transfersRefs(
    Expression<bool> Function($$TransfersTableFilterComposer f) f,
  ) {
    final $$TransfersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transfers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransfersTableFilterComposer(
            $db: $db,
            $table: $db.transfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get additionalInfo => $composableBuilder(
    column: $table.additionalInfo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get additionalInfo => $composableBuilder(
    column: $table.additionalInfo,
    builder: (column) => column,
  );

  Expression<T> devicesRefs<T extends Object>(
    Expression<T> Function($$DevicesTableAnnotationComposer a) f,
  ) {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userRabbiPermissionsRefs<T extends Object>(
    Expression<T> Function($$UserRabbiPermissionsTableAnnotationComposer a) f,
  ) {
    final $$UserRabbiPermissionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userRabbiPermissions,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserRabbiPermissionsTableAnnotationComposer(
                $db: $db,
                $table: $db.userRabbiPermissions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> transfersRefs<T extends Object>(
    Expression<T> Function($$TransfersTableAnnotationComposer a) f,
  ) {
    final $$TransfersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transfers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransfersTableAnnotationComposer(
            $db: $db,
            $table: $db.transfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, $$UsersTableReferences),
          User,
          PrefetchHooks Function({
            bool devicesRefs,
            bool userRabbiPermissionsRefs,
            bool transfersRefs,
          })
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> additionalInfo = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                additionalInfo: additionalInfo,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> additionalInfo = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                additionalInfo: additionalInfo,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                devicesRefs = false,
                userRabbiPermissionsRefs = false,
                transfersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (devicesRefs) db.devices,
                    if (userRabbiPermissionsRefs) db.userRabbiPermissions,
                    if (transfersRefs) db.transfers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (devicesRefs)
                        await $_getPrefetchedData<User, $UsersTable, Device>(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._devicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(db, table, p0).devicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userRabbiPermissionsRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          UserRabbiPermission
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._userRabbiPermissionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).userRabbiPermissionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transfersRefs)
                        await $_getPrefetchedData<User, $UsersTable, Transfer>(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._transfersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).transfersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, $$UsersTableReferences),
      User,
      PrefetchHooks Function({
        bool devicesRefs,
        bool userRabbiPermissionsRefs,
        bool transfersRefs,
      })
    >;
typedef $$DevicesTableCreateCompanionBuilder =
    DevicesCompanion Function({
      Value<int> id,
      required int userId,
      required String serialNumber,
      required String mountPath,
      required String sourcePath,
    });
typedef $$DevicesTableUpdateCompanionBuilder =
    DevicesCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> serialNumber,
      Value<String> mountPath,
      Value<String> sourcePath,
    });

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, Device> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.devices.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mountPath => $composableBuilder(
    column: $table.mountPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mountPath => $composableBuilder(
    column: $table.mountPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mountPath =>
      $composableBuilder(column: $table.mountPath, builder: (column) => column);

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, $$DevicesTableReferences),
          Device,
          PrefetchHooks Function({bool userId})
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> serialNumber = const Value.absent(),
                Value<String> mountPath = const Value.absent(),
                Value<String> sourcePath = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                userId: userId,
                serialNumber: serialNumber,
                mountPath: mountPath,
                sourcePath: sourcePath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String serialNumber,
                required String mountPath,
                required String sourcePath,
              }) => DevicesCompanion.insert(
                id: id,
                userId: userId,
                serialNumber: serialNumber,
                mountPath: mountPath,
                sourcePath: sourcePath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$DevicesTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$DevicesTableReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, $$DevicesTableReferences),
      Device,
      PrefetchHooks Function({bool userId})
    >;
typedef $$RabbisTableCreateCompanionBuilder =
    RabbisCompanion Function({
      Value<int> id,
      required String name,
      required String targetPath,
    });
typedef $$RabbisTableUpdateCompanionBuilder =
    RabbisCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> targetPath,
    });

final class $$RabbisTableReferences
    extends BaseReferences<_$AppDatabase, $RabbisTable, Rabbi> {
  $$RabbisTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $UserRabbiPermissionsTable,
    List<UserRabbiPermission>
  >
  _userRabbiPermissionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.userRabbiPermissions,
        aliasName: $_aliasNameGenerator(
          db.rabbis.id,
          db.userRabbiPermissions.rabbiId,
        ),
      );

  $$UserRabbiPermissionsTableProcessedTableManager
  get userRabbiPermissionsRefs {
    final manager = $$UserRabbiPermissionsTableTableManager(
      $_db,
      $_db.userRabbiPermissions,
    ).filter((f) => f.rabbiId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userRabbiPermissionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RabbisTableFilterComposer
    extends Composer<_$AppDatabase, $RabbisTable> {
  $$RabbisTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetPath => $composableBuilder(
    column: $table.targetPath,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userRabbiPermissionsRefs(
    Expression<bool> Function($$UserRabbiPermissionsTableFilterComposer f) f,
  ) {
    final $$UserRabbiPermissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userRabbiPermissions,
      getReferencedColumn: (t) => t.rabbiId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserRabbiPermissionsTableFilterComposer(
            $db: $db,
            $table: $db.userRabbiPermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RabbisTableOrderingComposer
    extends Composer<_$AppDatabase, $RabbisTable> {
  $$RabbisTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetPath => $composableBuilder(
    column: $table.targetPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RabbisTableAnnotationComposer
    extends Composer<_$AppDatabase, $RabbisTable> {
  $$RabbisTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get targetPath => $composableBuilder(
    column: $table.targetPath,
    builder: (column) => column,
  );

  Expression<T> userRabbiPermissionsRefs<T extends Object>(
    Expression<T> Function($$UserRabbiPermissionsTableAnnotationComposer a) f,
  ) {
    final $$UserRabbiPermissionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.userRabbiPermissions,
          getReferencedColumn: (t) => t.rabbiId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$UserRabbiPermissionsTableAnnotationComposer(
                $db: $db,
                $table: $db.userRabbiPermissions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RabbisTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RabbisTable,
          Rabbi,
          $$RabbisTableFilterComposer,
          $$RabbisTableOrderingComposer,
          $$RabbisTableAnnotationComposer,
          $$RabbisTableCreateCompanionBuilder,
          $$RabbisTableUpdateCompanionBuilder,
          (Rabbi, $$RabbisTableReferences),
          Rabbi,
          PrefetchHooks Function({bool userRabbiPermissionsRefs})
        > {
  $$RabbisTableTableManager(_$AppDatabase db, $RabbisTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RabbisTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RabbisTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RabbisTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> targetPath = const Value.absent(),
              }) => RabbisCompanion(id: id, name: name, targetPath: targetPath),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String targetPath,
              }) => RabbisCompanion.insert(
                id: id,
                name: name,
                targetPath: targetPath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RabbisTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({userRabbiPermissionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userRabbiPermissionsRefs) db.userRabbiPermissions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userRabbiPermissionsRefs)
                    await $_getPrefetchedData<
                      Rabbi,
                      $RabbisTable,
                      UserRabbiPermission
                    >(
                      currentTable: table,
                      referencedTable: $$RabbisTableReferences
                          ._userRabbiPermissionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RabbisTableReferences(
                        db,
                        table,
                        p0,
                      ).userRabbiPermissionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.rabbiId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RabbisTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RabbisTable,
      Rabbi,
      $$RabbisTableFilterComposer,
      $$RabbisTableOrderingComposer,
      $$RabbisTableAnnotationComposer,
      $$RabbisTableCreateCompanionBuilder,
      $$RabbisTableUpdateCompanionBuilder,
      (Rabbi, $$RabbisTableReferences),
      Rabbi,
      PrefetchHooks Function({bool userRabbiPermissionsRefs})
    >;
typedef $$UserRabbiPermissionsTableCreateCompanionBuilder =
    UserRabbiPermissionsCompanion Function({
      required int userId,
      required int rabbiId,
      Value<String?> specificPath,
      Value<int> rowid,
    });
typedef $$UserRabbiPermissionsTableUpdateCompanionBuilder =
    UserRabbiPermissionsCompanion Function({
      Value<int> userId,
      Value<int> rabbiId,
      Value<String?> specificPath,
      Value<int> rowid,
    });

final class $$UserRabbiPermissionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $UserRabbiPermissionsTable,
          UserRabbiPermission
        > {
  $$UserRabbiPermissionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.userRabbiPermissions.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RabbisTable _rabbiIdTable(_$AppDatabase db) => db.rabbis.createAlias(
    $_aliasNameGenerator(db.userRabbiPermissions.rabbiId, db.rabbis.id),
  );

  $$RabbisTableProcessedTableManager get rabbiId {
    final $_column = $_itemColumn<int>('rabbi_id')!;

    final manager = $$RabbisTableTableManager(
      $_db,
      $_db.rabbis,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rabbiIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserRabbiPermissionsTableFilterComposer
    extends Composer<_$AppDatabase, $UserRabbiPermissionsTable> {
  $$UserRabbiPermissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get specificPath => $composableBuilder(
    column: $table.specificPath,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RabbisTableFilterComposer get rabbiId {
    final $$RabbisTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rabbiId,
      referencedTable: $db.rabbis,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RabbisTableFilterComposer(
            $db: $db,
            $table: $db.rabbis,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserRabbiPermissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserRabbiPermissionsTable> {
  $$UserRabbiPermissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get specificPath => $composableBuilder(
    column: $table.specificPath,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RabbisTableOrderingComposer get rabbiId {
    final $$RabbisTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rabbiId,
      referencedTable: $db.rabbis,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RabbisTableOrderingComposer(
            $db: $db,
            $table: $db.rabbis,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserRabbiPermissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserRabbiPermissionsTable> {
  $$UserRabbiPermissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get specificPath => $composableBuilder(
    column: $table.specificPath,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RabbisTableAnnotationComposer get rabbiId {
    final $$RabbisTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rabbiId,
      referencedTable: $db.rabbis,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RabbisTableAnnotationComposer(
            $db: $db,
            $table: $db.rabbis,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserRabbiPermissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserRabbiPermissionsTable,
          UserRabbiPermission,
          $$UserRabbiPermissionsTableFilterComposer,
          $$UserRabbiPermissionsTableOrderingComposer,
          $$UserRabbiPermissionsTableAnnotationComposer,
          $$UserRabbiPermissionsTableCreateCompanionBuilder,
          $$UserRabbiPermissionsTableUpdateCompanionBuilder,
          (UserRabbiPermission, $$UserRabbiPermissionsTableReferences),
          UserRabbiPermission,
          PrefetchHooks Function({bool userId, bool rabbiId})
        > {
  $$UserRabbiPermissionsTableTableManager(
    _$AppDatabase db,
    $UserRabbiPermissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRabbiPermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRabbiPermissionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserRabbiPermissionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<int> rabbiId = const Value.absent(),
                Value<String?> specificPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserRabbiPermissionsCompanion(
                userId: userId,
                rabbiId: rabbiId,
                specificPath: specificPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int userId,
                required int rabbiId,
                Value<String?> specificPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserRabbiPermissionsCompanion.insert(
                userId: userId,
                rabbiId: rabbiId,
                specificPath: specificPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserRabbiPermissionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false, rabbiId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$UserRabbiPermissionsTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$UserRabbiPermissionsTableReferences
                                        ._userIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (rabbiId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.rabbiId,
                                referencedTable:
                                    $$UserRabbiPermissionsTableReferences
                                        ._rabbiIdTable(db),
                                referencedColumn:
                                    $$UserRabbiPermissionsTableReferences
                                        ._rabbiIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserRabbiPermissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserRabbiPermissionsTable,
      UserRabbiPermission,
      $$UserRabbiPermissionsTableFilterComposer,
      $$UserRabbiPermissionsTableOrderingComposer,
      $$UserRabbiPermissionsTableAnnotationComposer,
      $$UserRabbiPermissionsTableCreateCompanionBuilder,
      $$UserRabbiPermissionsTableUpdateCompanionBuilder,
      (UserRabbiPermission, $$UserRabbiPermissionsTableReferences),
      UserRabbiPermission,
      PrefetchHooks Function({bool userId, bool rabbiId})
    >;
typedef $$TransfersTableCreateCompanionBuilder =
    TransfersCompanion Function({
      Value<int> id,
      required int userId,
      required String sourceFile,
      required String destinationFile,
      required DateTime timestamp,
    });
typedef $$TransfersTableUpdateCompanionBuilder =
    TransfersCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<String> sourceFile,
      Value<String> destinationFile,
      Value<DateTime> timestamp,
    });

final class $$TransfersTableReferences
    extends BaseReferences<_$AppDatabase, $TransfersTable, Transfer> {
  $$TransfersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.transfers.userId, db.users.id),
  );

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransfersTableFilterComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFile => $composableBuilder(
    column: $table.sourceFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationFile => $composableBuilder(
    column: $table.destinationFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFile => $composableBuilder(
    column: $table.sourceFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationFile => $composableBuilder(
    column: $table.destinationFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceFile => $composableBuilder(
    column: $table.sourceFile,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationFile => $composableBuilder(
    column: $table.destinationFile,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransfersTable,
          Transfer,
          $$TransfersTableFilterComposer,
          $$TransfersTableOrderingComposer,
          $$TransfersTableAnnotationComposer,
          $$TransfersTableCreateCompanionBuilder,
          $$TransfersTableUpdateCompanionBuilder,
          (Transfer, $$TransfersTableReferences),
          Transfer,
          PrefetchHooks Function({bool userId})
        > {
  $$TransfersTableTableManager(_$AppDatabase db, $TransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> sourceFile = const Value.absent(),
                Value<String> destinationFile = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => TransfersCompanion(
                id: id,
                userId: userId,
                sourceFile: sourceFile,
                destinationFile: destinationFile,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required String sourceFile,
                required String destinationFile,
                required DateTime timestamp,
              }) => TransfersCompanion.insert(
                id: id,
                userId: userId,
                sourceFile: sourceFile,
                destinationFile: destinationFile,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransfersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$TransfersTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$TransfersTableReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransfersTable,
      Transfer,
      $$TransfersTableFilterComposer,
      $$TransfersTableOrderingComposer,
      $$TransfersTableAnnotationComposer,
      $$TransfersTableCreateCompanionBuilder,
      $$TransfersTableUpdateCompanionBuilder,
      (Transfer, $$TransfersTableReferences),
      Transfer,
      PrefetchHooks Function({bool userId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> convertToMp3,
      Value<int> mp3Bitrate,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<bool> convertToMp3,
      Value<int> mp3Bitrate,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get convertToMp3 => $composableBuilder(
    column: $table.convertToMp3,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mp3Bitrate => $composableBuilder(
    column: $table.mp3Bitrate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get convertToMp3 => $composableBuilder(
    column: $table.convertToMp3,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mp3Bitrate => $composableBuilder(
    column: $table.mp3Bitrate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get convertToMp3 => $composableBuilder(
    column: $table.convertToMp3,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mp3Bitrate => $composableBuilder(
    column: $table.mp3Bitrate,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> convertToMp3 = const Value.absent(),
                Value<int> mp3Bitrate = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                convertToMp3: convertToMp3,
                mp3Bitrate: mp3Bitrate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> convertToMp3 = const Value.absent(),
                Value<int> mp3Bitrate = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                convertToMp3: convertToMp3,
                mp3Bitrate: mp3Bitrate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$RabbisTableTableManager get rabbis =>
      $$RabbisTableTableManager(_db, _db.rabbis);
  $$UserRabbiPermissionsTableTableManager get userRabbiPermissions =>
      $$UserRabbiPermissionsTableTableManager(_db, _db.userRabbiPermissions);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
