import 'dart:io';

class CommonSignupRequest {
  const CommonSignupRequest({
    required this.roleId,
    required this.name,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    required this.address,
    required this.aadhar,
    required this.pan,
    required this.aadharFile,
    required this.panFile,
    required this.firstName,
    required this.lastName,
    required this.addressLine1,
    required this.addressLine2,
    required this.country,
    required this.state,
    required this.city,
    required this.pincode,
    required this.education,
    this.aadharBackFile,
    this.panBackFile,
    this.resultFile,
    this.addressProofFile,
  });

  final int roleId;
  final String name;
  final String phone;
  final String email;
  final String dob;
  final String gender;
  final String address;
  final String aadhar;
  final String pan;
  final File aadharFile;
  final File panFile;
  final String firstName;
  final String lastName;
  final String addressLine1;
  final String addressLine2;
  final String country;
  final String state;
  final String city;
  final String pincode;
  final String education;
  final File? aadharBackFile;
  final File? panBackFile;
  final File? resultFile;
  final File? addressProofFile;
}
