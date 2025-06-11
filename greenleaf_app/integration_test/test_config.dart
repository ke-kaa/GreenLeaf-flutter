import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class TestConfig {
  static Future<void> setup() async {
    // Initialize the integration test binding
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    
    // Add any global test setup here
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Set up any test environment variables or configurations
    // For example, you might want to set up mock services or test data
  }

  static Future<void> teardown() async {
    // Add any cleanup code here
    // For example, clearing test data or resetting state
  }
} 