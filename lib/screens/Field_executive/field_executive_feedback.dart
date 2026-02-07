import 'package:flutter/material.dart';

class fieldexecutiveFeedbackScreen extends StatelessWidget {
  final int roleId;
  final String roleName;
  const fieldexecutiveFeedbackScreen({super.key, required this.roleId, required this.roleName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Feedback's"),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: feedbackList.length,
          itemBuilder: (context, index) {
            final item = feedbackList[index];
            return FeedbackCard(
              name: item['name'],
              date: item['date'],
              message: item['message'],
              rating: item['rating'],
            );
          },
        ),
      ),
    );
  }
}

/// 🔹 Feedback Card Widget
class FeedbackCard extends StatelessWidget {
  final String name;
  final String date;
  final String message;
  final int rating;

  const FeedbackCard({
    super.key,
    required this.name,
    required this.date,
    required this.message,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// NAME + DATE + STARS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: " · "),
                        TextSpan(
                          text: date,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                        (index) => Icon(
                      Icons.star,
                      size: 16,
                      color: index < rating
                          ? Colors.amber
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// MESSAGE
            Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 TEMPORARY DUMMY DATA (Replace later with API data)
final List<Map<String, dynamic>> feedbackList = [
  {
    "name": "Caover92",
    "date": "22 Jul",
    "rating": 5,
    "message":
    "KaiB was amazing with our cats! 🐾 This was our first time using a pet-sitting service, so we were naturally anxious. We took a chance on Kai and completely lucked out!"
  },
  {
    "name": "KaiB",
    "date": "22 Jul",
    "rating": 5,
    "message":
    "KaiB was phenomenal with our dog, Max! We were first-time users and quite nervous. Kai’s professionalism immediately put us at ease."
  },
  {
    "name": "PetParent7",
    "date": "22 Jul",
    "rating": 5,
    "message":
    "Excellent care and regular updates. Highly recommended for first-time pet owners."
  },
  {
    "name": "HappyPetMom",
    "date": "22 Jul",
    "rating": 5,
    "message":
    "Absolutely fantastic service from Kai! Attentive care and detailed updates made us feel relaxed."
  },
  {
    "name": "FurBabyFan",
    "date": "22 Jul",
    "rating": 5,
    "message":
    "Kai did an outstanding job looking after our bunny, Thumper! 🐰 We were worried leaving him alone but Kai made all the difference."
  },
];
