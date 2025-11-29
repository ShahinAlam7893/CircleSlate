# CircleSlate

A comprehensive Flutter social calendar application that enables users to manage events, coordinate availability, and communicate in real-time with family and friends.

## 📱 Features

### 🔐 Authentication & User Management
- User registration and login
- Google Sign-In integration
- Password reset functionality
- Profile management with bio, phone number, and date of birth
- Child profile management

### 📅 Calendar & Availability
- Interactive calendar interface
- Personal availability tracking
- Event creation and management
- Google Calendar integration
- Availability preview and editing

### 💬 Real-time Communication
- One-on-one messaging
- Group chat functionality
- Real-time message delivery via WebSocket
- Typing indicators
- Online status tracking
- User search and discovery

### 👥 Group Management
- Create and manage groups
- Group conversations
- Member management
- Group-specific events

### 🚗 Additional Features
- Ride request system
- Event notifications
- Settings and preferences
- Offline support with internet connectivity awareness

## 🏗️ Project Structure

lib/
├── app_providers.dart              # Global app providers configuration
├── app_theme.dart                  # App-wide theme configuration
├── main.dart                       # Application entry point
├── core/                           # Core utilities & reusable components
│   ├── calendar_provider.dart      # Calendar state management
│   ├── constants/                  # App-wide constants
│   │   ├── app_assets.dart         # Asset paths and references
│   │   ├── app_colors.dart         # Color palette and theme colors
│   │   ├── app_strings.dart        # Localized strings and text constants
│   │   └── shared_utilities.dart   # Common utility functions
│   ├── errors/                     # Error handling system
│   │   ├── exceptions.dart         # Custom exception classes
│   │   └── failures.dart           # Failure handling mechanisms
│   ├── network/                    # Network configuration
│   │   └── endpoints.dart          # Centralized API endpoints (50+ endpoints)
│   ├── services/                   # Core business services
│   │   ├── conversation_manager.dart       # Chat conversation management
│   │   ├── group/                          # Group chat services
│   │   │   ├── group_chat_service.dart     # Group chat API integration
│   │   │   ├── group_chat_socket_service.dart # Real-time group messaging
│   │   │   └── group_conversation_manager.dart # Group conversation logic
│   │   ├── message_storage_service.dart    # Local message persistence
│   │   ├── notification_service.dart       # Push notification handling
│   │   ├── user_search_service.dart        # User discovery and search
│   │   └── websocket_service.dart          # Real-time communication
│   └── utils/                      # Utility functions
│       ├── date_time_formatter.dart        # Date/time formatting utilities
│       ├── profile_data_manager.dart       # User profile data management
│       ├── shared_prefs_helper.dart        # Local storage helper
│       └── user_image_helper.dart          # Image handling utilities
├── data/                           # Data layer (Clean Architecture)
│   ├── datasources/                # Data source abstractions
│   │   └── shared_pref/            # Local storage implementation
│   │       └── local/
│   │           ├── entity/         # Local data entities
│   │           ├── login_manager.dart      # Authentication persistence
│   │           ├── shared_pref_manager.dart # Shared preferences wrapper
│   │           └── token_manager.dart      # JWT token management
│   ├── models/                     # Data models with JSON serialization
│   │   ├── availability_model.dart         # User availability data
│   │   ├── chat_list_model.dart           # Chat list representation
│   │   ├── chat_model.dart                # Chat message model
│   │   ├── child_model.dart               # Child profile model
│   │   ├── conversation_model.dart        # Conversation data structure
│   │   ├── default_group_model.dart       # Default group configuration
│   │   ├── event_model.dart               # Event data model
│   │   ├── group_contact_model.dart       # Group contact information
│   │   ├── group_model.dart               # Group data structure
│   │   ├── message_model.dart             # Message data model
│   │   ├── ride_request_model.dart        # Ride sharing data
│   │   ├── user_model.dart                # User profile model
│   │   └── user_search_result_model.dart  # Search result structure
│   ├── repositories/               # Repository implementations
│   │   ├── event_repository.dart          # Event data repository interface
│   │   ├── event_repository_impl.dart     # Event repository implementation
│   │   ├── group_repository.dart          # Group data repository interface
│   │   ├── group_repository_impl.dart     # Group repository implementation
│   │   ├── schedule_repository.dart       # Schedule repository interface
│   │   └── schedule_repository_impl.dart  # Schedule repository implementation
│   └── services/                   # Data services
│       ├── api_base_helper.dart           # HTTP client wrapper
│       ├── auth_service.dart              # Authentication API service
│       └── user_service.dart              # User management API service
├── domain/                         # Business logic layer (Clean Architecture)
│   ├── entities/                   # Business entities
│   ├── repositories/               # Repository interfaces
│   └── usecases/                   # Business use cases
│       └── auth/                   # Authentication use cases
│           ├── forgot_password_usecase.dart # Password recovery logic
│           ├── login_usecase.dart          # Login business logic
│           ├── sign_in_with_google_usecase.dart # Google Sign-In logic
│           └── signup_usecase.dart         # Registration business logic
└── presentation/                   # UI layer (MVVM pattern)
    ├── common_providers/           # Shared state providers
    │   ├── auth_provider.dart              # Authentication state management
    │   ├── availability_provider.dart      # Availability state management
    │   ├── chat_provider.dart              # Chat state management
    │   ├── conversation_provider.dart      # Conversation state management
    │   ├── internet_provider.dart          # Network connectivity state
    │   ├── server_status_provider.dart     # Server status monitoring
    │   ├── user_events_provider.dart       # User events state
    │   ├── user_provider.dart              # User profile state
    │   └── users_availability_provider.dart # Multi-user availability state
    ├── data/                       # Presentation layer data models
    │   └── models/
    │       └── chat_model.dart             # Chat UI model
    ├── features/                   # Feature modules (MVVM pattern)
    │   ├── authentication/         # Complete authentication system
    │   │   ├── view/               # Authentication screens
    │   │   │   ├── EmailVerificationPage.dart # Email verification UI
    │   │   │   ├── forgot_password_reset_page.dart # Password reset UI
    │   │   │   ├── forgot_password_screen.dart # Forgot password UI
    │   │   │   ├── login_screen.dart       # Login interface
    │   │   │   ├── otp_verification_page.dart # OTP verification UI
    │   │   │   ├── pass_cng_success.dart   # Success confirmation UI
    │   │   │   ├── reset_password_page.dart # Password reset form
    │   │   │   └── signup_screen.dart      # Registration interface
    │   │   ├── viewmodel/          # Authentication business logic
    │   │   │   └── auth_viewmodel.dart     # Authentication view model
    │   │   └── widgets/            # Authentication UI components
    │   │       ├── auth_navigation_link.dart # Navigation helper widget
    │   │       └── user_type_selector.dart # User type selection widget
    │   ├── availability/           # Calendar & availability management
    │   │   ├── view/               # Availability screens
    │   │   │   ├── availability_preview_page.dart # Availability preview UI
    │   │   │   └── create_edit_availability_screen.dart # Availability editor
    │   │   ├── viewmodel/          # Availability business logic
    │   │   │   └── schedule_viewmodel.dart # Schedule management logic
    │   │   └── widgets/            # Availability UI components
    │   │       ├── day_selector.dart       # Day selection widget
    │   │       ├── schedule_entry_form.dart # Schedule entry form
    │   │       └── status_indicator_card.dart # Status display widget
    │   ├── chat/                   # Real-time messaging system
    │   │   ├── conversation_service.dart   # Chat service integration
    │   │   ├── group/              # Group chat functionality
    │   │   │   ├── view/           # Group chat screens
    │   │   │   │   ├── create_group_page.dart # Group creation UI
    │   │   │   │   └── group_conversation_page.dart # Group chat interface
    │   │   │   ├── viewmodel/      # Group chat business logic
    │   │   │   └── widgets/        # Group chat UI components
    │   │   ├── view/               # Chat screens
    │   │   │   ├── chat_list_screen.dart   # Chat list interface
    │   │   │   ├── chat_screen.dart        # Individual chat interface
    │   │   │   ├── check.dart              # Chat verification utilities
    │   │   │   └── samplechat.dart         # Sample chat implementation
    │   │   ├── viewmodel/          # Chat business logic
    │   │   └── widgets/            # Chat UI components
    │   │       └── message_bubble.dart     # Message display widget
    │   ├── child_management/       # Child profile management
    │   │   ├── view/               # Child management screens
    │   │   │   ├── add_child_screen.dart   # Add child interface
    │   │   │   └── child_details_screen.dart # Child details view
    │   │   ├── viewmodel/          # Child management logic
    │   │   │   └── child_viewmodel.dart    # Child data management
    │   │   └── widgets/            # Child management UI components
    │   │       └── child_list_item.dart    # Child list item widget
    │   ├── event_management/       # Event creation & management
    │   │   ├── controllers/        # Event controllers
    │   │   │   ├── createEventcontroller.dart # Event creation controller
    │   │   │   └── eventManagementControllers.dart # Event management controller
    │   │   ├── models/             # Event models
    │   │   │   └── eventsModels.dart       # Event data models
    │   │   ├── view/               # Event management screens
    │   │   │   ├── create_edit_event_screen.dart # Event creation/editing UI
    │   │   │   ├── direct_invite_page.dart # Direct invitation interface
    │   │   │   ├── event_details_screen.dart # Event details view
    │   │   │   ├── google_calendar_page.dart # Google Calendar integration
    │   │   │   ├── open_invite_page.dart   # Open invitation interface
    │   │   │   └── upcoming_events_page.dart # Upcoming events list
    │   │   ├── viewmodel/          # Event business logic
    │   │   │   └── event_viewmodel.dart    # Event management logic
    │   │   └── widgets/            # Event UI components
    │   │       ├── event_card.dart         # Event display card
    │   │       └── invite_selection_dialog.dart # Invitation dialog
    │   ├── group_management/       # Group & member management
    │   │   ├── view/               # Group management screens
    │   │   │   ├── add_member_page.dart    # Add member interface
    │   │   │   ├── day_details_dialog.dart # Day details popup
    │   │   │   ├── group_management_page.dart # Group management interface
    │   │   │   └── users_availability_page.dart # Group availability view
    │   │   ├── viewmodel/          # Group management logic
    │   │   │   └── group_viewmodel.dart    # Group data management
    │   │   └── widgets/            # Group management UI components
    │   │       ├── group_list_item.dart    # Group list item widget
    │   │       └── group_member_list_tile.dart # Member list item widget
    │   ├── home/                   # Main dashboard
    │   │   ├── view/               # Home screens
    │   │   │   └── home_screen.dart        # Main dashboard interface
    │   │   ├── viewmodel/          # Home business logic
    │   │   │   └── home_viewmodel.dart     # Dashboard logic
    │   │   └── widgets/            # Home UI components
    │   │       └── my_group_section.dart   # Group section widget
    │   ├── notification/           # Notification system
    │   │   ├── demo.dart                   # Notification demo
    │   │   └── notification_page.dart      # Notification interface
    │   ├── onboarding/             # App onboarding flow
    │   │   ├── view/               # Onboarding screens
    │   │   │   ├── onboarding_page_2.dart  # Onboarding step 2
    │   │   │   ├── onboarding_page_3.dart  # Onboarding step 3
    │   │   │   ├── onboarding_page_4.dart  # Onboarding step 4
    │   │   │   ├── onboarding_page_content.dart # Onboarding content
    │   │   │   ├── onboarding_screen.dart  # Main onboarding screen
    │   │   │   └── splash_screen.dart      # App splash screen
    │   │   ├── viewmodel/          # Onboarding business logic
    │   │   │   └── onboarding_viewmodel.dart # Onboarding logic
    │   │   └── widgets/            # Onboarding UI components
    │   │       └── onboarding_page_content.dart # Content widget
    │   ├── ride_request/           # Ride sharing system
    │   │   ├── services/           # Ride services
    │   │   │   └── RideService.dart        # Ride API service
    │   │   ├── view/               # Ride request screens
    │   │   │   ├── ride_request_sheet.dart # Ride request bottom sheet
    │   │   │   └── ride_sharing_page.dart  # Ride sharing interface
    │   │   ├── viewmodel/          # Ride request logic
    │   │   │   └── ride_request_viewmodel.dart # Ride management logic
    │   │   └── widgets/            # Ride request UI components
    │   │       └── ride_offer_card.dart    # Ride offer display card
    │   └── settings/               # App settings & preferences
    │       ├── view/               # Settings screens
    │       │   ├── delete_account_screen.dart # Account deletion interface
    │       │   ├── edit_profile_page.dart  # Profile editing interface
    │       │   ├── privacy_controls_page.dart # Privacy settings
    │       │   ├── privacy_policy_page.dart # Privacy policy display
    │       │   ├── profile_page.dart       # User profile view
    │       │   ├── settings_screen.dart    # Main settings interface
    │       │   └── terms_and_conditions_page.dart # Terms display
    │       ├── viewmodel/          # Settings business logic
    │       └── widgets/            # Settings UI components
    ├── routes/                     # Navigation configuration
    │   ├── app_router.dart                 # GoRouter configuration with 30+ routes
    │   └── route_observer.dart             # Route change observer
    ├── shared/                     # Shared UI components
    │   ├── app_loading_indicator.dart      # Loading indicator widget
    │   ├── app_snackbar.dart              # Snackbar utility
    │   ├── internet_connection_banner.dart # Connectivity banner
    │   ├── no_internet_page.dart          # No internet screen
    │   └── server_down_banner.dart        # Server status banner
    └── widgets/                    # Reusable UI widgets
        ├── auth_bottom_link.dart           # Authentication navigation link
        ├── auth_input_field.dart           # Authentication input field
        ├── calendar_part.dart              # Calendar component
        ├── custom_app_bar.dart             # Custom app bar widget
        ├── custom_bottom_nav_bar.dart      # Bottom navigation bar
        ├── date_time_picker_field.dart     # Date/time picker widget
        ├── friend_avatar.dart              # Friend avatar widget
        ├── google_facebook_sign_in_buttons.dart # Social auth buttons
        ├── page_indicator_dots.dart        # Page indicator widget
        ├── primary_button.dart             # Primary button widget
        ├── recurrence_selector.dart        # Event recurrence selector
        ├── secondary_button.dart           # Secondary button widget
        ├── social_auth_buttons.dart        # Social authentication buttons
        └── text_input_field.dart           # Text input field widget

## 🛠️ Technical Stack

### State Management
- **Provider** - For state management across the application
- **ChangeNotifier** - For reactive state updates

### Navigation
- **GoRouter** - Declarative routing with type-safe navigation

### Networking
- **HTTP** - RESTful API communication
- **WebSocket** - Real-time messaging
- **JWT** - Authentication token management

### Local Storage
- **SharedPreferences** - Local data persistence
- **Image Picker** - Camera and gallery integration

### UI/UX
- **Flutter ScreenUtil** - Responsive design
- **Custom Fonts** - Poppins and Roboto font families
- **Material Design** - Following Material Design principles

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Dynamic-Calendar-App
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Update API endpoints in `lib/core/network/endpoints.dart`
   - Configure authentication providers
   - Set up WebSocket connection details

4. **Run the application**
   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

### Platform Support
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 📦 Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  go_router: ^10.0.0
  http: ^1.0.0
  web_socket_channel: ^2.4.0
  shared_preferences: ^2.2.0
  image_picker: ^1.0.0
  flutter_screenutil: ^5.8.4
  json_annotation: ^4.8.1
```

### Development Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  json_serializable: ^6.7.1
  build_runner: ^2.4.6
```

## 🔧 Configuration

### API Configuration
Update the base URL in `lib/core/network/endpoints.dart`:
```dart
static const String baseUrl = 'YOUR_API_BASE_URL';
```

### WebSocket Configuration
Configure WebSocket endpoints in the respective service files under `lib/core/services/`.

## 📱 Screens Overview

### Authentication Flow
- **Login Screen** - User authentication
- **Signup Screen** - New user registration
- **Forgot Password** - Password recovery

### Main Application
- **Home Screen** - Dashboard with quick actions
- **Calendar Screen** - Interactive calendar view
- **Chat List** - List of conversations
- **Chat Screen** - Individual/group messaging
- **Event Management** - Create and manage events
- **Profile Settings** - User preferences and profile

## 🎨 Design System

### Colors
- Primary: Blue color scheme
- Accent: Complementary colors for highlights
- Text: High contrast for accessibility
- Background: Clean, modern backgrounds

### Typography
- **Primary Font**: Poppins (Regular, Medium, SemiBold, Bold)
- **Secondary Font**: Roboto (Regular, Medium, Bold, Black)

### Components
- Consistent button styles
- Standardized form inputs
- Reusable card components
- Loading indicators and error states

## 🧪 Testing

Run tests using:
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

## 📈 Performance Considerations

- **Lazy Loading** - Efficient data loading strategies
- **Image Optimization** - Proper image caching and compression
- **State Management** - Optimized provider usage
- **Network Efficiency** - Request batching and caching

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation for common solutions

## 🔄 Version History

- **v1.0.0** - Initial release with core features
- **v1.1.0** - Added group management
- **v1.2.0** - Enhanced real-time messaging
- **v1.3.0** - Improved calendar functionality

---

**Built with ❤️ using Flutter**
