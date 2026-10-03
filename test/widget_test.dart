import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fleettrack/app/app.dart';

void main() {
  testWidgets('FleetTrackApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FleetTrackApp(),
      ),
    );
    expect(find.byType(FleetTrackApp), findsOneWidget);
  });
}
