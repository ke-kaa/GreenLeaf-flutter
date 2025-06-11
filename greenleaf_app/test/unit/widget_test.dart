// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in the test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greenleaf_app/presentation/app.dart';
import 'package:greenleaf_app/application/auth_provider.dart';
import 'package:greenleaf_app/domain/user.dart';
import 'package:greenleaf_app/domain/auth_failure.dart';
import 'package:greenleaf_app/infrastructure/auth_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/test/path';
  }
}

class FakeAuthRepository implements AuthRepository {
  User? _user;
  
  @override
  Future<User> fetchProfile(String? token) async {
    if (_user == null) {
      throw AuthFailure('No user set');
    }
    return _user!;
  }
  
  @override
  Future<User> login(String email, String password) async {
    if (_user == null) {
      throw AuthFailure('No user set');
    }
    return _user!;
  }
  
  @override
  Future<User> signup(String email, String password, String confirmPassword) async {
    if (_user == null) {
      throw AuthFailure('No user set');
    }
    return _user!;
  }
  
  @override
  Future<void> logout() async {
    _user = null;
  }
  
  @override
  Future<void> deleteAccount() async {
    _user = null;
  }
  
  @override
  Future<User> updateProfile(Map<String, dynamic> data, [String? imagePath]) async {
    if (_user == null) {
      throw AuthFailure('No user set');
    }
    return _user!;
  }
  
  void setUser(User user) {
    _user = user;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProviderPlatform();

  setUpAll(() async {
    print('Setting up Hive for tests...');
    await Hive.initFlutter();
    print('Hive initialized');
    
    // Close any existing boxes
    if (Hive.isBoxOpen('auth')) {
      print('Closing existing auth box');
      await Hive.box('auth').close();
    }
    if (Hive.isBoxOpen('plants')) {
      print('Closing existing plants box');
      await Hive.box('plants').close();
    }
    if (Hive.isBoxOpen('observations')) {
      print('Closing existing observations box');
      await Hive.box('observations').close();
    }
    
    // Open boxes
    print('Opening Hive boxes...');
    await Hive.openBox('auth');
    await Hive.openBox('plants');
    await Hive.openBox('observations');
    print('Hive boxes opened successfully');
  });

  tearDownAll(() async {
    print('Cleaning up Hive after tests...');
    await Hive.close();
    print('Hive closed');
  });

  testWidgets('App should render without crashing', (WidgetTester tester) async {
    try {
      print('Starting widget test...');
      
      // Create a test user
      final testUser = User(
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        isActive: true,
      );

      final fakeRepo = FakeAuthRepository();
      fakeRepo.setUser(testUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            authProvider.overrideWithProvider(
              StateNotifierProvider<AuthNotifier, AuthState>(
                (ref) => AuthNotifier(fakeRepo, ref),
              ),
            ),
          ],
          child: const MaterialApp(
            home: GreenLeafApp(),
          ),
        ),
      );
      
      print('Widget tree built');
      
      // Wait for the widget to settle with a timeout
      await tester.pumpAndSettle(const Duration(seconds: 1));
      print('Widget settled');

      // Verify the app rendered with more specific assertions
      expect(find.byType(GreenLeafApp), findsOneWidget, reason: 'GreenLeafApp should be present');
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'Should show loading indicator initially');
      
      print('Test completed successfully');
    } catch (e, stack) {
      print('Test failed with error: $e\n$stack');
      rethrow;
    }
  });
}

// Helper class for testing
class TestAuthState extends AuthState {
  TestAuthState({super.user, super.isLoading = false, super.failure});

  TestAuthState copyWith({User? user, bool? isLoading, AuthFailure? failure}) {
    return TestAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }
}
