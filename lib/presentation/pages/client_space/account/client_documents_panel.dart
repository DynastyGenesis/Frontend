import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'account_components.dart';
import 'document_export.dart';

Future<Uint8List> createClientPdf(ClientDocument d, ClientAccount a) async {
  final font =
      pw.Font.ttf(await rootBundle.load('assets/fonts/open_sans_regular.ttf'));
  final pdf = pw.Document();
  pdf.addPage(pw.Page(
      theme: pw.ThemeData.withFont(base: font),
      build: (_) =>
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Ships4US', style: const pw.TextStyle(fontSize: 28)),
            pw.SizedBox(height: 30),
            pw.Text(d.title.toUpperCase(),
                style: const pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 30),
            pw.Text('Client : ${a.name}'),
            pw.Text('Colis : ${d.parcel}'),
            pw.Text('Produit : ${d.product}'),
            pw.Text('New York, USA → Lomé, Togo'),
            pw.SizedBox(height: 30),
            if (d.category == 'Factures') ...[
              pw.Text(
                  'Prix du produit : ${d.parcel.endsWith('002') ? '98,00' : d.parcel.endsWith('001') ? '980,00' : '1 250,00'} USD'),
              pw.Text('Transport : 24,00 USD')
            ],
            pw.Spacer(),
            pw.Text('Document de démonstration • Ships4US',
                style: const pw.TextStyle(fontSize: 10))
          ])));
  return pdf.save();
}

class ClientDocumentsPanel extends StatefulWidget {
  final ClientDocuments store;
  final ClientAccount account;
  final ValueChanged<String> openParcel;
  final VoidCallback support;
  const ClientDocumentsPanel(
      {super.key,
      required this.store,
      required this.account,
      required this.openParcel,
      required this.support});
  @override
  State<ClientDocumentsPanel> createState() => _DocumentsState();
}

class _DocumentsState extends State<ClientDocumentsPanel> {
  String category = 'Tous', search = '', parcel = 'Tous les colis';
  int page = 0;
  late ClientDocument selected = widget.store.items.first;
  double zoom = 1;
  Future<void> upload({bool purchase = false}) async {
    try {
      final file = await openFile(acceptedTypeGroups: [
        const XTypeGroup(
            label: 'Documents',
            extensions: ['pdf', 'jpg', 'jpeg', 'png'],
            uniformTypeIdentifiers: ['public.pdf', 'public.jpeg', 'public.png'])
      ]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final error = widget.store.validateFile(file.name, bytes);
      if (!mounted) return;
      if (error != null) {
        accountNotice(context, error);
        return;
      }
      String ref = purchase ? 'SHP-2026-003' : 'SHP-2026-002',
          kind = purchase ? 'Autres' : 'Factures';
      final title = TextEditingController(
          text: purchase ? 'Justificatif d’achat' : file.name.split('.').first);
      final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, update) => AlertDialog(
                      title: const Text('Ajouter un document'),
                      content: SizedBox(
                          width: 400,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            TextField(
                                controller: title,
                                decoration: const InputDecoration(
                                    labelText: 'Nom du document')),
                            DropdownButtonFormField<String>(
                                initialValue: ref,
                                items: [
                                  'SHP-2026-001',
                                  'SHP-2026-002',
                                  'SHP-2026-003',
                                  'SHP-2026-004'
                                ]
                                    .map((v) => DropdownMenuItem(
                                        value: v, child: Text(v)))
                                    .toList(),
                                onChanged: (v) => update(() => ref = v!),
                                decoration: const InputDecoration(
                                    labelText: 'Colis associé')),
                            DropdownButtonFormField<String>(
                                initialValue: kind,
                                items: [
                                  'Factures',
                                  'Expédition',
                                  'Identité',
                                  'Autres'
                                ]
                                    .map((v) => DropdownMenuItem(
                                        value: v, child: Text(v)))
                                    .toList(),
                                onChanged: (v) => update(() => kind = v!),
                                decoration: const InputDecoration(
                                    labelText: 'Catégorie'))
                          ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler')),
                        FilledButton(
                            onPressed: () {
                              if (title.text.trim().isNotEmpty) {
                                Navigator.pop(ctx, true);
                              }
                            },
                            child: const Text('Ajouter'))
                      ])));
      if (ok == true && mounted) {
        final d = ClientDocument(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title.text.trim(),
            category: kind,
            parcel: ref,
            product: {
              'SHP-2026-001': 'iPhone 15 Pro',
              'SHP-2026-002': 'Chaussures Nike',
              'SHP-2026-003': 'MacBook Air',
              'SHP-2026-004': 'Sac à main'
            }[ref]!,
            format: file.name.split('.').last.toUpperCase(),
            size: '${(bytes.length / 1024).ceil()} Ko',
            date: '07 oct. 2026',
            bytes: bytes);
        widget.store.add(d);
        setState(() {
          selected = d;
          category = 'Tous';
          search = '';
          parcel = 'Tous les colis';
          page = 0;
        });
      }
      title.dispose();
    } catch (e) {
      if (mounted) {
        accountNotice(context, 'Impossible d’ajouter ce fichier. Réessayez.');
      }
    }
  }

  Future<void> download(ClientDocument d) async {
    try {
      final bytes = d.bytes ?? await createClientPdf(d, widget.account);
      final generated = d.bytes == null;
      final ok = await saveDocumentBytes(
          bytes,
          generated ? '${d.id}.pdf' : d.filename,
          generated || d.format == 'PDF'
              ? 'application/pdf'
              : 'image/${d.format.toLowerCase()}');
      if (mounted && ok) accountNotice(context, 'Document enregistré.');
    } catch (e) {
      if (mounted) accountNotice(context, 'Le téléchargement n’a pas abouti.');
    }
  }

  Future<void> printDoc() async {
    try {
      final bytes = selected.bytes != null && selected.format == 'PDF'
          ? selected.bytes!
          : selected.bytes != null
              ? await imagePdf(selected.bytes!)
              : await createClientPdf(selected, widget.account);
      await Printing.layoutPdf(onLayout: (_) => Future.value(bytes));
    } catch (e) {
      if (mounted) {
        accountNotice(context, 'Impression indisponible sur cet appareil.');
      }
    }
  }

  Future<Uint8List> imagePdf(Uint8List bytes) async {
    final p = pw.Document();
    p.addPage(pw.Page(
        build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(bytes)))));
    return p.save();
  }

  void view(ClientDocument d) {
    setState(() => selected = d);
    showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
            child: SizedBox(
                width: 750,
                height: 760,
                child: Column(children: [
                  ListTile(
                      title: Text(d.title),
                      trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx))),
                  Expanded(
                      child: d.bytes != null
                          ? (d.format == 'PDF'
                              ? PdfPreview(
                                  build: (_) => Future.value(d.bytes!),
                                  allowPrinting: false,
                                  allowSharing: false)
                              : Image.memory(d.bytes!,
                                  errorBuilder: (_, e, s) =>
                                      const Text('Aperçu indisponible')))
                          : invoice(d)),
                  Padding(
                      padding: const EdgeInsets.all(12),
                      child: ab('Télécharger le document', () => download(d),
                          icon: Icons.download))
                ]))));
  }

  Widget invoice(ClientDocument d) => Container(
      color: const Color(0xFFF0F4F9),
      padding: const EdgeInsets.all(18),
      child: Container(
          padding: const EdgeInsets.all(22),
          color: Colors.white,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.view_in_ar, color: accountBlue, size: 26),
              const SizedBox(width: 8),
              at('Ships4US', bold: true, size: 20)
            ]),
            ag(10),
            at(d.title.toUpperCase(), bold: true, size: 14),
            ag(10),
            al('Client', widget.account.name),
            al('Référence', d.parcel),
            const Divider(),
            al('Description', 'Montant'),
            al(d.product, d.parcel.endsWith('002') ? '98,00 USD' : '—'),
            if (d.category == 'Factures') al('Frais de transport', '24,00 USD'),
            const Divider(),
            if (d.parcel.endsWith('002') && d.category == 'Factures')
              al('TOTAL PAYÉ', '122,00 USD'),
            ag(10),
            at('New York, USA  →  Lomé, Togo', size: 10, color: accountMuted),
            ag(10),
            at('Document de démonstration', size: 9, color: accountMuted)
          ])));
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final filtered = widget.store.items
            .where((d) =>
                (category == 'Tous' || d.category == category) &&
                (parcel == 'Tous les colis' || d.parcel == parcel) &&
                '${d.title} ${d.product} ${d.parcel}'
                    .toLowerCase()
                    .contains(search.toLowerCase()))
            .toList();
        final visible = filtered.skip(page * 5).take(5).toList();
        final left = Column(children: [
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: [
                'Tous',
                'Factures',
                'Expédition',
                'Identité',
                'Autres'
              ]
                      .map((s) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                              label: Text(
                                  '$s  ${s == 'Tous' ? widget.store.items.length : widget.store.items.where((d) => d.category == s).length}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: category == s
                                          ? Colors.white
                                          : accountNavy)),
                              selected: category == s,
                              showCheckmark: false,
                              selectedColor: accountBlue,
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                              onSelected: (_) => setState(() {
                                    category = s;
                                    page = 0;
                                  }))))
                      .toList())),
          ag(12),
          ap(Column(children: [
            Row(children: [
              Expanded(
                  child: TextField(
                      onChanged: (v) => setState(() {
                            search = v;
                            page = 0;
                          }),
                      decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.search, size: 18),
                          hintText: 'Rechercher un document…',
                          hintStyle: TextStyle(fontSize: 11),
                          border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                      initialValue: parcel,
                      isExpanded: true,
                      style: const TextStyle(
                          fontFamily: "Open Sans",
                          fontSize: 10,
                          color: accountNavy),
                      items: [
                        'Tous les colis',
                        'SHP-2026-001',
                        'SHP-2026-002',
                        'SHP-2026-003',
                        'SHP-2026-004'
                      ]
                          .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() {
                            parcel = v!;
                            page = 0;
                          }),
                      decoration: const InputDecoration(
                          isDense: true, border: OutlineInputBorder())))
            ]),
            ag(10),
            LayoutBuilder(
                builder: (_, box) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                        width: box.maxWidth < 620 ? 620 : box.maxWidth,
                        child: Column(children: [
                          Container(
                              color: accountTint,
                              padding: const EdgeInsets.all(10),
                              child: Row(children: [
                                Expanded(
                                    flex: 33,
                                    child:
                                        at('Document', size: 10, bold: true)),
                                Expanded(
                                    flex: 22,
                                    child: at('Colis', size: 10, bold: true)),
                                Expanded(
                                    flex: 16,
                                    child:
                                        at('Ajouté le', size: 10, bold: true)),
                                Expanded(
                                    flex: 16,
                                    child: at('Statut', size: 10, bold: true)),
                                Expanded(
                                    flex: 13,
                                    child: at('Actions', size: 10, bold: true))
                              ])),
                          ...visible.map((d) => InkWell(
                              onTap: () => setState(() => selected = d),
                              child: Container(
                                  color:
                                      d.id == selected.id ? accountTint : null,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: Row(children: [
                                    Expanded(
                                        flex: 33,
                                        child: Row(children: [
                                          Icon(Icons.description_outlined,
                                              color: d.status == 'À vérifier'
                                                  ? Colors.orange
                                                  : accountBlue,
                                              size: 23),
                                          const SizedBox(width: 7),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                at(d.title,
                                                    bold: true, size: 11),
                                                ag(4),
                                                at('${d.format} · ${d.size}',
                                                    size: 9,
                                                    color: accountMuted)
                                              ]))
                                        ])),
                                    Expanded(
                                        flex: 22,
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              at(d.parcel,
                                                  size: 10, color: accountBlue),
                                              at(d.product,
                                                  size: 9, color: accountMuted)
                                            ])),
                                    Expanded(
                                        flex: 16,
                                        child: at(d.date,
                                            size: 9, color: accountMuted)),
                                    Expanded(
                                        flex: 16,
                                        child: ach(d.status,
                                            color: d.status == 'À vérifier'
                                                ? Colors.orange
                                                : const Color(0xFF17A46B))),
                                    Expanded(
                                        flex: 13,
                                        child: Row(children: [
                                          IconButton(
                                              tooltip: 'Voir ${d.title}',
                                              constraints:
                                                  const BoxConstraints.tightFor(
                                                      width: 28, height: 28),
                                              style: IconButton.styleFrom(
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  minimumSize:
                                                      const Size(28, 28)),
                                              padding: const EdgeInsets.all(4),
                                              icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 17,
                                                  color: accountBlue),
                                              onPressed: () => view(d)),
                                          IconButton(
                                              tooltip: 'Télécharger ${d.title}',
                                              constraints:
                                                  const BoxConstraints.tightFor(
                                                      width: 28, height: 28),
                                              style: IconButton.styleFrom(
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  minimumSize:
                                                      const Size(28, 28)),
                                              padding: const EdgeInsets.all(4),
                                              icon: const Icon(Icons.download,
                                                  size: 17, color: accountBlue),
                                              onPressed: () => download(d))
                                        ]))
                                  ]))))
                        ])))),
            if (visible.isEmpty)
              Padding(
                  padding: const EdgeInsets.all(30),
                  child: at('Aucun document trouvé.')),
            ag(12),
            Row(children: [
              Expanded(
                  child: at(
                      '${visible.length} documents sur ${filtered.length}',
                      size: 10,
                      color: accountMuted)),
              ...List.generate(
                  (filtered.length / 5).ceil(),
                  (i) => TextButton(
                      onPressed: () => setState(() => page = i),
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: page == i ? accountBlue : accountMuted))))
            ])
          ])),
          ag(10),
          if (widget.store.purchasePending) ...[
            ap(
                Row(children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        at('Une pièce à compléter', bold: true),
                        ag(5),
                        at('Ajoutez le justificatif d’achat du MacBook Air\nColis SHP-2026-003',
                            size: 10, color: accountMuted)
                      ])),
                  ab('Ajouter la pièce', () => upload(purchase: true),
                      outline: true)
                ]),
                color: const Color(0xFFFFF7E8)),
            ag(10)
          ],
          ap(Column(children: [
            const Icon(Icons.cloud_upload_outlined,
                color: accountBlue, size: 35),
            ag(8),
            at('Ajouter vos fichiers ici', bold: true),
            ag(8),
            ab('Choisir un fichier', upload, outline: true),
            ag(10),
            at('PDF, JPG, PNG · Taille maximale : 10 Mo',
                size: 10, color: accountMuted)
          ]))
        ]);
        final right = Column(children: [
          ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ah('Aperçu du document', Icons.description_outlined),
            ag(10),
            at(selected.title, bold: true, size: 15),
            at('${selected.parcel} · ${selected.product}',
                size: 10, color: accountMuted),
            ag(10),
            if (selected.bytes != null && selected.format != 'PDF')
              SizedBox(
                  height: 300,
                  child: Image.memory(selected.bytes!,
                      errorBuilder: (_, e, s) => at('Aperçu indisponible')))
            else if (selected.bytes != null)
              SizedBox(
                  height: 300,
                  child: Center(
                      child: ab('Ouvrir le PDF', () => view(selected),
                          outline: true, icon: Icons.description_outlined)))
            else
              GestureDetector(
                  onTap: () => view(selected),
                  child: ClipRect(
                      child: Transform.scale(
                          scale: zoom, child: invoice(selected)))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              at('1 / 1', size: 10, color: accountMuted),
              Row(children: [
                IconButton(
                    onPressed: () =>
                        setState(() => zoom = (zoom - .1).clamp(.7, 1.4)),
                    icon: const Icon(Icons.remove, size: 15)),
                at('${(zoom * 100).round()} %', size: 10),
                IconButton(
                    onPressed: () =>
                        setState(() => zoom = (zoom + .1).clamp(.7, 1.4)),
                    icon: const Icon(Icons.add, size: 15))
              ])
            ]),
            const Divider(),
            al('Type de document', selected.title),
            al('Colis associé', selected.parcel),
            al('Ajouté le', selected.date),
            al('Format / taille', '${selected.format} · ${selected.size}'),
            ag(12),
            SizedBox(
                width: double.infinity,
                child: ab('Télécharger le document', () => download(selected),
                    icon: Icons.download)),
            ag(10),
            Row(children: [
              Expanded(
                  child: ab(
                      'Voir le colis', () => widget.openParcel(selected.parcel),
                      outline: true, icon: Icons.view_in_ar)),
              const SizedBox(width: 10),
              Expanded(
                  child: ab('Imprimer', printDoc,
                      outline: true, icon: Icons.print_outlined))
            ])
          ])),
          ag(10),
          accountHelp(widget.support)
        ]);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.description_outlined,
                color: accountBlue, size: 34),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  at('Mes documents', bold: true, size: 27),
                  at('Retrouvez vos factures, reçus et pièces liées à vos colis.',
                      size: 12, color: accountMuted)
                ])),
            ab('Ajouter un document', upload, icon: Icons.add)
          ]),
          ag(18),
          ap(
              Row(children: [
                const Icon(Icons.verified_user_outlined,
                    color: accountBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      at('Vos documents regroupés au même endroit.',
                          bold: true),
                      at('Associez chaque pièce au colis concerné.',
                          size: 11, color: accountMuted)
                    ]))
              ]),
              color: accountTint),
          ag(18),
          ac(left, right, c.maxWidth, flex: 58)
        ]);
      });
}
