import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' as foundation;

extension PreferencesCodecExtension on StandardMessageCodec {
  void _writeString(WriteBuffer buffer, String string) {
    final bytes = utf8.encoder.convert(string);
    writeSize(buffer, bytes.length);
    buffer.putUint8List(bytes);
  }

  String _readString(ReadBuffer buffer) {
    final length = readSize(buffer);
    final bytes = buffer.getUint8List(length);
    return utf8.decoder.convert(bytes);
  }

  Uint8List encodePrefsMap(Map<String, Object?> map) {
    final buffer = WriteBuffer();
    for (final entry in map.entries) {
      _writeString(buffer, entry.key);
      writeValue(buffer, entry.value);
    }
    final data = buffer.done();
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Map<String, Object?> decodePrefsMap(Uint8List bytes) {
    final buffer = ReadBuffer(bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes));
    final map = <String, Object?>{};
    while (buffer.hasRemaining) {
      map[_readString(buffer)] = readValue(buffer);
    }
    return map;
  }
}

// use Endian.little.
class WriteBuffer extends foundation.WriteBuffer {
  @override
  void putUint16(int value, {Endian? endian}) {
    super.putUint16(value, endian: Endian.little);
  }

  @override
  void putUint32(int value, {Endian? endian}) {
    super.putUint32(value, endian: Endian.little);
  }

  @override
  void putInt32(int value, {Endian? endian}) {
    super.putInt32(value, endian: Endian.little);
  }

  @override
  void putInt64(int value, {Endian? endian}) {
    super.putInt64(value, endian: Endian.little);
  }

  @override
  void putFloat64(double value, {Endian? endian}) {
    super.putFloat64(value, endian: Endian.little);
  }
}

// use Endian.little.
class ReadBuffer extends foundation.ReadBuffer {
  ReadBuffer(ByteData data) : super(data);

  @override
  int getUint16({Endian? endian}) {
    return super.getUint16(endian: Endian.little);
  }

  @override
  int getUint32({Endian? endian}) {
    return super.getUint32(endian: Endian.little);
  }

  @override
  int getInt32({Endian? endian}) {
    return super.getInt32(endian: Endian.little);
  }

  @override
  int getInt64({Endian? endian}) {
    return super.getInt64(endian: Endian.little);
  }

  @override
  double getFloat64({Endian? endian}) {
    return super.getFloat64(endian: Endian.little);
  }
}