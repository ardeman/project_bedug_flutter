import 'package:bedug/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BedugApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BedugApp()));
    expect(find.byType(BedugApp), findsOneWidget);
  });
}
