import 'dart:convert';

import 'dart:typed_data';

void main() {
  final bytes = Uint8List.fromList([0, 1, 0,0, 1, 0,0, 1, 0,]);

  final string = json.encoder.convert(bytes);
  print(string);
  print(json.decoder.convert(string).runtimeType);
}