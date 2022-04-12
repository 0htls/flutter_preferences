import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'file/file.dart';
import 'serialization.dart';
import 'task_queue.dart';

typedef Edit = FutureOr<void> Function(PreferencesEditor editor);

class PreferencesFactory {
  PreferencesFactory._();

  /// see [Preferences.instance].
  static Future<void> initInstance({
    String? path,
    StandardMessageCodec codec = const StandardMessageCodec(),
  }) async {
    Preferences._instance = await PreferencesFactory.create(
      name: 'flutter_preferences',
      path: path,
      codec: codec,
    );
  }

  static Future<Preferences> create({
    required String name,
    String? path,
    StandardMessageCodec codec = const StandardMessageCodec(),
  }) async {
    final prefs = Preferences._(
      name: name,
      codec: codec,
      homePath: path,
    );
    await prefs.sync();
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

  Map<String, Object?> _done() {
    final result = _prefsMap;
    _prefsMap = const {};
    return result;
  }
}

extension _PreferencesCodecExtension on StandardMessageCodec {
  Uint8List encodePreferences(Map<String, Object?> prefsMap) {
    final buffer = WriteBuffer();
    buffer.putInt64(Preferences._version);
    for (final entry in prefsMap.entries) {
      writeValue(buffer, entry.key);
      writeValue(buffer, entry.value);
    }
    final data = buffer.done();
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Map<String, Object?> decodePreferences(Uint8List bytes) {
    final buffer = ReadBuffer(
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes));
    if (buffer.hasRemaining) {
      buffer.getInt64();
    }
    final map = <String, Object?>{};
    while (buffer.hasRemaining) {
      map[readValue(buffer) as String] = readValue(buffer);
    }
    return map;
  }
}

class Preferences with _PreferencesMixin {
  Preferences._({
    required this.name,
    String? homePath,
    required this.codec,
  }) : _file = PreferencesFile(name: name, homePath: homePath);

  static Preferences? _instance;
  static Preferences get instance => _instance!;

  static const int _version = 0;

  final String name;

  final StandardMessageCodec codec;

  final PreferencesFile _file;

  // Make sure execution is serial.
  final _taskQueue = TaskQueue();

  @override
  var _prefsMap = const <String, Object?>{};

  Future<void> edit(Edit callback) async {
    final task = Task(() async {
      final editor = PreferencesEditor._fromPreferences(this);
      final result = callback(editor);
      if (result is Future<void>) {
        await result;
      }
      final newPrefsMap = editor._done();
      await _file.writeBytes(codec.encodePreferences(newPrefsMap));
      _prefsMap = newPrefsMap;
    });
    _taskQueue.add(task);
    return task.future;
  }

  Future<void> sync() async {
    final task = Task(() async {
      final bytes = await _file.readBytes();
      if (bytes == null) {
        return;
      }
      _prefsMap = codec.decodePreferences(bytes);
    });
    _taskQueue.add(task);
    return task.future;
  }
}
