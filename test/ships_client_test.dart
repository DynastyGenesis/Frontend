import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/presentation/pages/client_space/ships_client_page.dart';

void main() {
  setUpAll(() async {
    final regular = FontLoader('Open Sans')
      ..addFont(rootBundle.load('assets/fonts/open_sans_regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/open_sans_bold.ttf'));
    await regular.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('Ships4US desktop navigation and screenshot', (tester) async {
    tester.view.physicalSize = const Size(1280, 853);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: boundary, child: const MaterialApp(home: ShipsClientPage())));
    await tester.pumpAndSettle();
    expect(find.text('iPhone 15 Pro'), findsOneWidget);
    await tester.runAsync(() async {
      for (final asset in [
        'logo',
        'promo',
        'phone',
        'shoes',
        'laptop',
        'bag',
        'driver',
        'map'
      ]) {
        await precacheImage(AssetImage('assets/images/client_$asset.png'),
            boundary.currentContext!);
      }
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('preview').create();
      await File('preview/ships4us-desktop.png')
          .writeAsBytes(data!.buffer.asUint8List());
    });
    for (final label in [
      'Accueil',
      'En transit',
      'Livrés',
      'Réservations',
      'Portefeuille',
      'Documents',
      'Notifications',
      'Paramètres'
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tap(find.text('Colis à recevoir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir détails').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Chaussures Nike Air Force 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Voir le suivi en temps réel'));
    await tester.tap(find.text('Voir le suivi en temps réel'));
    await tester.pumpAndSettle();
    expect(find.text('Jean Koffi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Ships4US mobile and search', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ShipsClientPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'MacBook');
    await tester.pumpAndSettle();
    expect(find.text('MacBook Air'), findsOneWidget);
    expect(find.text('iPhone 15 Pro'), findsNothing);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portefeuille'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Recharger').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '50');
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(find.text('175,50 \$'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reservation validates and completes four steps', (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ShipsClientPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réservations').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Champ obligatoire'), findsWidgets);
    final values = [
      ['Colis standard', '2', 'Vêtements', 'Colis de test'],
      ['120 Broadway', 'New York', '+12125550123', '15 oct. 2026'],
      ['Ama Koffi', '+22890123456', 'Tokoin, Lomé']
    ];
    for (final group in values) {
      for (var i = 0; i < group.length; i++) {
        await tester.enterText(find.byType(TextFormField).at(i), group[i]);
      }
      await tester.ensureVisible(find.text('Suivant'));
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.text('Confirmer la réservation'));
    await tester.tap(find.text('Confirmer la réservation'));
    await tester.pumpAndSettle();
    expect(find.text('Colis de test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
