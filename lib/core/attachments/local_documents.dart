import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class LocalDocument {
  const LocalDocument({required this.name, required this.reference});

  final String name;
  final String reference;
}

final class LocalDocumentException implements Exception {
  const LocalDocumentException(this.message);
  final String message;
}

abstract final class LocalDocuments {
  static const _channel = MethodChannel('vn.assetone.assetone/documents');

  static bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<LocalDocument?> pick({required int maxBytes}) async {
    try {
      final file = await _channel.invokeMapMethod<String, String>(
        'pick',
        maxBytes,
      );
      return file == null
          ? null
          : LocalDocument(name: file['name']!, reference: file['uri']!);
    } on PlatformException catch (error) {
      throw LocalDocumentException(error.message ?? 'Không thể đọc tệp.');
    } on MissingPluginException {
      throw const LocalDocumentException(
        'Chọn tệp chưa khả dụng trên thiết bị này.',
      );
    }
  }

  static Future<void> open(String reference) async {
    try {
      await _channel.invokeMethod<void>('open', reference);
    } on PlatformException catch (error) {
      throw LocalDocumentException(error.message ?? 'Không thể mở tệp.');
    } on MissingPluginException {
      throw const LocalDocumentException(
        'Mở tệp chưa khả dụng trên thiết bị này.',
      );
    }
  }
}
