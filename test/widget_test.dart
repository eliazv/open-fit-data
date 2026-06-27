import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_fit_data/app/app.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OpenFitDataApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
