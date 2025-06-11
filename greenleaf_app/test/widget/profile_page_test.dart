import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenleaf_app/application/auth_provider.dart';
import 'package:greenleaf_app/domain/auth_failure.dart';
import 'package:greenleaf_app/domain/user.dart';
import 'package:greenleaf_app/presentation/profile_page.dart';
import 'package:greenleaf_app/infrastructure/auth_repository.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(AuthState initialState, Ref ref)
      : super(_FakeAuthRepository(), ref) {
    state = initialState;
  }
  @override
  Future<void> updateProfile(Map<String, dynamic> data, [String? imagePath]) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> deleteAccount() async {}
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<User> fetchProfile(String? token) async => throw UnimplementedError();
  @override
  Future<User> login(String email, String password) async => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<User> signup(String email, String password, String confirmPassword) async => throw UnimplementedError();
  @override
  Future<User> updateProfile(Map<String, dynamic> data, [String? imagePath]) async => throw UnimplementedError();
}

void main() {
  final testUser = User(
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    birthdate: DateTime(1990, 1, 1),
    gender: 'Male',
    phoneNumber: '1234567890',
    profileImage: 'https://example.com/profile.jpg',
    isSuperuser: false,
    isStaff: false,
    isActive: true,
  );

  Widget createWidgetUnderTest({required AuthState authState, Map<String, WidgetBuilder>? routes}) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier(authState, ref)),
      ],
      child: MaterialApp(
        home: const ProfilePage(),
        routes: routes ?? const {},
      ),
    );
  }

  testWidgets('displays user information correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(authState: AuthState(user: testUser)));
    await tester.pumpAndSettle();
    expect(find.text('John'), findsOneWidget);
    expect(find.text('Doe'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
  });

  testWidgets('shows loading indicator when auth state is loading', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(authState: AuthState(user: null, isLoading: true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('enables editing mode when edit button is pressed', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(authState: AuthState(user: testUser)));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).enabled, isFalse);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).enabled, isTrue);
  });

  testWidgets('shows save button in edit mode', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(authState: AuthState(user: testUser)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.save), findsNothing);
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.save), findsOneWidget);
  });

  testWidgets('shows delete account confirmation dialog', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(authState: AuthState(user: testUser)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to delete your account?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('calls logout when logout button is pressed', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      authState: AuthState(user: testUser),
      routes: {'/': (_) => const Scaffold(body: Text('Login Page'))},
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();
    expect(find.text('Login Page'), findsOneWidget);
  });

  testWidgets('displays error message when auth state has failure', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      authState: AuthState(user: testUser, failure: AuthFailure('Test error message')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Test error message'), findsOneWidget);
  });
} 