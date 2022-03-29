import 'dart:async';

import 'package:flutter/services.dart';

import 'file/file.dart';
import 'codec.dart';

typedef PreferencesMap = Map<String, Object?>;

typedef Edit = FutureOr<void> Function(PreferencesEditor editor);

class PreferencesEditor {
  PreferencesEditor(this._prefsMap);

  PreferencesMap? _prefsMap;

  T? get<T>(String key) {
    return _prefsMap![key] as T?;
  }

  void put<T>(String key, T value) {
    _prefsMap![key] = value;
  }

  T? remove<T>(String key) {
    return _prefsMap!.remove(key) as T?;
  }

  bool containsKey(String key) {
    return _prefsMap!.containsKey(key);
  }

  void clear() {
    _prefsMap!.clear();
  }
}

class Preferences {
  Preferences({
    required this.name,
    String? homePath,
    this.codec = const StandardMessageCodec(),
  }) : _file = PreferencesFile(name: name, homePath: homePath);

  final String name;

  final StandardMessageCodec codec;

  final PreferencesFile _file;

  var _prefsMap = <String, Object?>{};

  bool containsKey(String key) {
    return _prefsMap.containsKey(key);
  }

  T? get<T>(String key) {
    return _prefsMap[key] as T?;
  }

  Future<void> edit(Edit callback) async {
    final editor = PreferencesEditor(Map.of(_prefsMap));
    await callback(editor);
    await _file.writeBytes(codec.encodePrefsMap(editor._prefsMap!));
    _prefsMap = editor._prefsMap!;
    editor._prefsMap = null;
  }

  Future<void> sync() async {
    final bytes = await _file.readBytes();
    if (bytes == null) {
      return;
    }
    _prefsMap = codec.decodePrefsMap(bytes);
  }
}
