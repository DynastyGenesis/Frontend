import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

const accountBlue = Color(0xFF005BF3),
    accountNavy = Color(0xFF08264C),
    accountMuted = Color(0xFF72829C),
    accountTint = Color(0xFFEAF4FF),
    accountBorder = Color(0xFFE0EAF6);
Widget at(String s,
        {double size = 13, bool bold = false, Color color = accountNavy}) =>
    Text(s,
        style: TextStyle(
            fontSize: size,
            height: 1.35,
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400));
Widget ag([double size = 10]) => SizedBox(height: size);
Widget ap(Widget child,
        {Color color = Colors.white, double pad = 14}) =>
    Container(
        width: double.infinity,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accountBorder)),
        child: Material(type: MaterialType.transparency, child: child));
Widget ab(String s, VoidCallback? action,
    {bool outline = false, IconData? icon, Color? color}) {
  final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 8)],
        Flexible(
            child: Text(s,
                maxLines: 2,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))
      ]);
  return SizedBox(
      height: 40,
      child: outline
          ? OutlinedButton(
              onPressed: action,
              style: OutlinedButton.styleFrom(
                  foregroundColor: color ?? accountBlue,
                  side: BorderSide(
                      color: (color ?? accountBlue).withValues(alpha: .65)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: child)
          : FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(
                  backgroundColor: color ?? accountBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: child));
}

Widget ach(String label, {Color color = const Color(0xFF17A46B)}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18)),
    child: at(label, size: 11, color: color));
Widget al(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: at(label, size: 11, color: accountMuted)),
      Flexible(child: at(value, size: 11))
    ]));
Widget ah(String title, IconData icon, {Widget? trailing}) => Row(children: [
      Icon(icon, color: accountBlue, size: 23),
      const SizedBox(width: 10),
      Expanded(child: at(title, size: 16, bold: true)),
      if (trailing != null) trailing
    ]);
Widget ac(Widget left, Widget right, double width, {int flex = 60}) =>
    width >= 950
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: flex, child: left),
            const SizedBox(width: 16),
            Expanded(flex: 100 - flex, child: right)
          ])
        : Column(children: [left, ag(16), right]);
Widget accountHelp(VoidCallback onSupport) => ap(
    Row(children: [
      const Icon(Icons.headset_mic_outlined, color: accountBlue, size: 31),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        at('Besoin d’aide ?', bold: true, size: 15),
        ag(5),
        at('Une question ? Notre équipe vous accompagne.',
            size: 11, color: accountMuted)
      ])),
      TextButton(
          onPressed: onSupport,
          child: at('Contacter le support →', size: 11, color: accountBlue))
    ]),
    color: accountTint);
void accountNotice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

class ClientAccount extends ChangeNotifier {
  String name = 'Koffi Mensah',
      email = 'koffi.mensah@email.com',
      phone = '+228 90 12 34 56',
      country = 'Togo',
      address = 'Tokoin, Lomé, Togo',
      collection = 'New York, USA',
      currency = 'USD',
      language = 'Français',
      timezone = 'Africa/Lomé · UTC+0';
  bool shipmentAlerts = true,
      paymentAlerts = true,
      promotions = false,
      twoFactorDemo = false;
  Uint8List? avatar;
  void saveProfile(
      {required String newName,
      required String newEmail,
      required String newPhone,
      required String newCountry}) {
    name = newName;
    email = newEmail;
    phone = newPhone;
    country = newCountry;
    notifyListeners();
  }

  void changed() => notifyListeners();
  void reset() {
    name = 'Koffi Mensah';
    email = 'koffi.mensah@email.com';
    phone = '+228 90 12 34 56';
    country = 'Togo';
    address = 'Tokoin, Lomé, Togo';
    collection = 'New York, USA';
    currency = 'USD';
    language = 'Français';
    timezone = 'Africa/Lomé · UTC+0';
    shipmentAlerts = true;
    paymentAlerts = true;
    promotions = false;
    twoFactorDemo = false;
    avatar = null;
    notifyListeners();
  }
}

class ClientDocument {
  final String id, title, category, parcel, product, format, size, date;
  final String status;
  final Uint8List? bytes;
  const ClientDocument(
      {required this.id,
      required this.title,
      required this.category,
      required this.parcel,
      required this.product,
      this.format = 'PDF',
      this.size = '250 Ko',
      this.date = '05 oct. 2026',
      this.status = 'Disponible',
      this.bytes});
  String get filename =>
      '${title.replaceAll(RegExp(r"[^a-zA-Z0-9_-]"), '_')}_$parcel.${format.toLowerCase()}';
}

class ClientDocuments extends ChangeNotifier {
  final items = <ClientDocument>[
    const ClientDocument(
        id: 'doc1',
        title: 'Facture commerciale',
        category: 'Factures',
        parcel: 'SHP-2026-002',
        product: 'Chaussures Nike',
        size: '250 Ko'),
    const ClientDocument(
        id: 'doc2',
        title: 'Bon d’expédition',
        category: 'Expédition',
        parcel: 'SHP-2026-002',
        product: 'Chaussures Nike',
        size: '180 Ko'),
    const ClientDocument(
        id: 'doc3',
        title: 'Facture de transport',
        category: 'Factures',
        parcel: 'SHP-2026-001',
        product: 'iPhone 15 Pro',
        size: '145 Ko',
        date: '04 oct. 2026'),
    const ClientDocument(
        id: 'doc4',
        title: 'Justificatif d’achat',
        category: 'Autres',
        parcel: 'SHP-2026-003',
        product: 'MacBook Air',
        size: '320 Ko',
        date: '02 oct. 2026',
        status: 'À vérifier'),
    const ClientDocument(
        id: 'doc5',
        title: 'Pièce d’identité',
        category: 'Identité',
        parcel: 'SHP-2026-004',
        product: 'Sac à main',
        format: 'JPG',
        size: '420 Ko',
        date: '01 oct. 2026',
        status: 'Validé'),
    const ClientDocument(
        id: 'doc6',
        title: 'Facture commerciale',
        category: 'Factures',
        parcel: 'SHP-2026-003',
        product: 'MacBook Air',
        size: '280 Ko',
        date: '02 oct. 2026'),
    const ClientDocument(
        id: 'doc7',
        title: 'Bon d’expédition',
        category: 'Expédition',
        parcel: 'SHP-2026-001',
        product: 'iPhone 15 Pro',
        size: '165 Ko',
        date: '04 oct. 2026'),
    const ClientDocument(
        id: 'doc8',
        title: 'Bordereau de livraison',
        category: 'Expédition',
        parcel: 'SHP-2026-004',
        product: 'Sac à main',
        size: '150 Ko',
        date: '01 oct. 2026')
  ];
  bool purchasePending = true;
  String? validateFile(String name, Uint8List bytes) {
    final extension = name.split('.').last.toLowerCase();
    if (!['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
      return 'Formats acceptés : PDF, JPG et PNG.';
    }
    if (bytes.isEmpty) {
      return 'Ce fichier est vide.';
    }
    if (bytes.length > 10 * 1024 * 1024) {
      return 'Le document dépasse la limite de 10 Mo.';
    }
    if (extension == 'pdf' &&
        (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-')) {
      return 'Le fichier sélectionné n’est pas un PDF valide.';
    }
    if (['jpg', 'jpeg'].contains(extension) &&
        (bytes.length < 3 ||
            bytes[0] != 255 ||
            bytes[1] != 216 ||
            bytes[2] != 255)) {
      return 'Le fichier sélectionné n’est pas une image JPG valide.';
    }
    if (extension == 'png' &&
        (bytes.length < 8 ||
            !listEquals(
                bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]))) {
      return 'Le fichier sélectionné n’est pas une image PNG valide.';
    }
    return null;
  }

  void add(ClientDocument doc) {
    items.insert(0, doc);
    if (doc.parcel == 'SHP-2026-003' && doc.title == 'Justificatif d’achat') {
      purchasePending = false;
    }
    notifyListeners();
  }
}
