import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 50)();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
}

class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get serialNumber => text().unique()(); // In our mock, this will be the drive path
  TextColumn get sourcePath => text()(); // e.g., 'records'
  TextColumn get mountPath => text()(); // e.g., 'E:\' - the actual root of the drive
}

class Rabbis extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get targetPath => text()(); // e.g., 'C:\Shiurim\RabbiCohen'
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