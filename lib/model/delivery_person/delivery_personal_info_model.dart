class DeliveryPersonalInfoModel {
  const DeliveryPersonalInfoModel({
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.gender,
    required this.maritalStatus,
    required this.employmentType,
    required this.joiningDate,
    required this.assignedArea,
    required this.raw,
  });

  final String firstName;
  final String lastName;
  final String dob;
  final String? gender;
  final String maritalStatus;
  final String employmentType;
  final String joiningDate;
  final String assignedArea;
  final Map<String, dynamic> raw;

  factory DeliveryPersonalInfoModel.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] ?? '').toString().trim();
    final gender = read('gender');
    return DeliveryPersonalInfoModel(
      firstName: read('first_name'),
      lastName: read('last_name'),
      dob: read('dob'),
      gender: gender.isEmpty ? null : gender,
      maritalStatus: read('marital_status'),
      employmentType: read('employment_type'),
      joiningDate: read('joining_date'),
      assignedArea: read('assigned_area'),
      raw: Map<String, dynamic>.from(json),
    );
  }

  factory DeliveryPersonalInfoModel.empty() {
    return const DeliveryPersonalInfoModel(
      firstName: '',
      lastName: '',
      dob: '',
      gender: null,
      maritalStatus: '',
      employmentType: '',
      joiningDate: '',
      assignedArea: '',
      raw: <String, dynamic>{},
    );
  }
}
