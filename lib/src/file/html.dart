import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

import 'file.dart';

const _prefix = 'flutter_preferences/';

class PreferencesFileImpl implements PreferencesFile {
  PreferencesFileImpl._(this._key);

  factory PreferencesFileImpl({
    required String name,
    String? homePath,
  }) {
    return PreferencesFileImpl._('$_prefix$name');
  }

  final String _key;

  @override
  Future<Uint8List?> readBytes() {
    final string = html.window.localStorage[_key];
    Uint8List? bytes;
    if (string != null) {
      bytes = base64.decoder.convert(string);
    }
    return Future.value(bytes);
  }

  @override
  Future<void> writeBytes(Uint8List bytes) {
    html.window.localStorage[_key] = base64.encoder.convert(bytes);
    return Future.value();
  }
}
