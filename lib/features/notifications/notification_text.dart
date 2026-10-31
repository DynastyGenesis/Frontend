// NON ASSEMBLÉ. Texte français et cible d'une notification du backend.
// Types et données : voir app/Notifications du dépôt BarellGo_Backend.
import '../../core/status_mapping.dart';
import '../../data/models/api_models.dart';
import '../../data/models/api_models_extra.dart';

/// Écran qu'ouvre une notification.
enum NotificationTarget { reservation, parcel, dispute, mission, none }

class NotificationView {
  const NotificationView(this.title, this.body, this.target, [this.id]);
  final String title;
  final String body;
  final NotificationTarget target;

  /// Identifiant de la réservation, du colis, du litige ou de la mission visé.
  final int? id;
}

int? _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value');

NotificationView describeNotification(ApiNotification n) {
  final d = n.data;
  final pickup = _int(d['pickup_id']);
  switch (n.type) {
    case 'parcel_status_changed':
      return NotificationView(
          'Colis mis à jour',
          'Votre colis est maintenant : ${parcelStatusLabel('${d['status']}')}.',
          NotificationTarget.parcel,
          _int(d['parcel_id']));
    case 'driver_accepted':
      return NotificationView('Livreur confirmé',
          'Un livreur a accepté votre collecte.', NotificationTarget.reservation, pickup);
    case 'mission_report_proposed':
      return NotificationView(
          'Nouveau créneau proposé',
          'Le livreur propose de décaler la collecte. Répondez depuis la réservation.',
          NotificationTarget.reservation,
          pickup);
    case 'mission_report_answered':
      return NotificationView(
          d['accepted'] == true ? 'Report accepté' : 'Report refusé',
          d['accepted'] == true
              ? 'Le client a accepté le nouveau créneau.'
              : 'Le client a refusé le nouveau créneau.',
          NotificationTarget.mission,
          pickup);
    case 'payment_requested':
      return NotificationView(
          'Paiement demandé',
          'Un paiement de ${d['amount'] ?? ''} \$ est attendu pour la réservation #${pickup ?? ''}.',
          NotificationTarget.reservation,
          pickup);
    case 'payment_reminder':
      return NotificationView('Rappel de paiement',
          'Pensez à régler votre réservation #${pickup ?? ''}.',
          NotificationTarget.reservation, pickup);
    case 'payment_succeeded':
      return NotificationView('Paiement confirmé', 'Merci, votre paiement est reçu.',
          NotificationTarget.reservation, pickup);
    case 'payer_designated':
      return NotificationView('Vous êtes le payeur',
          'On vous demande de régler la réservation #${pickup ?? ''}.',
          NotificationTarget.reservation, pickup);
    case 'payer_replaced':
      return NotificationView('Payeur modifié',
          'Vous n’êtes plus le payeur de la réservation #${pickup ?? ''}.',
          NotificationTarget.reservation, pickup);
    case 'payer_unpaid_sender':
      return NotificationView('Paiement non effectué',
          'Le payeur désigné n’a pas réglé la réservation #${pickup ?? ''}.',
          NotificationTarget.reservation, pickup);
    case 'pickup_cancelled':
    case 'cancelled_pickup_payment':
      return NotificationView('Réservation annulée',
          'La réservation #${pickup ?? ''} a été annulée.',
          NotificationTarget.reservation, pickup);
    case 'dispute_updated':
      final status = disputeStatusLabel('${d['status']}');
      return NotificationView(
          'Litige mis à jour',
          d['refunded'] == true
              ? 'Votre litige est « $status » et un remboursement a été effectué.'
              : 'Votre litige est « $status ».',
          NotificationTarget.dispute,
          _int(d['dispute_id']));
    case 'mission_proposed':
      return NotificationView('Nouvelle mission',
          'Une collecte vous est proposée. Répondez avant la fin du délai.',
          NotificationTarget.mission, pickup);
    case 'mission_removed':
      return NotificationView('Mission retirée',
          'La mission #${pickup ?? ''} ne vous est plus attribuée.',
          NotificationTarget.mission, pickup);
    default:
      return const NotificationView(
          'Notification', 'Consultez l’application pour en savoir plus.',
          NotificationTarget.none);
  }
}
