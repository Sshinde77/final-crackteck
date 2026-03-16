import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/api_constants.dart';
import '../../model/reimbursement_model.dart';
import '../../services/api_service.dart';

class ReimbursementDetailScreen extends StatefulWidget {
  final ReimbursementModel reimbursement;

  const ReimbursementDetailScreen({
    super.key,
    required this.reimbursement,
  });

  @override
  State<ReimbursementDetailScreen> createState() =>
      _ReimbursementDetailScreenState();
}

class _ReimbursementDetailScreenState extends State<ReimbursementDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  ReimbursementModel? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detail = widget.reimbursement;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final reimbursementId = widget.reimbursement.id?.trim() ?? '';
    if (reimbursementId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Reimbursement id is missing for this request.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawDetail = await ApiService.fetchStaffReimbursementDetail(
        reimbursementId: reimbursementId,
      );
      final detail = ReimbursementModel.fromJson(rawDetail);

      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Uri? get _resolvedReceiptUri {
    final raw = _detail?.receiptImagePath?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    final encodedRaw = Uri.encodeFull(raw);
    final parsed = Uri.tryParse(encodedRaw);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    final baseUri = Uri.parse(ApiConstants.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.authority}';

    if (raw.startsWith('/')) {
      return Uri.tryParse(Uri.encodeFull('$origin$raw'));
    }

    final apiBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;

    if (raw.startsWith('receipts/')) {
      return Uri.tryParse(Uri.encodeFull('$origin$apiBasePath/$raw'));
    }

    return Uri.tryParse(Uri.encodeFull('$origin/$raw'));
  }

  Future<void> _downloadReceipt() async {
    final receiptUri = _resolvedReceiptUri;
    if (receiptUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt is not available.')),
      );
      return;
    }

    final launched = await launchUrl(
      receiptUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open receipt download.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail ?? widget.reimbursement;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Reimbursement Detail',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF145A00)),
              )
            : _errorMessage != null && _detail == null
                ? _DetailErrorState(
                    message: _errorMessage!,
                    onRetry: _fetchDetail,
                  )
                : RefreshIndicator(
                    color: const Color(0xFF145A00),
                    onRefresh: _fetchDetail,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _currencyFormat.format(detail.amount),
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Reimbursement Amount',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _DetailStatusBadge(status: detail.status),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _DetailRow(
                                label: 'Reason',
                                value: detail.reason,
                              ),
                              const SizedBox(height: 16),
                              _DetailRow(
                                label: 'Created Date',
                                value: _dateFormat.format(detail.createdAt),
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFED7AA),
                                    ),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9A3412),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Receipt',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ReceiptPreview(uri: _resolvedReceiptUri),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _downloadReceipt,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF145A00),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text(
                                    'Download Receipt',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  final Uri? uri;

  const _ReceiptPreview({required this.uri});

  @override
  Widget build(BuildContext context) {
    if (uri == null) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 10),
            Text(
              'Receipt image not available',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.network(
          uri.toString(),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              color: const Color(0xFFF9FAFB),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Color(0xFF145A00),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF9FAFB),
              alignment: Alignment.center,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Unable to load receipt image',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DetailErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: Color(0xFFC62828),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load reimbursement detail',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF145A00),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  final ReimbursementStatus status;

  const _DetailStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final style = _DetailStatusStyle.fromStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: style.textColor,
        ),
      ),
    );
  }
}

class _DetailStatusStyle {
  final Color backgroundColor;
  final Color textColor;

  const _DetailStatusStyle({
    required this.backgroundColor,
    required this.textColor,
  });

  factory _DetailStatusStyle.fromStatus(ReimbursementStatus status) {
    switch (status) {
      case ReimbursementStatus.pending:
        return const _DetailStatusStyle(
          backgroundColor: Color(0xFFFFF1E6),
          textColor: Color(0xFFE67E22),
        );
      case ReimbursementStatus.approved:
        return const _DetailStatusStyle(
          backgroundColor: Color(0xFFEAF8EC),
          textColor: Color(0xFF2E7D32),
        );
      case ReimbursementStatus.rejected:
        return const _DetailStatusStyle(
          backgroundColor: Color(0xFFFDECEC),
          textColor: Color(0xFFC62828),
        );
    }
  }
}
