import 'package:flutter/material.dart';

class fieldexecutivePrivacyPolicyScreen extends StatelessWidget {
  final int roleId;
  final String roleName;
  const fieldexecutivePrivacyPolicyScreen({super.key, required this.roleId, required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy policy',
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
              /// TITLE
              Text(
                'Privacy Policy for SampleApp',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),

              /// INTRO
              Text(
                'At SampleApp, accessible from sampleapp.com, one of our main '
                    'priorities is the privacy of our users. This Privacy Policy '
                    'document explains the types of information that are collected '
                    'and recorded by SampleApp and how we use it.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),

              /// CONTACT
              Text(
                'If you have additional questions or require more information '
                    'about our Privacy Policy, do not hesitate to contact us at '
                    'support@sampleapp.com.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),

              /// SCOPE
              Text(
                'This Privacy Policy applies only to our online activities and '
                    'is valid for users of our application with regards to the '
                    'information they share and/or collect in SampleApp. '
                    'This policy does not apply to any information collected '
                    'offline or via other channels.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),

              /// CONSENT
              Text(
                'By using our application, you hereby consent to our Privacy '
                    'Policy and agree to its terms.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),

              /// INFORMATION WE COLLECT
              Text(
                'Information We Collect',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              Text(
                'When you register for an account, we may ask for personal '
                    'information such as your name, email address, phone number, '
                    'and other relevant details.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),

              /// HOW WE USE DATA
              Text(
                'How We Use Your Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              Text(
                'We use the information we collect in various ways, including:\n'
                    '• To provide and maintain our application\n'
                    '• To improve and personalize user experience\n'
                    '• To communicate with users\n'
                    '• To analyze usage and improve services',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),

              /// UPDATE NOTE
              Text(
                'Note:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),

              Text(
                'This is temporary sample content. Please replace app name, '
                    'email, website, and policy details with your actual data '
                    'before publishing the app.',
                style: TextStyle(fontSize: 13),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
