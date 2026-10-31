import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/data/app_services.dart';
import 'package:barrel_go/features/client_flow.dart';
import 'package:barrel_go/features/driver_flow.dart';

void main() {
  testWidgets('sans backend, les pages gardent leur écran d’origine',
      (tester) async {
    AppServices.instance = null;
    late BuildContext captured;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        captured = context;
        return const SizedBox();
      }),
    ));
    for (final page in backendClientPages) {
      expect(openClientBackendScreen(captured, page), isFalse);
    }
    expect(openClientBackendScreen(captured, 'Notifications'), isFalse);
    for (final page in backendDriverPages) {
      expect(openDriverBackendScreen(captured, page), isFalse);
    }
  });
}
