// Paiement par carte avec la feuille de paiement Stripe.
//
// La carte est saisie dans l'interface Stripe : elle ne passe jamais par
// l'application ni par le backend. Créé au démarrage par `AppServices`.
//
// Android : `MainActivity` hérite de `FlutterFragmentActivity` et le thème
// `NormalTheme` dérive de `Theme.MaterialComponents` (déjà fait).
// Web : la feuille de paiement native n'existe pas ; le port reste indisponible.
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../core/app_config.dart';
import 'card_payment_launcher.dart';

class StripeCardPaymentLauncher implements CardPaymentLauncher {
  StripeCardPaymentLauncher._();

  static const merchantName = 'BarelGo';

  /// Initialise le SDK. Renvoie le port indisponible si la clé publique
  /// manque, si la plateforme n'est pas prise en charge ou si l'initialisation
  /// échoue : le bouton « Payer » reste alors masqué.
  static Future<CardPaymentLauncher> create(AppConfig config) async {
    final supported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!config.hasStripe || !supported) {
      return const UnavailableCardPaymentLauncher();
    }
    try {
      Stripe.publishableKey = config.stripePublishableKey;
      await Stripe.instance.applySettings();
      return StripeCardPaymentLauncher._();
    } catch (_) {
      return const UnavailableCardPaymentLauncher();
    }
  }

  @override
  Future<CardPaymentOutcome> confirm(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantName,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return const CardPaymentOutcome(CardPaymentStatus.succeeded);
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return const CardPaymentOutcome(CardPaymentStatus.canceled);
      }
      return CardPaymentOutcome(
        CardPaymentStatus.failed,
        e.error.localizedMessage ?? 'Le paiement a été refusé.',
      );
    } catch (_) {
      return const CardPaymentOutcome(
          CardPaymentStatus.failed, 'Le paiement n’a pas pu aboutir.');
    }
  }
}
