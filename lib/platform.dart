import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'model.dart';

class Device {
  static const channel = MethodChannel('org.basittv.blood_request/device');

  Future<Map<String, dynamic>> read() async {
    final raw = await channel.invokeMethod<String>('read');
    try {
      return Map<String, dynamic>.from(jsonDecode(raw ?? '{}') as Map);
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  Future<void> write(UserSettings settings, Iterable<PosterDraft> drafts) =>
      channel.invokeMethod<void>(
        'write',
        jsonEncode({
          'language': settings.language?.name,
          'favorites': settings.favorites.toList(),
          'drafts': drafts.map((draft) => draft.toJson()).toList(),
        }),
      );

  Future<bool> save(SharePayload payload) async =>
      await channel.invokeMethod<bool>('save', _arguments(payload)) ?? false;

  Future<void> share(SharePayload payload) =>
      channel.invokeMethod<void>('share', _arguments(payload));

  Map<String, Object?> _arguments(SharePayload payload) => {
    'bytes': Uint8List.fromList(payload.bytes),
    'name': payload.options.name,
    'mime': payload.options.mime,
    'caption': payload.caption,
  };
}
