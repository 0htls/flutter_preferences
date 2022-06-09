import 'dart:async';
import 'dart:typed_data';

import 'file/file.dart';
import 'serialization.dart';
import 'task_queue.dart';

typedef Edit = FutureOr<void> Function(PreferencesEditor editor);

class PreferencesFactory {
  PreferencesFactory._();

  /// see [Preferences.instance].
  static Future<void> initInstance({
    String? path,
    StandardCodec codec = const StandardCodec(),
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
    StandardCodec codec = const StandardCodec(),
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

abstract class PreferenceKey<R, P> {
  const PreferenceKey({
    required this.key,
    required this.defaultValue,
  });

  final String key;

  final R defaultValue;

  R from(P value);

  P to(R value);

  bool updateShouldNotify(R oldValue, R newValue) {
    return oldValue != newValue;
  }

  @override
  String toString() {
    return '$runtimeType($key)';
  }

  @override
  int get hashCode => key.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PreferenceKey && key == other.key;
  }
}

class PrimitivePreferenceKey<R> extends PreferenceKey<R, R> {
  const PrimitivePreferenceKey({
    required super.key,
    required super.defaultValue,
  });

  @override
  R from(R value) => value;

  @override
  R to(R value) => value;
}

typedef IntPreferenceKey = PrimitivePreferenceKey<int>;
typedef DoublePreferenceKey = PrimitivePreferenceKey<double>;
typedef BoolPreferenceKey = PrimitivePreferenceKey<bool>;
typedef StringPreferenceKey = PrimitivePreferenceKey<String>;

class StringListPreferenceKey
    extends PreferenceKey<List<String>, List<Object?>> {
  const StringListPreferenceKey({
    required super.key,
    required super.defaultValue,
  });

  @override
  List<String> from(List<Object?> value) {
    return value.cast();
  }

  @override
  List<Object?> to(List<String> value) {
    return value;
  }
}

class StringMapPreferenceKey
    extends PreferenceKey<Map<String, String>, Map<Object?, Object?>> {
  const StringMapPreferenceKey({
    required super.key,
    required super.defaultValue,
  });

  @override
  Map<String, String> from(Map<Object?, Object?> value) {
    return value.cast();
  }

  @override
  Map<Object?, Object?> to(Map<String, String> value) {
    return value;
  }
}

mixin _PreferencesMixin {
  Map<String, Object?> get _prefsMap;

  int get length => _prefsMap.length;

  bool containsKey(PreferenceKey<Object?, Object?> key) {
    return _prefsMap.containsKey(key.key);
  }

  R get<R, P>(PreferenceKey<R, P> key) {
    if (!_prefsMap.containsKey(key.key)) {
      return key.defaultValue;
    }
    return key.from(_prefsMap[key.key] as P);
  }
}

class PreferencesEditor with _PreferencesMixin {
  PreferencesEditor._fromPreferences(Preferences prefs)
      : _prefsMap = prefs._prefsMap;

  @override
  Map<String, Object?> _prefsMap;

  bool _forceUpdate = false;

  final _updatedKeys = <PreferenceKey<Object?, Object?>>{};

  void put<R, P>(PreferenceKey<R, P> key, R newValue) {
    if (_prefsMap.containsKey(key.key)) {
      final oldValue = key.from(_prefsMap[key.key] as P);
      if (key.updateShouldNotify(oldValue, newValue)) {
        _updatedKeys.add(key);
      }
    } else {
      _updatedKeys.add(key);
    }
    _prefsMap[key.key] = key.to(newValue);
  }

  void remove<T>(PreferenceKey<Object?, Object?> key) {
    if (_prefsMap.containsKey(key.key)) {
      _updatedKeys.add(key);
      _prefsMap.remove(key.key);
    }
  }

  void clear() {
    if (_prefsMap.isNotEmpty) {
      _forceUpdate = true;
    }
    _prefsMap.clear();
  }

  void _done() {
    _prefsMap = const {};
  }
}

extension _PreferencesCodecExtension on StandardCodec {
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

class PreferencesEvent {
  PreferencesEvent(this.forceUpdate, this.updatedKeys);

  final bool forceUpdate;

  final Set<PreferenceKey<Object?, Object?>> updatedKeys;
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

  final StandardCodec codec;

  final PreferencesFile _file;

  // Make sure execution is serial.
  final _taskQueue = TaskQueue();

  @override
  var _prefsMap = <String, Object?>{};

  StreamController<PreferencesEvent>? _controller;

  Stream<PreferencesEvent> get events {
    _controller ??= StreamController<PreferencesEvent>(
      onCancel: () {
        _controller?.close();
        _controller = null;
      },
    );
    return _controller!.stream;
  }

  void _dispatchEvent(PreferencesEditor editor) {
    if (_controller == null) {
      return;
    }

    if (editor._forceUpdate || editor._updatedKeys.isNotEmpty) {
      _controller!.add(PreferencesEvent(
        editor._forceUpdate,
        editor._updatedKeys,
      ));
    }
  }

  Future<void> edit(Edit callback) async {
    final task = Task(() async {
      final editor = PreferencesEditor._fromPreferences(this);
      final result = callback(editor);
      if (result is Future<void>) {
        await result;
      }
      editor._done();
      await _file.writeBytes(codec.encodePreferences(_prefsMap));
      _dispatchEvent(editor);
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
