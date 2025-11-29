import 'dart:io';
import 'package:circleslate/data/services/user_service.dart';
import 'package:circleslate/data/services/api_base_helper.dart';

void main() async {
  print("🧪 Testing Registration API...");
  
  final authService = AuthService(ApiBaseHelper());
  
  try {
    final response = await authService.registerUser(
      fullName: "Test User Debug",
      email: "testdebug@example.com",
      password: "testpass123",
      confirmPassword: "testpass123",
      profileImage: null,
    );
    
    print("✅ Test completed successfully!");
    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");
  } catch (e) {
    print("❌ Test failed with error: $e");
    print("Error type: ${e.runtimeType}");
  }
}