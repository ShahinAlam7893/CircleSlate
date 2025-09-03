class Urls {
  static const String baseUrl = 'http://72.60.26.57/api';

  static const String register = '$baseUrl/auth/register/';
  static const String login = '$baseUrl/auth/login/';
  static const String forgotPassword = '$baseUrl/auth/forgot-password/';
  static const String verifyOtp = '$baseUrl/auth/verify-otp/';
  static const String resetPassword = '$baseUrl/auth/change-password/';
  static const String setnewpassword = '$baseUrl/auth/set-new-password/';
  static const String userProfile = '$baseUrl/auth/profile/';
  static const String updateProfile = '$baseUrl/auth/profile/update/';
  static const String conversations = '$baseUrl/auth/conversations';

  static const String fetchUpcomingEvents = '$baseUrl/event/events/';
  static const String createEvents = '$baseUrl/event/events/create/';
  static const String getAvailability = '$baseUrl/calendar/user-month-availability/';
  static const String fatch_upcoming_events = '$baseUrl/event/events/';
  static const String Create_events = '$baseUrl/event/events/create/';
}
