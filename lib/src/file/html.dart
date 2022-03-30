import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

import 'file.dart';

const _prefix = 'flutter_preferences';

class PreferencesFileImpl implements PreferencesFile {
  PreferencesFileImpl._(this._prefsKey);

  factory PreferencesFileImpl({
    required String name,
    String? homePath,
  }) {
    final key = '$_prefix.$name';
    return PreferencesFileImpl._(key);
  }

  final String _prefsKey;

  @override
  Future<Uint8List?> readBytes() {
    final string = html.window.localStorage[_prefsKey];
    Uint8List? bytes;
    if (string != null) {
      bytes = base64.decoder.convert(string);
    }
    return Future.value(bytes);
  }

  @override
  Future<void> writeBytes(Uint8List bytes) {
    html.window.localStorage[_prefsKey] = base64.encoder.convert(bytes);
    return Future.value();
  }
}
