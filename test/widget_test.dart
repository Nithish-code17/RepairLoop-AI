import 'package:flutter_test/flutter_test.dart';
import 'package:repairloop_ai/app.dart';
import 'package:repairloop_ai/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows RepairLoop onboarding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(firebaseReady: false),
          ),
        ],
        child: const RepairLoopApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('A trusted service record for every device.'),
      findsOneWidget,
    );
    expect(find.text('Create account'), findsOneWidget);
  });
}
