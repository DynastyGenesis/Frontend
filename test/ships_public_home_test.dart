import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/app/app.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Open Sans')
      ..addFont(rootBundle.load('assets/fonts/open_sans_regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/open_sans_bold.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  void size(WidgetTester tester, Size value) {
    tester.view.physicalSize = value;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Public homepage renders full desktop proposal and services',
      (tester) async {
    size(tester, const Size(1440, 2280));
    final boundary = GlobalKey();
    await tester
        .pumpWidget(RepaintBoundary(key: boundary, child: const BarrelGoApp()));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
          const AssetImage('assets/images/public_home_hero.png'),
          boundary.currentContext!);
    });
    await tester.pumpAndSettle();
    expect(find.text('Nos services'), findsWidgets);
    expect(find.text('Collecte aux États-Unis'), findsOneWidget);
    expect(find.text('Transport international'), findsOneWidget);
    expect(find.text('Livraison au Togo'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final image = await (boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('preview').create();
      await File('preview/ships4us-public-home.png')
          .writeAsBytes(data!.buffer.asUint8List());
    });
  });
  testWidgets(
      'Public homepage opens login and client can return to public homepage',
      (tester) async {
    size(tester, const Size(1280, 900));
    await tester.pumpWidget(const BarrelGoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter — Client').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez une adresse e-mail valide.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'client@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'), 'demo123');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('iPhone 15 Pro'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Accueil public'));
    await tester.pumpAndSettle();
    expect(find.text('Nos services'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Driver login is accessible and mobile links scroll',
      (tester) async {
    size(tester, const Size(390, 844));
    await tester.pumpWidget(const BarrelGoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compte livreur').last);
    await tester.pumpAndSettle();
    expect(find.text('Ships4US · Espace livreur'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nos services').last);
    await tester.pumpAndSettle();
    expect(find.text('Collecte aux États-Unis').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nous contacter'));
    await tester.pumpAndSettle();
    expect(find.text('Contactez Ships4US'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Votre nom'), 'Ama');
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'ama@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Votre message'),
        'Question sur un colis');
    await tester.tap(find.text('Valider la demande'));
    await tester.pumpAndSettle();
    expect(find.text('Demande simulée. Aucun message n’a été envoyé.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
