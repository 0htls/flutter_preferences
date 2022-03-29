import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_preferences/flutter_preferences.dart';

final home = path.join(Directory.current.path, 'test');

void main() {
  group('preferences', () {
    final prefs = Preferences(homePath: home, name: 'test');

    setUp(() async {
      await prefs.sync();
    });

    test('edit', () async {
      await prefs.edit((editor) {
        for (var i = 0; i < 10000; i++) {
          editor.put('key$i', '54565612$i现在我一直保留遗留的文本布局代码用于测试和调试目的。 但在某些时候它将被删除。');
        }
      });
    });

  });
}
