import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class FieldExecutivePersonalInfo extends StatefulWidget {
  final int roleId;
  final String roleName;

  const FieldExecutivePersonalInfo({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<FieldExecutivePersonalInfo> createState() =>
      _FieldExecutivePersonalInfoState();
}

class _FieldExecutivePersonalInfoState extends State<FieldExecutivePersonalInfo> {
  static const Color midGreen = Color(0xFF1F8B00);
  static const Color darkGreen = Color(0xFF145A00);

  bool _isLoading = true;
  String? _errorMessage;

  String _firstName = '-';
  String _lastName = '-';
  String _phone = '-';
  String _email = '-';
  String _dob = '-';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _readValue(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) return '-';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await ApiService.fetchFieldExecutivePersonalInfo(
        roleId: widget.roleId,
      );

      if (!mounted) return;

      setState(() {
        _firstName = _readValue(profile, 'first_name');
        _lastName = _readValue(profile, 'last_name');
        _phone = _readValue(profile, 'phone');
        _email = _readValue(profile, 'email');
        _dob = _readValue(profile, 'dob');
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 76,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [midGreen, darkGreen],
            ),
          ),
        ),
        title: const Text(
          'Personal info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            _infoRow(label: 'First Name', value: _firstName),
            const Divider(height: 20),
            _infoRow(label: 'Last Name', value: _lastName),
            const Divider(height: 20),
            _infoRow(label: 'Phone', value: _phone),
            const Divider(height: 20),
            _infoRow(label: 'Email', value: _email),
            const Divider(height: 20),
            _infoRow(label: 'DOB', value: _dob),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
