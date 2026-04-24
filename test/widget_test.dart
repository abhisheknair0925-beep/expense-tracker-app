import 'package:flutter_test/flutter_test.dart';
import 'package:expence_tracker_app/main.dart';

void main() {
  testWidgets('App launches', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Expense Tracker'), findsAny);
  });
}
