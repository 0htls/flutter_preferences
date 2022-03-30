import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import 'file.dart';

const _kPrefsFileSuffix = '.prefs';
const _kScratchFileSuffix = '.prefs.tmp';

class PreferencesFileImpl implements PreferencesFile {
  PreferencesFileImpl._(
    this._home,
    this._prefsFile,
    this._scratchFile,
  );

  factory PreferencesFileImpl({
    required String name,
    String? homePath,
  }) {
    assert(homePath != null);
    final home = Directory(path.join(homePath!, 'preferences'));
    final prefsFile = File(path.join(home.path, '$name$_kPrefsFileSuffix'));
    final scratchFile = File(path.join(home.path, '$name$_kScratchFileSuffix'));
    return PreferencesFileImpl._(home, prefsFile, scratchFile);
  }

  final Directory _home;

  final File _prefsFile;

  final File _scratchFile;

  @override
  Future<Uint8List?> readBytes() async {
    if (!await _prefsFile.exists()) {
      return null;
    }
    return _prefsFile.readAsBytes();
  }

  @override
  Future<void> writeBytes(Uint8List bytes) async {
    try {
      await _home.create(recursive: true);
      await _scratchFile.writeAsBytes(bytes, flush: true);
      await _scratchFile.rename(_prefsFile.path);
    } catch (e) {
      if (await _scratchFile.exists()) {
        await _scratchFile.delete();
      }
      rethrow;
    }
  }
}
