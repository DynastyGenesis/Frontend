import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/presentation/widgets/google_logo.dart';

void main() {
  testWidgets('le logo Google est un SVG à la taille demandée', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GoogleLogo(size: 24))));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(GoogleLogo)), const Size(24, 24));
    expect(tester.takeException(), isNull);
  });
}
