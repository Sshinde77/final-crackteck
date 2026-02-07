class ProfileModel {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String gender;

  final String currentAddress;
  final String city;
  final String state;
  final String country;
  final String pincode;

  final String employmentType;
  final String assignedArea;

  final String vehicleType;
  final String vehicleNo;
  final String drivingLicenseNo;

  final String policeVerification;
  final String policeVerificationStatus;

  final String govId;
  final String idNo;

  final String bankAccNo;
  final String bankName;
  final String ifscCode;

  final String? drivingLicenseDoc;
  final String? policeCertificateDoc;
  final String? adharPic;
  final String? passbookPic;

  final DateTime? dob;
  final String dobRaw;

  final DateTime? joiningDate;
  final String joiningDateRaw;

  final DateTime? createdAt;
  final String createdAtRaw;

  final DateTime? updatedAt;
  final String updatedAtRaw;

  ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.gender,
    required this.currentAddress,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.employmentType,
    required this.assignedArea,
    required this.vehicleType,
    required this.vehicleNo,
    required this.drivingLicenseNo,
    required this.policeVerification,
    required this.policeVerificationStatus,
    required this.govId,
    required this.idNo,
    required this.bankAccNo,
    required this.bankName,
    required this.ifscCode,
    this.drivingLicenseDoc,
    this.policeCertificateDoc,
    this.adharPic,
    this.passbookPic,
    required this.dob,
    required this.dobRaw,
    required this.joiningDate,
    required this.joiningDateRaw,
    required this.createdAt,
    required this.createdAtRaw,
    required this.updatedAt,
    required this.updatedAtRaw,
  });

  String get fullName {
    final combined = '${firstName.trim()} ${lastName.trim()}'.trim();
    return combined.isEmpty ? '-' : combined;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        // Unix timestamp in seconds or milliseconds
        try {
          if (value > 1000000000000) {
            return DateTime.fromMillisecondsSinceEpoch(value);
          }
          return DateTime.fromMillisecondsSinceEpoch(value * 1000);
        } catch (_) {
          return null;
        }
      }
      if (value is String && value.trim().isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    String _string(dynamic v) => v?.toString() ?? '';

    final dobRaw = _string(json['dob']);
    final joiningRaw = _string(json['joining_date'] ?? json['joiningDate']);
    final createdRaw = _string(json['created_at'] ?? json['createdAt']);
    final updatedRaw = _string(json['updated_at'] ?? json['updatedAt']);

    return ProfileModel(
      id: int.tryParse(_string(json['id'])) ?? 0,
      firstName: _string(json['first_name'] ?? json['firstName']),
      lastName: _string(json['last_name'] ?? json['lastName']),
      phone: _string(json['phone'] ?? json['mobile'] ?? json['contact_no']),
      email: _string(json['email']),
      gender: _string(json['gender']),
      currentAddress: _string(
        json['current_address'] ?? json['address'] ?? json['addr'],
      ),
      city: _string(json['city']),
      state: _string(json['state']),
      country: _string(json['country']),
      pincode: _string(json['pincode'] ?? json['zip']),
      employmentType: _string(
        json['employment_type'] ?? json['employmentType'],
      ),
      assignedArea: _string(json['assigned_area'] ?? json['area']),
      vehicleType: _string(json['vehicle_type'] ?? json['vehicleType']),
      vehicleNo: _string(
        json['vehicle_no'] ?? json['vehicleNo'] ?? json['vehical_no'],
      ),
      drivingLicenseNo: _string(
        json['driving_license_no'] ?? json['drivingLicenseNo'],
      ),
      policeVerification: _string(
        json['police_verification'] ?? json['policeVerification'],
      ),
      policeVerificationStatus: _string(
        json['police_verification_status'] ?? json['policeVerificationStatus'],
      ),
      govId: _string(json['gov_id'] ?? json['govId'] ?? json['govid']),
      idNo: _string(json['id_no'] ?? json['idNo'] ?? json['idno']),
      bankAccNo: _string(
        json['bank_acc_no'] ?? json['account_no'] ?? json['bankAcc'],
      ),
      bankName: _string(json['bank_name'] ?? json['bankName']),
      ifscCode: _string(json['ifsc_code'] ?? json['ifscCode']),
      drivingLicenseDoc:
          json['driving_license']?.toString() ?? json['drivingLicense'],
      policeCertificateDoc:
          json['police_certificate']?.toString() ?? json['policeCertificate'],
      adharPic: json['adhar_pic']?.toString() ?? json['aadharPic'],
      passbookPic: json['passbook_pic']?.toString() ?? json['passbookPic'],
      dob: _parseDate(json['dob']),
      dobRaw: dobRaw,
      joiningDate: _parseDate(joiningRaw),
      joiningDateRaw: joiningRaw,
      createdAt: _parseDate(createdRaw),
      createdAtRaw: createdRaw,
      updatedAt: _parseDate(updatedRaw),
      updatedAtRaw: updatedRaw,
    );
  }

  static ProfileModel? fromUserEnvelope(dynamic json) {
    if (json is Map<String, dynamic>) {
      final dynamic user = json['user'] ?? json['data'];
      if (user is Map<String, dynamic>) {
        return ProfileModel.fromJson(user);
      }
      if (!json.containsKey('user')) {
        // Some APIs may return the user object at the root
        return ProfileModel.fromJson(json);
      }
    }
    return null;
  }
}
