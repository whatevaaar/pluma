import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app's marketing version prefixed with `v` (e.g. `v0.1.42`).
///
/// Read from the platform bundle metadata (Info.plist / AndroidManifest) via
/// [PackageInfo], which Flutter populates from `--build-name`. CI ships each
/// build with `--build-name=0.1.$BUILD_NUMBER`, so this always reflects the
/// actual shipped version instead of a hardcoded literal.
///
/// Overridable in tests via `overrideWith`.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});
