import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/presentation/pages/driver_space/ships_driver_page.dart';
import 'package:barrel_go/presentation/pages/driver_space/driver_models.dart';
import 'package:barrel_go/presentation/pages/client_space/ships_login_page.dart';

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
  void size(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('Delivery requires ordered steps and confirmation, gains credit once',
      () {
    final session = DriverSession();
    final mission = session.missions.first;
    expect(mission.complete('Ama', true), isFalse);
    expect(mission.advance(), isTrue);
    expect(mission.advance(), isTrue);
    expect(mission.advance(), isTrue);
    expect(mission.advance(), isFalse);
    expect(mission.complete('', true), isFalse);
    expect(mission.complete('Ama', false), isFalse);
    final previous = session.earnings;
    expect(mission.complete('Ama', true), isTrue);
    expect(session.earnings, previous + mission.fee);
    expect(mission.complete('Ama', true), isFalse);
    expect(session.earnings, previous + mission.fee);
  });
  testWidgets('Driver desktop screenshots, incident and completed delivery',
      (tester) async {
    size(tester, const Size(1440, 1000));
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: const MaterialApp(
            debugShowCheckedModeBanner: false, home: ShipsDriverPage())));
    await tester.pumpAndSettle();
    Future<void> capture(String file) async {
      await tester.runAsync(() async {
        for (final image in [
          'logo',
          'driver',
          'bag',
          'shoes',
          'phone',
          'laptop'
        ]) {
          await precacheImage(AssetImage('assets/images/client_$image.png'),
              key.currentContext!);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final img = await (key.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('preview/$file.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    await capture('ships4us-driver-dashboard');
    await tester.tap(find.text('Voir la mission').first);
    await tester.pumpAndSettle();
    await capture('ships4us-driver-mission');
    await tester.tap(find.text('Signaler un incident'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer l’incident'));
    await tester.pumpAndSettle();
    expect(find.text('Destinataire absent'), findsOneWidget);
    await tester.ensureVisible(find.text('Confirmer la collecte'));
    await tester.tap(find.text('Confirmer la collecte'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Démarrer la livraison'));
    await tester.tap(find.text('Démarrer la livraison'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirmer la livraison'));
    await tester.tap(find.text('Confirmer la livraison'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider la livraison'));
    await tester.pumpAndSettle();
    expect(find.text('Indiquez le nom du réceptionnaire.'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nom de la personne qui reçoit'),
        'Abla Sika');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('Valider la livraison'));
    await tester.pumpAndSettle();
    expect(find.text('Livraison terminée'), findsOneWidget);
    await tester.tap(find.text('Mes revenus').first);
    await tester.pumpAndSettle();
    expect(find.text('20,00 \$'), findsOneWidget);
    for (final menu in [
      'Missions disponibles',
      'Mes missions',
      'Historique',
      'Notifications',
      'Mon profil',
      'Aide & Support'
    ]) {
      await tester.tap(find.text(menu).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: menu);
    }
  });
  testWidgets('Driver mobile navigation prevents unavailable acceptance',
      (tester) async {
    size(tester, const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: ShipsDriverPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Missions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir la mission').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Accepter la mission'));
    await tester.tap(find.text('Accepter la mission'));
    await tester.pumpAndSettle();
    expect(find.text('Activez votre disponibilité pour accepter une mission.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Driver login opens driver dashboard and logout returns public home',
      (tester) async {
    size(tester, const Size(1440, 1000));
    await tester
        .pumpWidget(const MaterialApp(home: ShipsLoginPage(driver: true)));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse e-mail'),
        'livreur@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'), 'demo123');
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour Jean !'), findsOneWidget);
    await tester.tap(find.text('Se déconnecter').first);
    await tester.pumpAndSettle();
    expect(find.text('Nos services'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
