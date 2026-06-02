import 'package:flutter_test/flutter_test.dart';
import 'package:mini_teamflow/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Login ekranı açılır', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MiniTeamFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('TeamFlow'), findsWidgets);
    expect(find.text('Giriş Yap'), findsOneWidget);
  });
}
