import 'package:image_picker/image_picker.dart';

class DeliverySignupRequest {
  const DeliverySignupRequest({
    required this.roleId,
    required this.name,
    required this.phone,
    required this.email,
    required this.dob,
    required this.gender,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.aadharNumber,
    required this.aadharFrontFile,
    required this.aadharBackFile,
    required this.panNumber,
    required this.panFrontFile,
    required this.panBackFile,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.drivingLicenseNo,
    required this.drivingLicenseFrontFile,
    required this.drivingLicenseBackFile,
    required this.qualification,
    required this.qualificationCertifications,
    this.addressProof,
  });

  final int roleId;
  final String name;
  final String phone;
  final String email;
  final String dob;
  final String gender;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String aadharNumber;
  final XFile aadharFrontFile;
  final XFile aadharBackFile;
  final String panNumber;
  final XFile panFrontFile;
  final XFile panBackFile;
  final String vehicleType;
  final String vehicleNumber;
  final String drivingLicenseNo;
  final XFile drivingLicenseFrontFile;
  final XFile drivingLicenseBackFile;
  final String qualification;
  final XFile qualificationCertifications;
  final XFile? addressProof;
}
