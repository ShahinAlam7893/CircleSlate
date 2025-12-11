import 'package:circleslate/presentation/features/availability/view/create_edit_availability_screen.dart';
import 'package:circleslate/presentation/features/chat/view/chat_list_screen.dart';
import 'package:circleslate/presentation/features/event_management/view/upcoming_events_page.dart';
import 'package:circleslate/presentation/features/settings/view/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Still useful for internal page navigation (not bottom bar)
import 'package:circleslate/presentation/features/home/view/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';


// --- AppColors (Copied for self-containment) ---
class AppColors {
  static const Color primaryBlue = Color(0xFF4285F4);
  static const Color inputBorderColor = Colors.grey;
  static const Color textColorSecondary = Color(0xFF333333);
  static const Color inputHintColor = Colors.grey;
  static const Color lightBlueBackground = Color(0x1AD8ECFF);
  static const Color textDark = Color(0xE51B1D2A);
  static const Color textMedium = Color(0x991B1D2A);
  static const Color textLight = Color(0xB21B1D2A);
  static const Color accentBlue = Color(0xFF5A8DEE);
  static const Color inputOutline = Color(0x1A101010);
  static const Color emailIconBackground = Color(0x1AD8ECFF);
  static const Color otpInputFill = Color(0xFFF9FAFB);
  static const Color successIconBackground = Color(0x1AD8ECFF);
  static const Color successIconColor = Color(0xFF4CAF50);
  static const Color headerBackground = Color(0xFF4285F4);
  static const Color availableGreen = Color(0xFF4CAF50);
  static const Color unavailableRed = Color(0xFFF44336);
  static const Color dateBackground = Color(0xFFE0E0E0);
  static const Color dateText = Color(0xFF616161);
  static const Color quickActionCardBackground = Color(0xFFE3F2FD);
  static const Color quickActionCardBorder = Color(0xFF90CAF9);
  static const Color openStatusColor = Color(0xFFD8ECFF);
  static const Color openStatusText = Color(0xA636D399);
  static const Color rideNeededStatusColor = Color(0x1AF87171);
  static const Color rideNeededStatusText = Color(0xFFF87171);
  static const Color toggleButtonActiveBg = Color(0xFF4285F4);
  static const Color toggleButtonActiveText = Colors.white;
  static const Color toggleButtonInactiveBg = Colors.white;
  static const Color toggleButtonInactiveText = Color(0xFF4285F4);
  static const Color toggleButtonBorder = Color(0xFFE0E0E0);
  static const Color goingButtonColor = Color(0xFF4CAF50); // Green for "Going"
  static const Color notGoingButtonColor = Color(0xFFF44336); // Red for "Not Going"
  static const Color chatButtonColor = Color(0xFFE3F2FD); // Light blue for chat button background
  static const Color chatButtonTextColor = Color(0xFF4285F4); // Blue for chat button text
  static const Color requestRideButtonColor = Color(0xFF5A8DEE); // Accent blue for Request Ride
  static const Color requestRideButtonTextColor = Colors.white;
  static const Color rideRequestCardBackground = Color(0xFFE3F2FD); // Light blue for ride request card
  static const Color rideRequestCardBorder = Color(0xFF90CAF9); // Slightly darker blue for card border
  static const Color pendingResponseColor = Color(0xFFFFFBEB); // Light yellow for pending
  static const Color pendingResponseTextColor = Color(0xFFD97706); // Dark yellow for pending text
  static const Color acceptedColor = Color(0xFFD1FAE5); // Light green for accepted
  static const Color acceptedTextColor = Color(0xFF065F46); // Dark green for accepted text
  static const Color senderBubbleColor = Color(0xFFE3F2FD); // Light blue for sender's message bubble
  static const Color receiverBubbleColor = Color(0xFFE0F2F1); // Light green/teal for receiver's message bubble
  static const Color chatTimeColor = Color(0xFF9E9E9E); // Grey for message time
  static const Color chatInputFillColor = Color(0xFFF5F5F5); // Light grey for chat input field
  static const Color shadowColor = Color(0x1A000000); // Placeholder for shadow color if not defined
  static const Color unreadCountBg = Color(0xFFFF6347); // Red-orange for unread count
  static const Color onlineIndicator = Color(0xFF4CAF50); // Green for online indicator
  static const Color adminTagColor = Color(0xFFF87171); // Red for Admin tag
  static const Color memberTagColor = Color(0xFF4CAF50); // Green for Member tag
  static const Color tagTextColor = Colors.white; // White text for tags
 // Red for delete action
  static const Color buttonPrimary = Color(0xFF4285F4); // Primary button color
}

// Placeholder for AppAssets. You should import your actual AppAssets.
class AppAssets {
  static const String calendarIcon = 'assets/images/calendar_icon.png';
  static const String profilePicture = 'assets/images/profile_picture.png';
  static const String emailIcon = 'assets/images/email_icon.png';
  static const String plusIcon = 'assets/images/plus.png';
  static const String eventCalendarIcon = 'assets/images/event_calendar.png';
  static const String sarahMartinez = 'assets/images/sarah_martinez.png';
  static const String peterJohnson = 'assets/images/peter_johnson.png';
  static const String mikeWilson = 'assets/images/mike_wilson.png';
  static const String jenniferDavis = 'assets/images/jennifer_davis.png';
  static const String ellaProfile = 'assets/images/ella_profile.png';
  static const String jennyProfile = 'assets/images/jenny_profile.png';
  static const String lisaProfile = 'assets/images/lisa_profile.png';
  static const String johnProfile = 'assets/images/john_profile.png';
  static const String groupChatIcon = 'assets/images/group_chat_icon.png';
  static const String davidkimProfile = 'assets/images/david_kim_profile.png';
  static const String jenniferBrown = 'assets/images/jennifer_brown.png';
  static const String tomWillson = 'assets/images/tom_willson.png';
  static const String amandaDavis = 'assets/images/amanda_davis.png';
  static const String robertGarcia = 'assets/images/robert_garcia.png';
  static const String sophieMiller = 'assets/images/sophie_miller.png';
  static const String openInviteIcon = 'assets/images/open_invite_icon.png';
}


class SmoothNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const SmoothNavigationWrapper({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<SmoothNavigationWrapper> createState() => _SmoothNavigationWrapperState();
}

class _SmoothNavigationWrapperState extends State<SmoothNavigationWrapper>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Widget> get _pages {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUserId ?? '';
    
    debugPrint('[SmoothNavigationWrapper] Current User ID: $currentUserId');
    
    return [
      const HomePage(),
      const UpcomingEventsPage(),
      const ChatListPage(),
      const AvailabilityPage(),
      const SettingsPage(),
      // const GroupManagementPage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    HapticFeedback.lightImpact();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );

    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Rebuild pages when user profile changes
        final pages = _pages;
        
        return Scaffold(
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(), // Provides a nice scroll effect
              children: pages.map((page) =>
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: page,
              )
              ).toList(),
            ),
          ),
          bottomNavigationBar: _buildCustomBottomNav(),
        );
      },
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.event_note_outlined, Icons.event_note, 'Events'),
              _buildNavItem(2, Icons.chat_bubble_outline, Icons.chat_bubble_outline, 'Chats'),
              _buildNavItem(3, Icons.calendar_today_outlined, Icons.calendar_today, 'Availability'),
              _buildNavItem(4, Icons.settings_outlined, Icons.settings, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.1) // Using AppColors
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primaryBlue : Colors.grey, // Using AppColors
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.primaryBlue : Colors.grey, // Using AppColors
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Poppins',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonPage({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1), // Using AppColors
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primaryBlue, // Using AppColors
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark, // Using AppColors
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon!',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textMedium, // Using AppColors
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue, // Using AppColors
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                'We\'re working hard to bring you this feature!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

