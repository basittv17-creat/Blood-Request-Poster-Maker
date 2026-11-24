import 'package:blood_request/groups_data.dart';
import 'package:blood_request/main.dart';
import 'package:blood_request/platform.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const invite = 'https://chat.whatsapp.com/abcdefghijklmnopqrstuv';

  test('only canonical WhatsApp group invitations are accepted', () {
    expect(canonicalInvite('  $invite?s=test  '), invite);
    for (final invalid in [
      'http://chat.whatsapp.com/abcdefghijklmnopqrstuv',
      'https://chat.whatsapp.com.example.com/abcdefghijklmnopqrstuv',
      'https://someone@chat.whatsapp.com/abcdefghijklmnopqrstuv',
      '$invite/extra',
      'https://chat.whatsapp.com/short',
    ]) {
      expect(canonicalInvite(invalid), isNull, reason: invalid);
    }
  });

  testWidgets('first launch shows both home options with Admin in the menu', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(Device.channel, (call) async {
      if (call.method == 'read') return '{}';
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(Device.channel, null));

    await tester.pumpWidget(const BloodRequestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Generate Request Poster'), findsOneWidget);
    expect(find.text('Join WhatsApp Donation Groups'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('premium home remains usable on a narrow phone in Urdu', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(Device.channel, (call) async {
      if (call.method == 'read') return '{}';
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(Device.channel, null));
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BloodRequestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();

    expect(find.text('Blood Request'), findsOneWidget);
    expect(find.text('میرے ڈرافٹس'), findsOneWidget);
    expect(find.text('درخواست کا پوسٹر بنائیں'), findsOneWidget);
    expect(find.text('واٹس ایپ عطیہ گروپس میں شامل ہوں'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
