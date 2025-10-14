import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

void main() {
  testWidgets('app builds', (WidgetTester tester) async {
    final authService = MockAuthService();
    // Corrected to use the new 'user' stream instead of the old 'authStateChanges'
    when(authService.user).thenAnswer((_) => Stream.value(null));
    await tester.pumpWidget(MyApp(authService: authService));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
