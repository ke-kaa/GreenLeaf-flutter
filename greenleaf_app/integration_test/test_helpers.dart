import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:greenleaf_app/domain/plant.dart';
import 'package:greenleaf_app/domain/observation.dart';
import 'package:greenleaf_app/presentation/profile_page.dart';

class TestHelpers {
  static Future<void> login(WidgetTester tester) async {
    // Wait for login form to be visible
    await tester.pumpAndSettle();
    
    // Debug: print current widgets
    print('DEBUG: Current widgets before login:');
    tester.allWidgets.forEach((w) => print(w.toStringShort()));
    
    // Find email and password fields by their hint text
    final emailField = find.widgetWithText(TextField, 'Email');
    final passwordField = find.widgetWithText(TextField, 'Password');
    
    expect(emailField, findsOneWidget, reason: 'Email field not found');
    expect(passwordField, findsOneWidget, reason: 'Password field not found');

    // Enter credentials
    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordField, 'password123');
    await tester.pumpAndSettle();

    // Debug: print widgets after entering credentials
    print('DEBUG: Widgets after entering credentials:');
    tester.allWidgets.forEach((w) => print(w.toStringShort()));

    // Find and tap login button by its text
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    expect(loginButton, findsOneWidget, reason: 'Login button not found');
    await tester.tap(loginButton);
    
    // Wait longer for login to complete and navigation to appear
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Debug: print widgets after login attempt
    print('DEBUG: Widgets after login attempt:');
    tester.allWidgets.forEach((w) => print(w.toStringShort()));
    
    // Verify we're logged in by checking for bottom navigation
    final bottomNav = find.byType(BottomNavigationBar);
    if (bottomNav.evaluate().isEmpty) {
      print('DEBUG: BottomNavigationBar not found after login. Current widgets:');
      tester.allWidgets.forEach((w) => print(w.toStringShort()));
      throw Exception('Login failed - BottomNavigationBar not found');
    }
  }

  static Future<void> navigateToTab(WidgetTester tester, int index) async {
    // Wait for bottom navigation bar to be visible
    await tester.pumpAndSettle();
    
    // Debug: print widget tree if navigation fails
    if (find.byType(BottomNavigationBar).evaluate().isEmpty) {
      print('DEBUG: BottomNavigationBar not found. Current widgets:');
      tester.allWidgets.forEach((w) => print(w.toStringShort()));
    }
    
    final bottomNav = find.byType(BottomNavigationBar);
    expect(bottomNav, findsOneWidget);

    // Add a small delay to ensure the navigation bar is fully rendered
    await Future.delayed(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Find the navigation bar and tap the item at the specified index
    final navBar = tester.widget<BottomNavigationBar>(bottomNav);
    final items = navBar.items;
    expect(items.length, greaterThan(index), reason: 'Navigation index out of bounds');

    // Get the icon data from the navigation item
    final icon = items[index].icon;
    if (icon is Icon && icon.icon != null) {
      await tester.tap(find.byIcon(icon.icon!));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // If we're navigating to profile (index 1), we need to wait for the new page
      if (index == 1) {
        expect(find.byType(ProfilePage), findsOneWidget);
      }
    } else {
      throw Exception('Navigation item icon is not a valid Icon widget');
    }
  }

  static Future<void> addPlantObservation(WidgetTester tester) async {
    // Navigate to plants tab
    await navigateToTab(tester, 0);
    await tester.pumpAndSettle();

    // Tap add button
    final addButton = find.byType(FloatingActionButton);
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Fill out the form
    await tester.enterText(find.byType(TextField).first, 'Test Plant');
    await tester.enterText(find.byType(TextField).last, 'Test Observation');
    await tester.pumpAndSettle();

    // Submit the form - find the green submit button
    final submitButton = find.byWidgetPredicate(
      (widget) => widget is ElevatedButton && 
                  widget.style?.backgroundColor?.resolve({}) == Colors.green,
    );
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}