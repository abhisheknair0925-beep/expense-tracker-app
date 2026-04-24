import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_app1/main.dart';

void main() {
  testWidgets('App launches', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Expense Tracker'), findsAny);
  });
}
