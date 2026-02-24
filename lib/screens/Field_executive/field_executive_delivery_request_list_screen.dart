import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../model/field executive/delivery_request_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class DeliveryRequestListScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final String deliveryType;

  const DeliveryRequestListScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    required this.deliveryType,
  });

  @override
  State<DeliveryRequestListScreen> createState() =>
      _DeliveryRequestListScreenState();
}

class _DeliveryRequestListScreenState extends State<DeliveryRequestListScreen> {
  static const Color _primaryGreen = Color(0xFF1E7C10);

  List<DeliveryRequestModel> _requests = const <DeliveryRequestModel>[];
  bool _isLoading = true;
  String? _errorMessage;

  String get _requestTypeLabel =>
      DeliveryRequestTypes.labelFor(widget.deliveryType);

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawRequests = await ApiService.fetchDeliveryRequests(
        deliveryType: widget.deliveryType,
        roleId: widget.roleId,
      );

      if (!mounted) return;
      setState(() {
        _requests = rawRequests.map(DeliveryRequestModel.fromJson).toList();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$_requestTypeLabel List',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return _DeliveryRequestErrorState(
        message: _errorMessage!,
        onRetry: _fetchRequests,
      );
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Text(
          'No delivery requests found',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _DeliveryRequestCard(
          request: request,
          onTap: () {
            if (request.id.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid delivery request id')),
              );
              return;
            }

            Navigator.pushNamed(
              context,
              AppRoutes.DeliveryProductDetailScreen,
              arguments: deliveryproductdetailArguments(
                roleId: widget.roleId,
                roleName: widget.roleName,
                deliveryType: widget.deliveryType,
                deliveryId: request.id,
                requestType: _requestTypeLabel,
                requestId: request.request_id,
                productName: request.product_name,
                location: request.location,
                status: request.status,
                customerName: request.customer_name,
                customerPhone: request.customer_phone,
                customerAddress: request.customer_address,
              ),
            );
          },
        );
      },
    );
  }
}

class _DeliveryRequestErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DeliveryRequestErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryRequestCard extends StatelessWidget {
  final DeliveryRequestModel request;
  final VoidCallback onTap;

  const _DeliveryRequestCard({
    required this.request,
    required this.onTap,
  });

  static const Color _primaryGreen = Color(0xFF1E7C10);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RequestImage(imageUrl: request.main_product_image),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line('request_id', request.request_id, isBold: true),
                  const SizedBox(height: 4),
                  _line('product_name', request.product_name),
                  const SizedBox(height: 4),
                  _line('model_no', request.model_no),
                  const SizedBox(height: 4),
                  _line('final_price', request.final_price),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestImage extends StatelessWidget {
  final String? imageUrl;

  const _RequestImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final safeUrl = _resolveImageUrl(imageUrl);
    if (safeUrl.isEmpty) {
      return const _ImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 84,
        height: 84,
        child: Image.network(
          safeUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const _ImagePlaceholder(showLoader: true);
          },
        ),
      ),
    );
  }

  String _resolveImageUrl(String? path) {
    final raw = path?.trim() ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) {
      return '${ApiConstants.baseUrl}$raw';
    }
    return '${ApiConstants.baseUrl}/$raw';
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool showLoader;

  const _ImagePlaceholder({this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F1),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF6B7280),
            ),
    );
  }
}
