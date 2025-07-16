part of 'database.dart';

// NOTE: No imports here, this is a part file.

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 50)();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
}

class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  // This now stores the REAL hardware/volume serial number.
  TextColumn get serialNumber => text().unique()();
  // This is the RELATIVE source path on the device, e.g., "records/" or "voice/".
  TextColumn get sourcePath => text()();
  // REMOVED: mountPath was removed as it's transient and detected at runtime.
}

class Rabbis extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  // This is the absolute target path on the local machine.
  TextColumn get targetPath => text()();
}

@DataClassName('UserRabbiPermission')
class UserRabbiPermissions extends Table {
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get rabbiId => integer().references(Rabbis, #id)();
  @override
  Set<Column> get primaryKey => {userId, rabbiId};
}

class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get sourceFile => text()();
  TextColumn get destinationFile => text()();
  DateTimeColumn get timestamp => dateTime()();
}