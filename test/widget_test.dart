import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/router/app_router.dart';
import 'package:myapp/services/local_database_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    final authService = MockAuthService();
    final router = createAppRouter(authService);

    // Initialize the local database service before running the test
    await LocalDatabaseService().init();

    when(authService.user).thenAnswer((_) => Stream.value(null));
    await tester.pumpWidget(MyApp(authService: authService, router: router));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
