import 'dart:convert' show utf8;
import 'dart:math' as math;

import 'dart:typed_data';

class StandardCodec {
  const StandardCodec();

  // The codec serializes messages as outlined below. This format must match the
  // Android and iOS counterparts and cannot change (as it's possible for
  // someone to end up using this for persistent storage).
  //
  // * A single byte with one of the constant values below determines the
  //   type of the value.
  // * The serialization of the value itself follows the type byte.
  // * Numbers are represented using the host endianness throughout.
  // * Lengths and sizes of serialized parts are encoded using an expanding
  //   format optimized for the common case of small non-negative integers:
  //   * values 0..253 inclusive using one byte with that value;
  //   * values 254..2^16 inclusive using three bytes, the first of which is
  //     254, the next two the usual unsigned representation of the value;
  //   * values 2^16+1..2^32 inclusive using five bytes, the first of which is
  //     255, the next four the usual unsigned representation of the value.
  // * null, true, and false have empty serialization; they are encoded directly
  //   in the type byte (using _valueNull, _valueTrue, _valueFalse)
  // * Integers representable in 32 bits are encoded using 4 bytes two's
  //   complement representation.
  // * Larger integers are encoded using 8 bytes two's complement
  //   representation.
  // * doubles are encoded using the IEEE 754 64-bit double-precision binary
  //   format. Zero bytes are added before the encoded double value to align it
  //   to a 64 bit boundary in the full message.
  // * Strings are encoded using their UTF-8 representation. First the length
  //   of that in bytes is encoded using the expanding format, then follows the
  //   UTF-8 encoding itself.
  // * Uint8Lists, Int32Lists, Int64Lists, Float32Lists, and Float64Lists are
  //   encoded by first encoding the list's element count in the expanding
  //   format, then the smallest number of zero bytes needed to align the
  //   position in the full message with a multiple of the number of bytes per
  //   element, then the encoding of the list elements themselves, end-to-end
  //   with no additional type information, using two's complement or IEEE 754
  //   as applicable.
  // * Lists are encoded by first encoding their length in the expanding format,
  //   then follows the recursive encoding of each element value, including the
  //   type byte (Lists are assumed to be heterogeneous).
  // * Maps are encoded by first encoding their length in the expanding format,
  //   then follows the recursive encoding of each key/value pair, including the
  //   type byte for both (Maps are assumed to be heterogeneous).
  //
  // The type labels below must not change, since it's possible for this interface
  // to be used for persistent storage.
  static const int _valueNull = 0;
  static const int _valueTrue = 1;
  static const int _valueFalse = 2;
  static const int _valueInt32 = 3;
  static const int _valueInt64 = 4;
  static const int _valueLargeInt = 5;
  static const int _valueFloat64 = 6;
  static const int _valueString = 7;
  static const int _valueUint8List = 8;
  static const int _valueInt32List = 9;
  static const int _valueInt64List = 10;
  static const int _valueFloat64List = 11;
  static const int _valueList = 12;
  static const int _valueMap = 13;
  static const int _valueFloat32List = 14;

  /// Writes [value] to [buffer] by first writing a type discriminator
  /// byte, then the value itself.
  ///
  /// This method may be called recursively to serialize container values.
  ///
  /// Type discriminators 0 through 127 inclusive are reserved for use by the
  /// base class, as follows:
  ///
  ///  * null = 0
  ///  * true = 1
  ///  * false = 2
  ///  * 32 bit integer = 3
  ///  * 64 bit integer = 4
  ///  * larger integers = 5 (see below)
  ///  * 64 bit floating-point number = 6
  ///  * String = 7
  ///  * Uint8List = 8
  ///  * Int32List = 9
  ///  * Int64List = 10
  ///  * Float64List = 11
  ///  * List = 12
  ///  * Map = 13
  ///  * Float32List = 14
  ///  * Reserved for future expansion: 15..127
  ///
  /// The codec can be extended by overriding this method, calling super
  /// for values that the extension does not handle. Type discriminators
  /// used by extensions must be greater than or equal to 128 in order to avoid
  /// clashes with any later extensions to the base class.
  ///
  /// The "larger integers" type, 5, is never used by [writeValue]. A subclass
  /// could represent big integers from another package using that type. The
  /// format is first the type byte (0x05), then the actual number as an ASCII
  /// string giving the hexadecimal representation of the integer, with the
  /// string's length as encoded by [writeSize] followed by the string bytes. On
  /// Android, that would get converted to a `java.math.BigInteger` object. On
  /// iOS, the string representation is returned.
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value == null) {
      buffer.putUint8(_valueNull);
    } else if (value is bool) {
      buffer.putUint8(value ? _valueTrue : _valueFalse);
    } else if (value is double) {  // Double precedes int because in JS everything is a double.
      // Therefore in JS, both `is int` and `is double` always
      // return `true`. If we check int first, we'll end up treating
      // all numbers as ints and attempt the int32/int64 conversion,
      // which is wrong. This precedence rule is irrelevant when
      // decoding because we use tags to detect the type of value.
      buffer.putUint8(_valueFloat64);
      buffer.putFloat64(value);
    } else if (value is int) { // ignore: avoid_double_and_int_checks, JS code always goes through the `double` path above
      if (-0x7fffffff - 1 <= value && value <= 0x7fffffff) {
        buffer.putUint8(_valueInt32);
        buffer.putInt32(value);
      } else {
        buffer.putUint8(_valueInt64);
        buffer.putInt64(value);
      }
    } else if (value is String) {
      buffer.putUint8(_valueString);
      final Uint8List bytes = utf8.encoder.convert(value);
      writeSize(buffer, bytes.length);
      buffer.putUint8List(bytes);
    } else if (value is Uint8List) {
      buffer.putUint8(_valueUint8List);
      writeSize(buffer, value.length);
      buffer.putUint8List(value);
    } else if (value is Int32List) {
      buffer.putUint8(_valueInt32List);
      writeSize(buffer, value.length);
      buffer.putInt32List(value);
    } else if (value is Int64List) {
      buffer.putUint8(_valueInt64List);
      writeSize(buffer, value.length);
      buffer.putInt64List(value);
    } else if (value is Float32List) {
      buffer.putUint8(_valueFloat32List);
      writeSize(buffer, value.length);
      buffer.putFloat32List(value);
    } else if (value is Float64List) {
      buffer.putUint8(_valueFloat64List);
      writeSize(buffer, value.length);
      buffer.putFloat64List(value);
    } else if (value is List) {
      buffer.putUint8(_valueList);
      writeSize(buffer, value.length);
      for (final Object? item in value) {
        writeValue(buffer, item);
      }
    } else if (value is Map) {
      buffer.putUint8(_valueMap);
      writeSize(buffer, value.length);
      value.forEach((Object? key, Object? value) {
        writeValue(buffer, key);
        writeValue(buffer, value);
      });
    } else {
      throw ArgumentError.value(value);
    }
  }

  /// Reads a value from [buffer] as written by [writeValue].
  ///
  /// This method is intended for use by subclasses overriding
  /// [readValueOfType].
  Object? readValue(ReadBuffer buffer) {
    if (!buffer.hasRemaining) {
      throw const FormatException('Message corrupted');
    }
    final int type = buffer.getUint8();
    return readValueOfType(type, buffer);
  }

  /// Reads a value of the indicated [type] from [buffer].
  ///
  /// The codec can be extended by overriding this method, calling super for
  /// types that the extension does not handle. See the discussion at
  /// [writeValue].
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case _valueNull:
        return null;
      case _valueTrue:
        return true;
      case _valueFalse:
        return false;
      case _valueInt32:
        return buffer.getInt32();
      case _valueInt64:
        return buffer.getInt64();
      case _valueFloat64:
        return buffer.getFloat64();
      case _valueLargeInt:
      case _valueString:
        final int length = readSize(buffer);
        return utf8.decoder.convert(buffer.getUint8List(length));
      case _valueUint8List:
        final int length = readSize(buffer);
        return buffer.getUint8List(length);
      case _valueInt32List:
        final int length = readSize(buffer);
        return buffer.getInt32List(length);
      case _valueInt64List:
        final int length = readSize(buffer);
        return buffer.getInt64List(length);
      case _valueFloat32List:
        final int length = readSize(buffer);
        return buffer.getFloat32List(length);
      case _valueFloat64List:
        final int length = readSize(buffer);
        return buffer.getFloat64List(length);
      case _valueList:
        final int length = readSize(buffer);
        final List<Object?> result = List<Object?>.filled(length, null);
        for (int i = 0; i < length; i++) {
          result[i] = readValue(buffer);
        }
        return result;
      case _valueMap:
        final int length = readSize(buffer);
        final Map<Object?, Object?> result = <Object?, Object?>{};
        for (int i = 0; i < length; i++) {
          result[readValue(buffer)] = readValue(buffer);
        }
        return result;
      default: throw const FormatException('Message corrupted');
    }
  }

  /// Writes a non-negative 32-bit integer [value] to [buffer]
  /// using an expanding 1-5 byte encoding that optimizes for small values.
  ///
  /// This method is intended for use by subclasses overriding
  /// [writeValue].
  void writeSize(WriteBuffer buffer, int value) {
    assert(0 <= value && value <= 0xffffffff);
    if (value < 254) {
      buffer.putUint8(value);
    } else if (value <= 0xffff) {
      buffer.putUint8(254);
      buffer.putUint16(value);
    } else {
      buffer.putUint8(255);
      buffer.putUint32(value);
    }
  }

  /// Reads a non-negative int from [buffer] as written by [writeSize].
  ///
  /// This method is intended for use by subclasses overriding
  /// [readValueOfType].
  int readSize(ReadBuffer buffer) {
    final int value = buffer.getUint8();
    switch (value) {
      case 254:
        return buffer.getUint16();
      case 255:
        return buffer.getUint32();
      default:
        return value;
    }
  }
}

/// Write-only buffer for incrementally building a [ByteData] instance.
///
/// A WriteBuffer instance can be used only once. Attempts to reuse will result
/// in [StateError]s being thrown.
///
/// The byte order used is [Endian.little] throughout.
class WriteBuffer {
  /// Creates an interface for incrementally building a [ByteData] instance.
  factory WriteBuffer() {
    final ByteData eightBytes = ByteData(8);
    final Uint8List eightBytesAsList = eightBytes.buffer.asUint8List();
    return WriteBuffer._(Uint8List(8), eightBytes, eightBytesAsList);
  }

  WriteBuffer._(this._buffer, this._eightBytes, this._eightBytesAsList);

  Uint8List _buffer;
  int _currentSize = 0;
  bool _isDone = false;
  final ByteData _eightBytes;
  final Uint8List _eightBytesAsList;
  static final Uint8List _zeroBuffer = Uint8List(8);

  void _add(int byte) {
    if (_currentSize == _buffer.length) {
      _resize();
    }
    _buffer[_currentSize] = byte;
    _currentSize += 1;
  }

  void _append(Uint8List other) {
    final int newSize = _currentSize + other.length;
    if (newSize >= _buffer.length) {
      _resize(newSize);
    }
    _buffer.setRange(_currentSize, newSize, other);
    _currentSize += other.length;
  }

  void _addAll(Uint8List data, [int start = 0, int? end]) {
    final int newEnd = end ?? _eightBytesAsList.length;
    final int newSize = _currentSize + (newEnd - start);
    if (newSize >= _buffer.length) {
      _resize(newSize);
    }
    _buffer.setRange(_currentSize, newSize, data);
    _currentSize = newSize;
  }

  void _resize([int? requiredLength]) {
    final int doubleLength = _buffer.length * 2;
    final int newLength = math.max(requiredLength ?? 0, doubleLength);
    final Uint8List newBuffer = Uint8List(newLength);
    newBuffer.setRange(0, _buffer.length, _buffer);
    _buffer = newBuffer;
  }

  /// Write a Uint8 into the buffer.
  void putUint8(int byte) {
    assert(!_isDone);
    _add(byte);
  }

  /// Write a Uint16 into the buffer.
  void putUint16(int value) {
    assert(!_isDone);
    _eightBytes.setUint16(0, value, Endian.little);
    _addAll(_eightBytesAsList, 0, 2);
  }

  /// Write a Uint32 into the buffer.
  void putUint32(int value) {
    assert(!_isDone);
    _eightBytes.setUint32(0, value, Endian.little);
    _addAll(_eightBytesAsList, 0, 4);
  }

  /// Write an Int32 into the buffer.
  void putInt32(int value) {
    assert(!_isDone);
    _eightBytes.setInt32(0, value, Endian.little);
    _addAll(_eightBytesAsList, 0, 4);
  }

  /// Write an Int64 into the buffer.
  void putInt64(int value) {
    assert(!_isDone);
    _eightBytes.setInt64(0, value, Endian.little);
    _addAll(_eightBytesAsList, 0, 8);
  }

  /// Write an Float64 into the buffer.
  void putFloat64(double value) {
    assert(!_isDone);
    _alignTo(8);
    _eightBytes.setFloat64(0, value, Endian.little);
    _addAll(_eightBytesAsList);
  }

  /// Write all the values from a [Uint8List] into the buffer.
  void putUint8List(Uint8List list) {
    assert(!_isDone);
    _append(list);
  }

  /// Write all the values from an [Int32List] into the buffer.
  void putInt32List(Int32List list) {
    assert(!_isDone);
    _alignTo(4);
    _append(list.buffer.asUint8List(list.offsetInBytes, 4 * list.length));
  }

  /// Write all the values from an [Int64List] into the buffer.
  void putInt64List(Int64List list) {
    assert(!_isDone);
    _alignTo(8);
    _append(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
  }

  /// Write all the values from a [Float32List] into the buffer.
  void putFloat32List(Float32List list) {
    assert(!_isDone);
    _alignTo(4);
    _append(list.buffer.asUint8List(list.offsetInBytes, 4 * list.length));
  }

  /// Write all the values from a [Float64List] into the buffer.
  void putFloat64List(Float64List list) {
    assert(!_isDone);
    _alignTo(8);
    _append(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
  }

  void _alignTo(int alignment) {
    assert(!_isDone);
    final int mod = _currentSize % alignment;
    if (mod != 0) {
      _addAll(_zeroBuffer, 0, alignment - mod);
    }
  }

  /// Finalize and return the written [ByteData].
  ByteData done() {
    if (_isDone) {
      throw StateError('done() must not be called more than once on the same $runtimeType.');
    }
    final ByteData result = _buffer.buffer.asByteData(0, _currentSize);
    _buffer = Uint8List(0);
    _isDone = true;
    return result;
  }
}

/// Read-only buffer for reading sequentially from a [ByteData] instance.
///
/// The byte order used is [Endian.little] throughout.
class ReadBuffer {
  /// Creates a [ReadBuffer] for reading from the specified [data].
  ReadBuffer(this.data);

  /// The underlying data being read.
  final ByteData data;

  /// The position to read next.
  int _position = 0;

  /// Whether the buffer has data remaining to read.
  bool get hasRemaining => _position < data.lengthInBytes;

  /// Reads a Uint8 from the buffer.
  int getUint8() {
    return data.getUint8(_position++);
  }

  /// Reads a Uint16 from the buffer.
  int getUint16() {
    final int value = data.getUint16(_position, Endian.little);
    _position += 2;
    return value;
  }

  /// Reads a Uint32 from the buffer.
  int getUint32({Endian? endian}) {
    final int value = data.getUint32(_position, Endian.little);
    _position += 4;
    return value;
  }

  /// Reads an Int32 from the buffer.
  int getInt32({Endian? endian}) {
    final int value = data.getInt32(_position, Endian.little);
    _position += 4;
    return value;
  }

  /// Reads an Int64 from the buffer.
  int getInt64({Endian? endian}) {
    final int value = data.getInt64(_position, Endian.little);
    _position += 8;
    return value;
  }

  /// Reads a Float64 from the buffer.
  double getFloat64({Endian? endian}) {
    _alignTo(8);
    final double value = data.getFloat64(_position, Endian.little);
    _position += 8;
    return value;
  }

  /// Reads the given number of Uint8s from the buffer.
  Uint8List getUint8List(int length) {
    final Uint8List list = data.buffer.asUint8List(data.offsetInBytes + _position, length);
    _position += length;
    return list;
  }

  /// Reads the given number of Int32s from the buffer.
  Int32List getInt32List(int length) {
    _alignTo(4);
    final Int32List list = data.buffer.asInt32List(data.offsetInBytes + _position, length);
    _position += 4 * length;
    return list;
  }

  /// Reads the given number of Int64s from the buffer.
  Int64List getInt64List(int length) {
    _alignTo(8);
    final Int64List list = data.buffer.asInt64List(data.offsetInBytes + _position, length);
    _position += 8 * length;
    return list;
  }

  /// Reads the given number of Float32s from the buffer
  Float32List getFloat32List(int length) {
    _alignTo(4);
    final Float32List list = data.buffer.asFloat32List(data.offsetInBytes + _position, length);
    _position += 4 * length;
    return list;
  }

  /// Reads the given number of Float64s from the buffer.
  Float64List getFloat64List(int length) {
    _alignTo(8);
    final Float64List list = data.buffer.asFloat64List(data.offsetInBytes + _position, length);
    _position += 8 * length;
    return list;
  }

  void _alignTo(int alignment) {
    final int mod = _position % alignment;
    if (mod != 0) {
      _position += alignment - mod;
    }
  }
}
