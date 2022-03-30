import 'dart:async';

import 'package:flutter/services.dart';

import 'file/file.dart';
import 'codec.dart';
import 'utils.dart';

typedef Edit = FutureOr<void> Function(PreferencesEditor editor);

class PreferencesFactory {
  PreferencesFactory._();

  static String? homePath;

  static Future<Preferences> create({
    required String name,
    String? path,
    StandardMessageCodec codec = const StandardMessageCodec(),
  }) async {
    final prefs = Preferences._(
      name: name,
      codec: codec,
      homePath: path ?? homePath,
    );
    await prefs._sync();
    return prefs;
  }
}

mixin _PreferencesMixin {
  Map<String, Object?> get _prefsMap;

  bool containsKey(String key) {
    return _prefsMap.containsKey(key);
  }

  T? get<T>(String key) {
    return _prefsMap[key] as T?;
  }

  List<T>? getList<T>(String key) {
    return (_prefsMap[key] as List?)?.cast();
  }

  Map<K, V>? getMap<K, V>(String key) {
    return (_prefsMap[key] as Map?)?.cast();
  }
}

class PreferencesEditor with _PreferencesMixin {
  PreferencesEditor._fromPreferences(Preferences prefs)
      : _prefsMap = Map.of(prefs._prefsMap);

  @override
  Map<String, Object?> _prefsMap;

  void put<T>(String key, T value) {
    _prefsMap[key] = value;
  }

  T? remove<T>(String key) {
    return _prefsMap.remove(key) as T?;
  }

  void clear() {
    _prefsMap.clear();
  }

  Map<String, Object?> _takePreferencesMap() {
    final prefsMap = _prefsMap;
    _prefsMap = const {};
    return prefsMap;
  }
}

class Preferences with _PreferencesMixin {
  Preferences._({
    required this.name,
    String? homePath,
    required this.codec,
  }) : _file = PreferencesFile(name: name, homePath: homePath);

  final String name;

  final StandardMessageCodec codec;

  final PreferencesFile _file;

  // Make sure execution is serial.
  final _taskQueue = TaskQueue();

  @override
  var _prefsMap = const <String, Object?>{};

  Future<void> edit(Edit callback) async {
    return _taskQueue.add(() async {
      final editor = PreferencesEditor._fromPreferences(this);
      await Future<void>.sync(() => callback(editor));
      final result = editor._takePreferencesMap();
      await _file.writeBytes(codec.encodePrefsMap(result));
      _prefsMap = result;
    });
  }

  Future<void> _sync() async {
    final bytes = await _file.readBytes();
    if (bytes == null) {
      return;
    }
    _prefsMap = codec.decodePrefsMap(bytes);
  }
}
