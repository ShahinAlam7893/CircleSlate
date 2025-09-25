import 'package:circleslate/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // For navigation

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.pop(); // Use pop for back navigation
          },
        ),
        title: const Text(
          'Terms & Conditions',
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
            children: [
              Text(
                'Effective Date: September 15, 2025\n\n'
                    'Welcome to CircleSlate! These Terms of Service ("Terms") govern your use of the CircleSlate mobile application and related services (collectively, the "Service") provided by CircleSlate, Inc. ("CircleSlate," "we," "us," or "our").\n\n'
                    'IMPORTANT: PLEASE READ THESE TERMS CAREFULLY. BY ACCESSING OR USING OUR SERVICE, YOU AGREE TO BE BOUND BY THESE TERMS. IF YOU DO NOT AGREE TO THESE TERMS, DO NOT USE OUR SERVICE.\n\n'
                    'THESE TERMS CONTAIN A MANDATORY ARBITRATION PROVISION THAT, AS FURTHER SET FORTH IN SECTION 15 BELOW, REQUIRES THE USE OF ARBITRATION ON AN INDIVIDUAL BASIS TO RESOLVE DISPUTES, RATHER THAN JURY TRIALS OR CLASS ACTIONS.',
                style: TextStyle(
                  fontSize: 14.0,
                  color: AppColors.textColorPrimary,
                  fontFamily: 'Poppins',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20.0),

              _buildTermsPoint(
                number: '1.',
                title: 'ACCEPTANCE OF TERMS',
                content:
                'By creating an account, downloading, accessing, or using CircleSlate, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy. '
                    'If you are using CircleSlate on behalf of an organization, you represent that you have the authority to bind that organization to these Terms.',
              ),
              _buildTermsPoint(
                number: '2.',
                title: 'DESCRIPTION OF SERVICE',
                content:
                'CircleSlate is a social calendar application that enables users to coordinate activities, events, and social gatherings within trusted circles of friends, family, and acquaintances. '
                    'Features include creating calendars, managing events, coordinating rides, childcare, in-app messaging, and more.',
              ),
              _buildTermsPoint(
                number: '3.',
                title: 'ELIGIBILITY AND ACCOUNT REGISTRATION',
                content:
                'You must be at least 13 years old to use CircleSlate. Users between 13–18 require parental consent. '
                    'You are responsible for providing accurate account information, keeping your credentials secure, and notifying us of unauthorized access.',
              ),
              _buildTermsPoint(
                number: '4.',
                title: 'ACCEPTABLE USE POLICY',
                content:
                'You may only use CircleSlate for lawful purposes. Prohibited activities include posting harmful or illegal content, violating privacy rights, misusing the platform, and engaging in unsafe behavior.',
              ),
              _buildTermsPoint(
                number: '5.',
                title: 'USER CONTENT AND PRIVACY',
                content:
                'You retain ownership of content you share but grant CircleSlate a license to use it to provide the Service. '
                    'Content must be lawful, accurate, and not infringe rights of others. Privacy practices are governed by our Privacy Policy.',
              ),
              _buildTermsPoint(
                number: '6.',
                title: 'TRUSTED CIRCLES AND SOCIAL FEATURES',
                content:
                'You are responsible for managing your circles and invitations. Parents using the app must ensure child safety. Ride-sharing and childcare arrangements are made at users’ discretion and risk.',
              ),
              _buildTermsPoint(
                number: '7.',
                title: 'INTELLECTUAL PROPERTY RIGHTS',
                content:
                'CircleSlate owns the app and all related intellectual property. You may not copy, modify, or distribute our content without permission. '
                    '"CircleSlate" and its logos are trademarks of CircleSlate, Inc.',
              ),
              _buildTermsPoint(
                number: '8.',
                title: 'PAYMENT TERMS AND SUBSCRIPTIONS',
                content:
                'Some features may be paid. Subscriptions renew automatically unless cancelled. Payments are handled by third-party processors.',
              ),
              _buildTermsPoint(
                number: '9.',
                title: 'THIRD-PARTY SERVICES AND INTEGRATIONS',
                content:
                'CircleSlate may link to or integrate with third-party services. We are not responsible for their practices or content.',
              ),
              _buildTermsPoint(
                number: '10.',
                title: 'DATA SECURITY AND BACKUP',
                content:
                'We implement reasonable safeguards but cannot guarantee absolute security. You are responsible for backing up your data.',
              ),
              _buildTermsPoint(
                number: '11.',
                title: 'SERVICE AVAILABILITY AND MODIFICATIONS',
                content:
                'We strive for high availability but do not guarantee uninterrupted access. We may update or discontinue features at any time.',
              ),
              _buildTermsPoint(
                number: '12.',
                title: 'TERMINATION',
                content:
                'You may terminate your account at any time. CircleSlate may suspend or terminate accounts for violations of these Terms or harmful behavior.',
              ),
              _buildTermsPoint(
                number: '13.',
                title: 'DISCLAIMERS AND WARRANTIES',
                content:
                'The Service is provided "as is" without warranties. We do not guarantee uninterrupted service, accuracy of content, or safe user interactions.',
              ),
              _buildTermsPoint(
                number: '14.',
                title: 'LIMITATION OF LIABILITY',
                content:
                'CircleSlate is not liable for indirect, incidental, or consequential damages. Our total liability will not exceed \$100 or the amount you paid in the past 12 months.',
              ),
              _buildTermsPoint(
                number: '15.',
                title: 'DISPUTE RESOLUTION AND ARBITRATION',
                content:
                'Disputes will be resolved through binding individual arbitration. Class actions and jury trials are waived. Certain exceptions apply (e.g., small claims, IP claims).',
              ),
              _buildTermsPoint(
                number: '16.',
                title: 'GOVERNING LAW AND JURISDICTION',
                content:
                'These Terms are governed by New York law. Non-arbitrable disputes fall under New York state or federal courts.',
              ),
              _buildTermsPoint(
                number: '17.',
                title: 'INDEMNIFICATION',
                content:
                'You agree to indemnify and hold harmless CircleSlate, its officers, and employees from claims arising from your use, violations, or posted content.',
              ),
              _buildTermsPoint(
                number: '18.',
                title: 'GENERAL PROVISIONS',
                content:
                'These Terms, together with our Privacy Policy, form the entire agreement. Provisions cover severability, waiver, assignment, force majeure, and notices.',
              ),
              _buildTermsPoint(
                number: '19.',
                title: 'CONTACT INFORMATION',
                content:
                'CircleSlate, Inc.\n223 Wall Street, PMB 185\nHuntington, NY 11743\nEmail: support@circleslate.com\n\nLast Updated: 9/15/2025',
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsPoint({
    required String number,
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.textColorPrimary,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '$number ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.0,
              color: AppColors.textColorSecondary,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
