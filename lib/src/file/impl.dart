import 'dart:typed_data';

import 'file.dart';

class PreferencesFileImpl implements PreferencesFile {
  factory PreferencesFileImpl({
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
