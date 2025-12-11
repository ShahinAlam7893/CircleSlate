import 'package:circleslate/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SectionTitle("Introduction"),
              _SectionText(
                  "Welcome to CircleSlate (\"we,\" \"our,\" or \"us\"). CircleSlate is a dynamic social calendar application designed to help users share availability for social gatherings, with a particular focus on coordinating activities and playdates.\n\n"
                      "We respect your privacy and are committed to protecting the personal information of all our users. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and related services (collectively, the \"Service\").\n\n"
                      "Please read this Privacy Policy carefully. By accessing or using the Service, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy. If you do not agree with our policies and practices, please do not use our Service."),

              SizedBox(height: 20),
              _SectionTitle("User Eligibility"),
              _BulletList(items: [
                "Adult Users (18+): Full account privileges and responsibilities",
                "Teen Users (13-17): May use the app with certain privacy protections as outlined below",
                "Children Under 13: Do not directly use the app; parents may input information about their children's activities",
              ]),

              SizedBox(height: 20),
              _SectionTitle("Information We Collect"),
              _SectionSubtitle("Personal Information"),
              _BulletList(items: [
                "Account Information: When you register, we collect your name, email address, password, and optionally, your phone number.",
                "Profile Information: Information you provide in your user profile, such as profile picture, location, and preferences.",
                "Child-Related Information: Parents may input information about their children (names, ages, interests, availability).",
                "Calendar and Availability Data: Information about your availability, scheduled activities, and social preferences.",
                "Communications: Messages and communications between users within the app.",
                "Device Information: Device type, OS, identifiers, IP address, and network information.",
                "Usage Data: Information about how you use the app and features you access.",
                "Social Network Information: If you connect accounts (e.g., Facebook, Google), we may collect profile data.",
                "Location Data: General or precise location (with consent).",
              ]),

              SizedBox(height: 20),
              _SectionTitle("How We Collect Information"),
              _BulletList(items: [
                "Directly from you when you register, create profiles, or communicate.",
                "Automatically through device and app usage data.",
                "From third-party services you choose to link (e.g., calendar or social media).",
              ]),

              // ➝ Continue adding sections for:
              // Cookies & Tracking, Teen Users, How We Use Info,
              // Child-Related Info, Sharing Info, Security, Rights, etc.

              SizedBox(height: 20),
              _SectionTitle("Contact Us"),
              _SectionText(
                  "If you have questions or concerns about this Privacy Policy or our practices, please contact us at:\n\n"
                      "Email: support@circleslate.com\n\n"
                      "Address: CircleSlate\n"
                      "223 Wall Street, PMB 185\n"
                      "Huntington, NY 11743\n"
              "\n"
              "Last Updated: 09/15/2025"),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 Reusable styled section title
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textColorPrimary,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _SectionSubtitle extends StatelessWidget {
  final String text;
  const _SectionSubtitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textColorPrimary,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;
  const _SectionText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14.0,
        color: AppColors.textColorSecondary,
        fontFamily: 'Poppins',
        height: 1.5,
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ",
                  style: TextStyle(
                    fontSize: 14.0,
                    color: AppColors.textColorPrimary,
                  )),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: AppColors.textColorSecondary,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
