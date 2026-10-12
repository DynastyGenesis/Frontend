import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/app/app.dart';
import 'package:barrel_go/presentation/pages/client_space/client_space_page.dart';

void main() {
  testWidgets('barrelGo shell renders navigation and brand', (tester) async {
    await tester.pumpWidget(const BarrelGoApp(legacy: true));
    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Suivi'), findsOneWidget);
    expect(find.text('Devis'), findsOneWidget);
    expect(find.text('Envois'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('barrelGo'), findsWidgets);
    expect(find.text('Bienvenue sur barrelGo'), findsOneWidget);
    expect(
        find.textContaining('entre l’Afrique et les États-Unis'), findsWidgets);
    expect(
      find.text('Un besoin transport, une solution sur barrelGo'),
      findsOneWidget,
    );
  });

  testWidgets('Homepage shipment CTA opens the quote screen', (tester) async {
    await tester.pumpWidget(const BarrelGoApp(legacy: true));
    await tester.tap(find.text('Planifier un envoi').first);
    await tester.pumpAndSettle();

    expect(find.text('Demander un devis'), findsOneWidget);
  });

  testWidgets('Quote form supports both Togo and USA directions', (
    tester,
  ) async {
    await tester.pumpWidget(const BarrelGoApp(legacy: true));
    await tester.tap(find.text('Devis').last);
    await tester.pumpAndSettle();

    expect(find.text('Ville de départ au Togo'), findsOneWidget);
    expect(find.text('Ville d’arrivée aux États-Unis'), findsOneWidget);

    await tester.tap(find.text('Togo → États-Unis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('États-Unis → Togo').last);
    await tester.pumpAndSettle();

    expect(find.text('Ville de départ aux États-Unis'), findsOneWidget);
    expect(find.text('Ville d’arrivée au Togo'), findsOneWidget);
  });

  testWidgets('Client space login opens dashboard and shipment shortcuts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ClientSpacePage(onOpenSection: (_) {})),
    );

    expect(find.text('Espace client'), findsOneWidget);
    expect(find.textContaining('Aperçu de démonstration'), findsOneWidget);

    await tester.ensureVisible(find.text('Se connecter'));
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez votre adresse e-mail.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      'client@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'demo-password',
    );
    await tester.ensureVisible(find.text('Se connecter'));
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Bonjour, Marcel !'), findsOneWidget);
    expect(find.text('Envois récents'), findsOneWidget);
    expect(find.textContaining('Paiement à la collecte'), findsOneWidget);

    await tester.tap(find.text('Réserver un pickup').first);
    await tester.pumpAndSettle();
    expect(
        find.text('Collecte du colis et détails de livraison'), findsOneWidget);
    expect(find.textContaining('100 % du montant'), findsOneWidget);

    final pickupFields = <String, String>{
      'Adresse de collecte': 'Rue de la Paix, Lomé',
      'Téléphone du client expéditeur': '+22890000000',
      'Nom du destinataire': 'Kossi Amegavi',
      'Téléphone du destinataire': '+22891000000',
      'Adresse de livraison': 'Tokoin, Lomé',
      'Description du colis': 'Documents',
    };
    for (final entry in pickupFields.entries) {
      await tester.enterText(
        find.widgetWithText(TextFormField, entry.key),
        entry.value,
      );
    }
    await tester.ensureVisible(find.text('Confirmer le pickup'));
    await tester.tap(find.text('Confirmer le pickup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pickup réservé'), findsOneWidget);
    expect(find.textContaining('Paiement à la collecte'), findsOneWidget);

    await tester.tap(find.text('Destinataire (Togo)'));
    await tester.pumpAndSettle();
    expect(find.text('Colis à recevoir au Togo'), findsOneWidget);
    expect(find.text('Notifications de livraison'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Vous serez averti des changements de statut'),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirmer la réception du colis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui, confirmer'));
    await tester.pumpAndSettle();
    expect(find.text('Réception confirmée'), findsOneWidget);
  });

  testWidgets('Client space can be opened as guest without an account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BarrelGoApp(legacy: true));
    await tester.tap(find.byTooltip('Espace client'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue, invité !'), findsOneWidget);
    expect(find.text('Réserver un pickup'), findsWidgets);

    await tester.tap(find.text('Destinataire (Togo)'));
    await tester.pumpAndSettle();
    expect(find.text('Colis à recevoir au Togo'), findsOneWidget);
  });

  testWidgets('Client dashboard menu can open login from guest mode', (
    tester,
  ) async {
    await tester.pumpWidget(const BarrelGoApp(legacy: true));
    await tester.tap(find.byTooltip('Espace client'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue, invité !'), findsOneWidget);

    await tester.tap(find.byTooltip('Menu du compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Espace client'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });

  testWidgets('Client space includes frontend registration and recovery flows',
      (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ClientSpacePage(onOpenSection: (_) {})),
    );

    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);

    await tester.tap(find.text('J’ai déjà un compte — Se connecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    expect(find.text('Mot de passe oublié'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Adresse e-mail'),
      'client@example.com',
    );
    await tester.ensureVisible(find.text('Continuer'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demande simulée'), findsOneWidget);
    expect(find.textContaining('aucun e-mail n’est envoyé'), findsOneWidget);
  });
}

