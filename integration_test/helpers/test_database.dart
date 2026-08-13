import 'package:drift/native.dart';
import 'package:pluma/core/database/app_database.dart';

/// Creates an in-memory AppDatabase for integration tests.
///
/// Using an in-memory database (not a temp file) means tests are fully
/// isolated:
/// no cleanup needed, no file locking between test runs.
///
/// For the "write → close → reopen → data persists" integration test, use
/// `createFileDatabaseAt` with a deterministic temp path instead.
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
