import '../../core/media/media_url.dart';

class DeliveryProfileModel {
  const DeliveryProfileModel({
    required this.name,
    required this.code,
    required this.rating,
    required this.avatarUrl,
    required this.raw,
  });

  final String name;
  final String code;
  final double rating;
  final String avatarUrl;
  final Map<String, dynamic> raw;

  factory DeliveryProfileModel.fromJson(Map<String, dynamic> json) {
    final first = (json['first_name'] ?? '').toString().trim();
    final last = (json['last_name'] ?? '').toString().trim();
    final full = '$first $last'.trim();
    final rawRating = json['rating'] ?? json['average_rating'] ?? 0;

    return DeliveryProfileModel(
      name: full.isNotEmpty
          ? full
          : (json['name'] ?? 'Delivery Partner').toString(),
      code:
          (json['staff_id'] ??
                  json['employee_id'] ??
                  json['user_id'] ??
                  json['id'] ??
                  '--')
              .toString(),
      rating: rawRating is num
          ? rawRating.toDouble()
          : double.tryParse(rawRating.toString()) ?? 0,
      avatarUrl: MediaUrl.fromMap(json, const [
        'profile_image',
        'avatar',
        'image',
        'profile',
      ]),
      raw: Map<String, dynamic>.from(json),
    );
  }

  factory DeliveryProfileModel.empty() {
    return const DeliveryProfileModel(
      name: 'Delivery Partner',
      code: '--',
      rating: 0,
      avatarUrl: '',
      raw: <String, dynamic>{},
    );
  }
}
