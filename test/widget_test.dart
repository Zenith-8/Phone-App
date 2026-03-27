import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:liftelligence/main.dart';
import 'package:liftelligence/services/app_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Loads dashboard when session is already paired', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'liftelligence_seen_onboarding': true,
      'liftelligence_signed_in': true,
      'liftelligence_user_email': 'demo@liftelligence.local',
      'liftelligence_paired': true,
      'liftelligence_paired_offline': true,
      'liftelligence_pair_host': '127.0.0.1',
      'liftelligence_pair_port': 5001,
      'liftelligence_pair_token': 'DEMO1234',
    });

    final session = AppSession();
    await session.load();

    await tester.pumpWidget(LiftelligenceApp(session: session));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.textContaining('Hi,'), findsOneWidget);
    expect(find.text('Workouts'), findsOneWidget);
  });
}
