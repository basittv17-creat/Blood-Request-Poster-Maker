import 'dart:io';
import 'dart:ui' as ui;

import 'package:blood_request/model.dart';
import 'package:blood_request/poster.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports twelve distinct opaque Urdu 1920 × 1080 PNGs', () async {
    for (final font in {
      'Nastaliq': 'notonastaliqurdu',
      'Naskh': 'notonaskharabic',
      'Devanagari': 'notosansdevanagari',
    }.entries) {
      final file = File('assets/fonts/${font.value}.ttf');
      final loader = FontLoader(font.key)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }
    final directory = Directory('build/demo-posters')
      ..createSync(recursive: true);
    final fingerprints = <String>{};
    for (var i = 0; i < designs.length; i++) {
      final image = await PosterPainter(
        PosterRequest.sample,
        Language.ur,
        i,
      ).render();
      expect(image.width, 1920);
      expect(image.height, 1080);
      final rgba = (await image.toByteData())!;
      expect(rgba.getUint8(3), 255);
      expect(rgba.getUint8(rgba.lengthInBytes - 1), 255);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
      expect(png.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      fingerprints.add(png.skip(64).take(240).join(','));
      await File('${directory.path}/demo-${i + 1}.png').writeAsBytes(png);
      image.dispose();
    }
    expect(fingerprints.length, 12);
  });
}
