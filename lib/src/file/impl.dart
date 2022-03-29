import 'dart:typed_data';

import 'file.dart';

class PreferenceFileImpl implements PreferencesFile {
  factory PreferenceFileImpl({
    required String name,
    String? homePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> readBytes() {
    throw UnimplementedError();
  }

  @override
  Future<void> writeBytes(Uint8List bytes) {
    throw UnimplementedError();
  }
}
