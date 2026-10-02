import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportsphere/main.dart';

void main() {
  testWidgets('App launches and renders splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const App());

    expect(find.text('SportSphere'), findsOneWidget);
    expect(find.text('Your Game, Your Score'), findsOneWidget);

    // Fast-forward past splash timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
