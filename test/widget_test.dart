import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportsphere/main.dart';

void main() {
  testWidgets('App launches and renders splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO SPORTSPHERE'), findsOneWidget);
    expect(find.textContaining('Your Game,'), findsOneWidget);

    // Fast-forward past splash timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
