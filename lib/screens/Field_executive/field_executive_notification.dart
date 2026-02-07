import 'package:flutter/material.dart';

class EnigneerNotificationScreen extends StatelessWidget {
  const EnigneerNotificationScreen({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            NotificationCard(
              title: 'New Call',
              description:
              'How did we do? Let us know by rating your recent order and sharing your feedback.',
              time: '15 minutes ago',
              isUnread: true,
            ),
            NotificationCard(
              title: 'Service Rating',
              description:
              'How did we do? Let us know by rating your recent order and sharing your feedback.',
              time: '1 day ago',
            ),
            NotificationCard(
              title: 'Hungry? Try Our New Pizza Specials!',
              description:
              'Check out the latest additions to our menu and satisfy your cravings!',
              time: '2 days ago',
            ),
            NotificationCard(
              title: "Don't Miss Out: Special Offer Just for You!",
              description:
              'Get 10% off your next order with code SAVE10. Limited time only!',
              time: '2 hours ago',
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔔 Notification Card Widget
class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final bool isUnread;

  const NotificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + unread dot
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: title == 'New Call'
                              ? Colors.green[700]
                              : Colors.black,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Time
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
