import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class fieldexecutiveFeedbackScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const fieldexecutiveFeedbackScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<fieldexecutiveFeedbackScreen> createState() =>
      _fieldexecutiveFeedbackScreenState();
}

class _fieldexecutiveFeedbackScreenState
    extends State<fieldexecutiveFeedbackScreen> {
  static const Color _primaryGreen = Color(0xFF1F8B00);
  static const Color _darkGreen = Color(0xFF145A00);

  List<_FeedbackListItem> _feedbacks = const <_FeedbackListItem>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawList = await ApiService.fetchFieldExecutiveFeedbackList(
        roleId: widget.roleId,
      );

      if (!mounted) return;

      setState(() {
        _feedbacks = rawList.map(_FeedbackListItem.fromJson).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _cleanErrorMessage(error);
        _isLoading = false;
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString().trim();
    const prefix = 'Exception:';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length).trim();
    }
    return message;
  }

  void _openFeedbackDetail(_FeedbackListItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FeedbackDetailSheet(
        roleId: widget.roleId,
        feedback: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Feedback",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _darkGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadFeedbacks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_feedbacks.isEmpty) {
      return RefreshIndicator(
        color: _darkGreen,
        onRefresh: _loadFeedbacks,
        child: ListView(
          children: const [
            SizedBox(height: 220),
            Center(
              child: Text(
                'No feedback found',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _darkGreen,
      onRefresh: _loadFeedbacks,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _feedbacks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _feedbacks[index];
          return _FeedbackCard(
            item: item,
            onTap: () => _openFeedbackDetail(item),
          );
        },
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final _FeedbackListItem item;
  final VoidCallback onTap;

  const _FeedbackCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: item.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: item.date.isEmpty ? '' : ' · ${item.date}',
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
                      color: index < item.rating
                          ? Colors.amber
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF145A00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackDetailSheet extends StatefulWidget {
  final int roleId;
  final _FeedbackListItem feedback;

  const _FeedbackDetailSheet({
    required this.roleId,
    required this.feedback,
  });

  @override
  State<_FeedbackDetailSheet> createState() => _FeedbackDetailSheetState();
}

class _FeedbackDetailSheetState extends State<_FeedbackDetailSheet> {
  static const Color _darkGreen = Color(0xFF145A00);

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (widget.feedback.id.isEmpty) {
      setState(() {
        _isLoading = false;
        _detail = const <String, dynamic>{};
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.fetchFieldExecutiveFeedbackDetail(
        feedbackId: widget.feedback.id,
        roleId: widget.roleId,
      );

      if (!mounted) return;
      setState(() {
        _detail = response;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _cleanErrorMessage(error);
        _isLoading = false;
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString().trim();
    const prefix = 'Exception:';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length).trim();
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final merged = Map<String, dynamic>.from(widget.feedback.raw)
      ..addAll(_detail ?? const <String, dynamic>{});

    final name = _firstString(
      merged,
      const ['customer_name', 'name', 'user_name', 'username', 'customer'],
      fallback: widget.feedback.name,
    );
    final message = _firstString(
      merged,
      const ['message', 'feedback', 'comment', 'description', 'notes'],
      fallback: widget.feedback.message,
    );
    final rating = _firstInt(
      merged,
      const ['rating', 'stars', 'star'],
      fallback: widget.feedback.rating,
    );
    final date = _formatFeedbackDate(
      _firstValue(
        merged,
        const ['created_at', 'feedback_date', 'date', 'updated_at'],
      ),
      fallback: widget.feedback.date,
    );
    final feedbackId = _firstString(
      merged,
      const ['feedback_id', 'id'],
      fallback: widget.feedback.id,
    );
    final serviceId = _firstString(
      merged,
      const ['service_id', 'request_id', 'case_id'],
      fallback: '-',
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Feedback Detail',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: _buildDetailBody(
                name: name,
                date: date,
                rating: rating,
                message: message,
                feedbackId: feedbackId,
                serviceId: serviceId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailBody({
    required String name,
    required String date,
    required int rating,
    required String message,
    required String feedbackId,
    required String serviceId,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _darkGreen),
      );
    }

    if (_errorMessage != null && (_detail == null || _detail!.isEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Name', name),
          const SizedBox(height: 10),
          _detailRow('Date', date),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 88,
                child: Text(
                  'Rating',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 18,
                    color: index < rating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _detailRow('Feedback ID', feedbackId),
          const SizedBox(height: 10),
          _detailRow('Service ID', serviceId),
          const SizedBox(height: 12),
          const Text(
            'Message',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackListItem {
  final String id;
  final String name;
  final String date;
  final String message;
  final int rating;
  final Map<String, dynamic> raw;

  const _FeedbackListItem({
    required this.id,
    required this.name,
    required this.date,
    required this.message,
    required this.rating,
    required this.raw,
  });

  factory _FeedbackListItem.fromJson(Map<String, dynamic> json) {
    final id = _firstString(
      json,
      const ['feedback_id', 'id'],
      fallback: '',
    );
    final name = _firstString(
      json,
      const ['customer_name', 'name', 'user_name', 'username', 'customer'],
      fallback: 'Unknown',
    );
    final message = _firstString(
      json,
      const ['message', 'feedback', 'comment', 'description', 'notes'],
      fallback: 'No feedback message',
    );
    final rating = _firstInt(
      json,
      const ['rating', 'stars', 'star'],
      fallback: 0,
    );
    final date = _formatFeedbackDate(
      _firstValue(
        json,
        const ['created_at', 'feedback_date', 'date', 'updated_at'],
      ),
      fallback: '',
    );

    return _FeedbackListItem(
      id: id,
      name: name,
      date: date,
      message: message,
      rating: rating.clamp(0, 5),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

dynamic _firstValue(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    if (!source.containsKey(key)) continue;
    final value = source[key];
    if (value != null) return value;
  }
  return null;
}

String _firstString(
  Map<String, dynamic> source,
  List<String> keys, {
  String fallback = '-',
}) {
  final value = _firstValue(source, keys);
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _firstInt(
  Map<String, dynamic> source,
  List<String> keys, {
  int fallback = 0,
}) {
  final value = _firstValue(source, keys);
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) return parsed.round();
  }
  return fallback;
}

String _formatFeedbackDate(dynamic value, {String fallback = '-'}) {
  if (value == null) {
    return fallback;
  }

  DateTime? parsed;
  if (value is String) {
    parsed = DateTime.tryParse(value.trim());
  } else if (value is int) {
    parsed = DateTime.fromMillisecondsSinceEpoch(
      value < 1000000000000 ? value * 1000 : value,
    );
  } else if (value is num) {
    final millis = value.toInt();
    parsed = DateTime.fromMillisecondsSinceEpoch(
      millis < 1000000000000 ? millis * 1000 : millis,
    );
  } else if (value is DateTime) {
    parsed = value;
  }

  if (parsed == null) {
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
}
