import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  static const Color darkGreen = Color(0xFF145A00);
  static const Color starColor = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔹 AppBar
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Feedback’s",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // 🔹 Body
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feedbackList.length,
        itemBuilder: (context, index) {
          final item = _feedbackList[index];
          return _FeedbackCard(
            name: item.name,
            date: item.date,
            message: item.message,
            rating: item.rating,
          );
        },
      ),
    );
  }
}

/// =======================
/// FEEDBACK CARD
/// =======================
class _FeedbackCard extends StatelessWidget {
  final String name;
  final String date;
  final String message;
  final int rating;

  const _FeedbackCard({
    required this.name,
    required this.date,
    required this.message,
    required this.rating,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Date + Stars
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: "  ·  $date",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Stars(rating: rating),
            ],
          ),

          const SizedBox(height: 8),

          // Message
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// STAR RATING
/// =======================
class _Stars extends StatelessWidget {
  final int rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
            (index) => Icon(
          Icons.star,
          size: 16,
          color: index < rating ? FeedbackScreen.starColor : Colors.black12,
        ),
      ),
    );
  }
}

/// =======================
/// STATIC DATA
/// =======================
class _FeedbackData {
  final String name;
  final String date;
  final String message;
  final int rating;

  _FeedbackData({
    required this.name,
    required this.date,
    required this.message,
    required this.rating,
  });
}

final List<_FeedbackData> _feedbackList = [
  _FeedbackData(
    name: "Caover92",
    date: "22 Jul",
    rating: 5,
    message:
    "KaiB was amazing with our cats!! 🐾🐾 This was our first time using a pet-sitting service, so we were naturally quite anxious. We took a chance on Kai and completely lucked out! We booked Kai to come twice a day for three days.",
  ),
  _FeedbackData(
    name: "KaiB",
    date: "22 Jul",
    rating: 5,
    message:
    "KaiB was phenomenal with our dog, Max! We were first-time users of a pet-sitting service and were quite nervous. Kai’s professionalism and warmth immediately put us at ease.",
  ),
  _FeedbackData(
    name: "PetParent7",
    date: "22 Jul",
    rating: 5,
    message:
    "KaiB was phenomenal with our dog, Max! We were first-time users of a pet-sitting service and were quite nervous. Kai’s professionalism and warmth immediately put us at ease.",
  ),
  _FeedbackData(
    name: "HappyPetMom",
    date: "22 Jul",
    rating: 5,
    message:
    "Absolutely fantastic service from Kai! As first-time Pet Backer users, we were unsure what to expect. Kai’s attentive care and detailed updates put us at ease.",
  ),
  _FeedbackData(
    name: "FurBabyFan",
    date: "22 Jul",
    rating: 5,
    message:
    "KaiB did an outstanding job looking after our bunny, Thumper! 🐰🐰 We were worried about leaving him alone, but Kai’s attentive care made all the difference.",
  ),
];
