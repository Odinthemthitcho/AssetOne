import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'local_storage.dart';

LocalStorage createStorage() => _FileStorage();

final class _FileStorage implements LocalStorage {
  late final Future<Directory> _directory = _openDirectory();
  static const _channel = MethodChannel('vn.assetone.assetone/storage');

  Future<Directory> _openDirectory() async {
    final path = switch (Platform.operatingSystem) {
      'android' || 'ios' => await _channel.invokeMethod<String>('directory'),
      'windows' => Platform.environment['LOCALAPPDATA'],
      'macos' => '${Platform.environment['HOME']}/Library/Application Support',
      'linux' =>
        Platform.environment['XDG_DATA_HOME'] ??
            '${Platform.environment['HOME']}/.local/share',
      _ => null,
    };
    if (path == null || path.isEmpty) {
      throw FileSystemException('Không tìm được thư mục lưu dữ liệu AssetOne.');
    }
    return Directory(
      '$path${Platform.pathSeparator}AssetOne',
    ).create(recursive: true);
  }

  Future<File> _file(String key) async {
    final directory = await _directory;
    final encoded = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return File('${directory.path}${Platform.pathSeparator}$encoded.json');
  }

  @override
  Future<String?> read(String key) async {
    final file = await _file(key);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String key, String value) async {
    final file = await _file(key);
    final temporary = File('${file.path}.new');
    await temporary.writeAsString(value, flush: true);
    await temporary.rename(file.path);
  }
}
