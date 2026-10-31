import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/app/app.dart';
import 'package:barrel_go/core/app_config.dart';
import 'package:barrel_go/data/app_services.dart';
import 'package:barrel_go/data/auth/auth_session.dart';

void main() {
  setUpAll(() async {
    await AppServices.initialize(
      config: const AppConfig(
        apiBaseUrl: 'https://api.test/api/v1',
        supabaseUrl: 'https://test.supabase.co',
        supabaseKey: 'sb_publishable_test',
      ),
      store: MemorySessionStore(),
    );
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
        .pumpWidget(RepaintBoundary(key: boundary, child: const BarelGoApp()));
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
      'Public homepage opens login, validates the form and returns',
      (tester) async {
    size(tester, const Size(1280, 900));
    await tester.pumpWidget(const BarelGoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter — Client').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez une adresse e-mail valide.'), findsOneWidget);
    expect(find.text('Saisissez au moins 6 caractères.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Nos services'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Driver login is accessible and mobile links scroll',
      (tester) async {
    size(tester, const Size(390, 844));
    await tester.pumpWidget(const BarelGoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compte livreur').last);
    await tester.pumpAndSettle();
    expect(find.text('BarelGo · Espace livreur'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nos services').last);
    await tester.pumpAndSettle();
    expect(find.text('Collecte aux États-Unis').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('sans configuration du backend, une page l’explique',
      (tester) async {
    await AppServices.initialize(config: const AppConfig());
    addTearDown(() => AppServices.initialize(
          config: const AppConfig(
            apiBaseUrl: 'https://api.test/api/v1',
            supabaseUrl: 'https://test.supabase.co',
            supabaseKey: 'sb_publishable_test',
          ),
          store: MemorySessionStore(),
        ));
    await tester.pumpWidget(const BarelGoApp());
    expect(find.text('Configuration du backend manquante'), findsOneWidget);
  });
}
