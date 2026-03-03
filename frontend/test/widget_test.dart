import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:migrate_x/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MigrateXApp()),
    );

    expect(find.text('Migrate X'), findsOneWidget);
    expect(find.text('Upload a Flutter Project'), findsOneWidget);
  });
}
