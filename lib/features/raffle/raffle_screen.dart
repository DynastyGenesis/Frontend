// Tirage au sort mensuel (GET /raffle/current et /raffle/history).
//
// Un tirage par État américain et par mois. Le gain est un crédit de remise sur
// la prochaine collecte du gagnant, pas un virement. L'État vient du profil
// (écran « Mon compte ») : sans lui, le backend répond 404.
import 'package:flutter/material.dart';

import '../../data/api/api_exception.dart';
import '../../data/models/api_models_raffle.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';
import '../common/ui.dart';

class RaffleController extends FeatureController {
  RaffleController(this._api, {required this.currentUserId});

  final BackendApi _api;
  final String currentUserId;

  ApiRaffleDraw? current;
  List<ApiRaffleDraw> history = [];

  /// Vrai quand le profil n'a pas d'État (le backend répond 404).
  bool missingState = false;
  bool loadedOnce = false;

  Future<void> load() async {
    missingState = false;
    final result = await run(() async {
      ApiRaffleDraw? draw;
      try {
        draw = await _api.raffleCurrent();
      } on ApiException catch (e) {
        if (!e.isNotFound) rethrow;
        missingState = true;
      }
      return (draw, await _api.raffleHistory());
    });
    if (result != null) {
      current = result.$1;
      history = result.$2;
    }
    if (missingState) error = null;
    loadedOnce = true;
    notifyListeners();
  }

  bool isWinner(ApiRaffleDraw draw) =>
      draw.winnerUserId != null && draw.winnerUserId == currentUserId;
}

class RaffleScreen extends StatefulWidget {
  const RaffleScreen({super.key, required this.controller, this.onOpenAccount});
  final RaffleController controller;

  /// Ouvre « Mon compte », où l'on renseigne l'État.
  final VoidCallback? onOpenAccount;

  @override
  State<RaffleScreen> createState() => _RaffleScreenState();
}

class _RaffleScreenState extends State<RaffleScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  String _period(ApiRaffleDraw d) => '${formatDate(d.periodStart)} au ${formatDate(d.periodEnd)}';

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Tirage au sort',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return RefreshIndicator(
              onRefresh: c.load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (c.error != null) ErrorBanner(message: c.error!, onRetry: c.load),
                if (c.busy && !c.loadedOnce)
                  const Center(child: CircularProgressIndicator()),
                if (c.missingState)
                  Panel(
                      color: const Color(0xFFFFF7EC),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Heading('État non renseigné'),
                        const Text(
                            'Le tirage a lieu chaque mois pour chaque État américain. Indiquez le vôtre pour y participer.',
                            style: TextStyle(fontSize: 12)),
                        if (widget.onOpenAccount != null) ...[
                          const SizedBox(height: 10),
                          ActionButton(
                              label: 'Renseigner mon État',
                              outline: true,
                              onPressed: widget.onOpenAccount),
                        ],
                      ])),
                if (c.current != null) _currentPanel(c, c.current!),
                if (c.loadedOnce && !c.missingState)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 14),
                    child: Text(
                        'Le gain est un crédit de remise sur votre prochaine collecte, pas un virement.',
                        style: TextStyle(fontSize: 11, color: fMuted)),
                  ),
                if (c.history.isNotEmpty) ...[
                  const Heading('Tirages précédents'),
                  for (final d in c.history)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Panel(
                          child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                          Text('${d.state} · ${_period(d)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: fNavy)),
                          if (d.amountRefunded != null)
                            Text('Crédit : ${usd(d.amountRefunded!)}',
                                style: const TextStyle(
                                    fontSize: 11, color: fMuted)),
                        ])),
                        if (c.isWinner(d))
                          const Pill('Vous avez gagné', color: fGreen)
                        else
                          const Pill('Tiré', color: fMuted),
                      ])),
                    ),
                ],
                if (c.loadedOnce &&
                    !c.missingState &&
                    c.history.isEmpty &&
                    c.error == null)
                  const EmptyState(
                      text: 'Aucun tirage terminé pour le moment.',
                      icon: Icons.emoji_events_outlined),
              ]),
            );
          },
        ),
      );

  Widget _currentPanel(RaffleController c, ApiRaffleDraw draw) => Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Heading('Tirage de ${draw.state}')),
          draw.isDrawn
              ? (c.isWinner(draw)
                  ? const Pill('Vous avez gagné', color: fGreen)
                  : const Pill('Tirage effectué', color: fBlue))
              : const Pill('En attente', color: fOrange),
        ]),
        LabeledLine('Période', _period(draw)),
        if (draw.isDrawn) ...[
          LabeledLine('Tiré le', formatDateTime(draw.drawnAt)),
          if (draw.amountRefunded != null)
            LabeledLine('Crédit offert', usd(draw.amountRefunded!)),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Le tirage n’a pas encore eu lieu pour cette période.',
                style: TextStyle(fontSize: 12, color: fMuted)),
          ),
      ]));
}
