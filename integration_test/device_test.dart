import 'dart:ui' as ui;

import 'package:blood_request/main.dart';
import 'package:blood_request/model.dart';
import 'package:blood_request/platform.dart';
import 'package:blood_request/poster.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch, saved language, and local storage round trip', (
    tester,
  ) async {
    final device = Device();
    await device.write(const UserSettings(null, {}), []);
    await tester.pumpWidget(const BloodRequestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Generate Request Poster'), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.text('درخواست کا پوسٹر بنائیں'))),
      TextDirection.rtl,
    );
    expect((await device.read())['language'], 'ur');
    final draft = PosterDraft('test', PosterRequest.sample, 8);
    await device.write(const UserSettings(Language.ur, {8}), [draft]);
    final records = (await device.read())['drafts'] as List;
    expect(
      PosterDraft.fromJson(Map<String, dynamic>.from(records.single as Map))
          .template,
      8,
    );
    await device.write(const UserSettings(Language.ur, {}), []);
    expect((await device.read())['drafts'], isEmpty);
  });

  testWidgets('native JPEG encodes and decodes at full poster size', (
    tester,
  ) async {
    final image = await PosterPainter(
      PosterRequest.sample,
      Language.ur,
      0,
    ).render();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
    final jpeg = (await Device.channel.invokeMethod<Uint8List>('jpeg', {
      'bytes': png,
      'quality': 95,
    }))!;
    expect(jpeg.take(2), [255, 216]);
    final codec = await ui.instantiateImageCodec(jpeg);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1920);
    expect(frame.image.height, 1080);
    frame.image.dispose();
    codec.dispose();
  });
}
