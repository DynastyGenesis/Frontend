// NON ASSEMBLÉ. Compte : profil, code destinataire, état américain.
import '../../data/models/api_models.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';

/// Codes des états américains acceptés par `PATCH /me` (+ DC).
const usStates = <String>[
  'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'DC', 'FL', 'GA', 'HI',
  'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN',
  'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH',
  'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA',
  'WV', 'WI', 'WY',
];

class AccountController extends FeatureController {
  AccountController(this._api);

  final BackendApi _api;
  ApiUser? user;

  /// Le backend n'a pas de recherche d'utilisateur : un expéditeur désigne son
  /// destinataire avec cet identifiant, que le destinataire lui transmet.
  String? get recipientCode => user?.id;

  Future<void> load() async {
    final result = await run(_api.me);
    if (result != null) {
      user = result;
      notifyListeners();
    }
  }

  Future<bool> saveState(String code) async {
    final result = await run(() => _api.updateState(code.trim().toUpperCase()));
    if (result == null) return false;
    user = result;
    notifyListeners();
    return true;
  }
}
