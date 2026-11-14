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
    DateTime? parseDate(dynamic value) {
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

    String string(dynamic v) => v?.toString() ?? '';

    final dobRaw = string(json['dob']);
    final joiningRaw = string(json['joining_date'] ?? json['joiningDate']);
    final createdRaw = string(json['created_at'] ?? json['createdAt']);
    final updatedRaw = string(json['updated_at'] ?? json['updatedAt']);

    return ProfileModel(
      id: int.tryParse(string(json['id'])) ?? 0,
      firstName: string(json['first_name'] ?? json['firstName']),
      lastName: string(json['last_name'] ?? json['lastName']),
      phone: string(json['phone'] ?? json['mobile'] ?? json['contact_no']),
      email: string(json['email']),
      gender: string(json['gender']),
      currentAddress: string(
        json['current_address'] ?? json['address'] ?? json['addr'],
      ),
      city: string(json['city']),
      state: string(json['state']),
      country: string(json['country']),
      pincode: string(json['pincode'] ?? json['zip']),
      employmentType: string(
        json['employment_type'] ?? json['employmentType'],
      ),
      assignedArea: string(json['assigned_area'] ?? json['area']),
      vehicleType: string(json['vehicle_type'] ?? json['vehicleType']),
      vehicleNo: string(
        json['vehicle_no'] ?? json['vehicleNo'] ?? json['vehical_no'],
      ),
      drivingLicenseNo: string(
        json['driving_license_no'] ?? json['drivingLicenseNo'],
      ),
      policeVerification: string(
        json['police_verification'] ?? json['policeVerification'],
      ),
      policeVerificationStatus: string(
        json['police_verification_status'] ?? json['policeVerificationStatus'],
      ),
      govId: string(json['gov_id'] ?? json['govId'] ?? json['govid']),
      idNo: string(json['id_no'] ?? json['idNo'] ?? json['idno']),
      bankAccNo: string(
        json['bank_acc_no'] ?? json['account_no'] ?? json['bankAcc'],
      ),
      bankName: string(json['bank_name'] ?? json['bankName']),
      ifscCode: string(json['ifsc_code'] ?? json['ifscCode']),
      drivingLicenseDoc:
          json['driving_license']?.toString() ?? json['drivingLicense'],
      policeCertificateDoc:
          json['police_certificate']?.toString() ?? json['policeCertificate'],
      adharPic: json['adhar_pic']?.toString() ?? json['aadharPic'],
      passbookPic: json['passbook_pic']?.toString() ?? json['passbookPic'],
      dob: parseDate(json['dob']),
      dobRaw: dobRaw,
      joiningDate: parseDate(joiningRaw),
      joiningDateRaw: joiningRaw,
      createdAt: parseDate(createdRaw),
      createdAtRaw: createdRaw,
      updatedAt: parseDate(updatedRaw),
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
