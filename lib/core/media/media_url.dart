import '../../constants/api_constants.dart';

/// Resolves the API media contract consistently across every screen.
///
/// API responses should expose companion `*_url` fields. The stored path is
/// still accepted as a backward-compatible fallback for older responses.
class MediaUrl {
  MediaUrl._();

  static String resolve(dynamic value) {
    if (value == null) return '';

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in map.keys.where((key) => key.endsWith('_url'))) {
        final resolved = resolve(map[key]);
        if (resolved.isNotEmpty) return resolved;
      }
      for (final key in const [
        'url',
        'image_url',
        'main_product_image_url',
        'profile_url',
        'receipt_url',
        'document_file_url',
        'file_url',
        'path_url',
        'image',
        'main_product_image',
        'profile',
        'receipt',
        'document_file',
        'path',
        'file',
      ]) {
        final resolved = resolve(map[key]);
        if (resolved.isNotEmpty) return resolved;
      }
      return '';
    }

    if (value is List) {
      for (final item in value) {
        final resolved = resolve(item);
        if (resolved.isNotEmpty) return resolved;
      }
      return '';
    }

    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return '';
    final lowerRaw = raw.toLowerCase();
    if (lowerRaw.startsWith('<!doctype html') ||
        lowerRaw.startsWith('<html') ||
        (raw.contains('<') && raw.contains('>'))) {
      return '';
    }
    if (raw.startsWith('data:image/')) return raw;

    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      final scheme = parsed.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https') return raw;
    }

    if (raw.startsWith('//')) return 'https:$raw';

    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    if (path.isEmpty) return '';

    final storagePath = path.startsWith('diagnosis_photos/') ||
            path.startsWith('kyc_documents/')
        ? 'storage/$path'
        : path;
    return '${ApiConstants.siteBaseUrl}/$storagePath';
  }

  static String fromMap(
    Map<String, dynamic>? source,
    List<String> fields, {
    String fallback = '',
  }) {
    if (source == null) return fallback;

    for (final field in fields) {
      final candidates = field.endsWith('_url')
          ? <String>[field]
          : <String>['${field}_url', field];
      for (final key in candidates) {
        final resolved = resolve(source[key]);
        if (resolved.isNotEmpty) return resolved;
      }
    }
    return fallback;
  }

  static List<String> listFromMap(
    Map<String, dynamic>? source,
    List<String> fields,
  ) {
    if (source == null) return const <String>[];
    final urls = <String>[];

    for (final field in fields) {
      final candidates = field.endsWith('_url')
          ? <String>[field]
          : <String>['${field}_url', field];
      for (final key in candidates) {
        final value = source[key];
        if (value is List) {
          for (final item in value) {
            final resolved = resolve(item);
            if (resolved.isNotEmpty && !urls.contains(resolved)) {
              urls.add(resolved);
            }
          }
        } else {
          final resolved = resolve(value);
          if (resolved.isNotEmpty && !urls.contains(resolved)) {
            urls.add(resolved);
          }
        }
        if (urls.isNotEmpty) return urls;
      }
    }
    return urls;
  }
}
