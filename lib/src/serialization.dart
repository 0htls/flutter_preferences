import 'dart:typed_data';

import 'package:flutter/foundation.dart' as flutter;

// use Endian.little.
class WriteBuffer extends flutter.WriteBuffer {
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
class ReadBuffer extends flutter.ReadBuffer {
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