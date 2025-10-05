part of 'database.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 50)();

  TextColumn get additionalInfo => text().nullable()();
}

class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();

  TextColumn get serialNumber => text().unique()();
  TextColumn get sourcePath => text()();
}

class Rabbis extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();

  TextColumn get targetPath => text()();
}

@DataClassName('UserRabbiPermission')
class UserRabbiPermissions extends Table {
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get rabbiId => integer().references(Rabbis, #id)();
  TextColumn get specificPath => text().nullable()();

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

@DataClassName('AppSetting')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get convertToMp3 => boolean().withDefault(const Constant(false))();
  IntColumn get mp3Bitrate => integer().withDefault(const Constant(128))();

  @override
  Set<Column> get primaryKey => {id};
}