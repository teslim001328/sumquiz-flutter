import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/local_database_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    // Initialize the local database service before running the test
    await LocalDatabaseService().init();

    final mockAuthService = MockAuthService();
    when(mockAuthService.authStateChanges).thenAnswer((_) => Stream.value(null));
    when(mockAuthService.currentUser).thenReturn(null);

    // MyApp now uses providers internally, so we don't pass arguments.
    await tester.pumpWidget(MyApp(authService: mockAuthService));
    
    expect(find.byType(MyApp), findsOneWidget);
  });
}
