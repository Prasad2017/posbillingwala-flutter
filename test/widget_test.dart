import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_billingwala_v2/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash then licence login gate', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PosBillingwalaApp(),
      ),
    );

    expect(find.text('POS Billingwala'), findsWidgets);

    // Splash delay + SharedPreferences bootstrap + redirect frames.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Licence key'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
