import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/presentation/pages/client_space/ships_client_page.dart';
import 'package:barrel_go/presentation/pages/client_space/account/account_components.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Open Sans')
          ..addFont(rootBundle.load('assets/fonts/open_sans_regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/open_sans_bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('document upload validates type, signature and size', () {
    final s = ClientDocuments();
    expect(
        s.validateFile('invoice.pdf', Uint8List.fromList('%PDF-1.7'.codeUnits)),
        isNull);
    expect(s.validateFile('fake.pdf', Uint8List.fromList('invalid'.codeUnits)),
        isNotNull);
    expect(s.validateFile('x.exe', Uint8List(5)), isNotNull);
    expect(s.validateFile('large.pdf', Uint8List(11 * 1024 * 1024)), isNotNull);
  });
  testWidgets('Documents and settings screenshots and profile persistence',
      (tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: const MaterialApp(
            debugShowCheckedModeBanner: false, home: ShipsClientPage())));
    await tester.pumpAndSettle();
    for (final page in ['Documents', 'Paramètres']) {
      await tester.tap(find.text(page).first);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await precacheImage(
            const AssetImage('assets/images/client_settings_avatar.jpg'),
            key.currentContext!);
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
                'preview/ships4us-${page == 'Documents' ? 'documents' : 'settings'}.png')
            .writeAsBytes(data!.buffer.asUint8List());
      });
    }
    final name = find.byType(TextFormField).first;
    await tester.enterText(name, 'Ama Mensah');
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();
    expect(find.text('Ama Mensah'), findsWidgets);
    await tester.tap(find.text('Documents').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paramètres').first);
    await tester.pumpAndSettle();
    expect(find.text('Ama Mensah'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
