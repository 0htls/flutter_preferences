import 'dart:typed_data';

import 'impl.dart'
    if (dart.library.io) 'io.dart'
    if (dart.library.html) 'html.dart';

abstract class PreferencesFile {
  factory PreferencesFile({
    required String name,
    String? homePath,
  }) = PreferenceFileImpl;

  Future<Uint8List?> readBytes();

  Future<void> writeBytes(Uint8List bytes);
}
