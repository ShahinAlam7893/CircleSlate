class Urls {
  // Base URLs
  static const String baseUrl = 'https://app.circleslate.com';
  static const String baseWsUrl = 'ws://app.circleslate.com/ws';
  // static const String baseAppUrl = 'https://app.circleslate.com';

  // ========== AUTHENTICATION ENDPOINTS ==========
  static const String register = '$baseUrl/api/auth/register/';
  static const String login = '$baseUrl/api/auth/login/';
  static const String forgotPassword = '$baseUrl/api/auth/forgot-password/';
  static const String verifyOtp = '$baseUrl/api/auth/verify-otp/';
  static const String resetPassword = '$baseUrl/api/auth/change-password/';
  static const String setNewPassword = '$baseUrl/api/auth/set-new-password/';
  static const String resetPasswordAlt = '$baseUrl/api/auth/reset-password/';

  // ========== USER PROFILE ENDPOINTS ==========
  static const String userProfile = '$baseUrl/api/auth/profile/';
  static const String updateProfile = '$baseUrl/api/auth/profile/update/';
  static const String getUserById = '$baseUrl/api/auth/user/'; // + userId
  static const String users = '$baseUrl/api/users/';
  static const String children = '$baseUrl/api/auth/children/';

  // ========== CHAT & CONVERSATION ENDPOINTS ==========
  static const String conversations = '$baseUrl/api/auth/conversations';
  static const String chatConversations = '$baseUrl/api/chat/conversations/';
  static const String createConversation =
      '$baseUrl/api/chat/conversations/create/';
  static const String createGroupConversation =
      '$baseUrl/api/conversations/create-group/';
  static const String conversationMessages =
      '$baseUrl/api/conversations/'; // + conversationId + /messages/
  static const String conversationMembers =
      '$baseUrl/api/chat/conversations/'; // + conversationId + /members/
  static const String sendMessage =
      '$baseUrl/api/chat/messages/'; // + conversationId + /send/
  static const String addMembers =
      '$baseUrl/api/chat/conversations/'; // + conversationId + /add-members/
  static const String removeMember =
      '$baseUrl/api/chat/conversations/'; // + conversationId + /remove-member/
  static const String promoteAdmin =
      '$baseUrl/api/chat/conversations/'; // + conversationId + /promote-admin/
  static const String leaveGroup =
      '$baseUrl/api/chat/conversations/'; // + conversationId + /leave/
  static const String deleteGroup =
      '$baseUrl/api/chat/conversations/'; // + conversationId + /delete-group/

  static String markMessageAsRead(String messageId) =>
      '$baseUrl/api/chat/messages/$messageId/read/';

  static const String changeGroupName =
      '$baseUrl/api/chat/conversations/'; // + conversationId + /change-name/
  static const String searchUsers = '$baseUrl/api/chat/search-users/';
  static const String userGroups = '$baseUrl/api/chat/groups/user-groups/';

  // ========== WEBSOCKET ENDPOINTS ==========
  static const String chatWebSocket =
      '$baseWsUrl/chat/'; // + conversationId + /?token=
  static const String groupChatWebSocket =
      '$baseWsUrl/chat/conversations/'; // + conversationId + /?token=

  // ========== EVENT MANAGEMENT ENDPOINTS ==========
  static const String fetchUpcomingEvents = '$baseUrl/api/event/events/';
  static const String createEvents = '$baseUrl/api/event/events/create/';
  static const String eventDetails =
      '$baseUrl/api/event/events/'; // + eventId + /
  static const String respondToEvent =
      '$baseUrl/api/event/events/'; // + eventId + /respond/
  static const String requestRide =
      '$baseUrl/api/event/events/'; // + eventId + /request_ride/
  static const String rideRequests =
      '$baseUrl/api/event/events/'; // + eventId + /ride-requests/
  static const String acceptRide =
      '$baseUrl/api/event/ride-requests/'; // + rideId + /accept/

  // ========== CALENDAR & AVAILABILITY ENDPOINTS ==========
  static const String getAvailability =
      '$baseUrl/api/calendar/user-month-availability/';
  static const String userMonthAvailability =
      '$baseUrl/api/calendar/user-month-availability/'; // + userId + /
  static const String userDayAvailability =
      '$baseUrl/api/calendar/user-day-availability/'; // + userId + /?date=
  static const String dayAvailability = '$baseUrl/api/calendar/day/'; // ?date=
  static const String calendarAvailability =
      '$baseUrl/api/calendar/availability/';
  static const String userCalendarAvailability =
      '$baseUrl/api/calendar/availability/'; // ?user_id=

  // ========== NOTIFICATION ENDPOINTS ==========
  static const String notifications = '$baseUrl/api/chat/notifications/';
  static const String unreadNotificationCount =
      '$baseUrl/api/chat/notifications/unread-count/';
  static const String markNotificationRead =
      '$baseUrl/api/chat/notifications/'; // + notificationId + /read/

  // ========== EXTERNAL INTEGRATIONS ==========
  static const String googleCalendar =
      'https://calendar.google.com/calendar/u/0/r/eventedit';

  // ========== DEPRECATED/DUPLICATE ENDPOINTS (TO BE REMOVED) ==========
  // These are duplicates with different naming conventions - keeping for backward compatibility
  @deprecated
  static const String fatch_upcoming_events = '$baseUrl/api/event/events/'; // Typo in original
  @deprecated
  static const String Create_events = '$baseUrl/api/event/events/create/'; // Different case
  @deprecated
  static const String setnewpassword = '$baseUrl/api/auth/set-new-password/'; // Use setNewPassword instead
}
