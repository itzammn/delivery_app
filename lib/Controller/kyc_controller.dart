// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:zamboree/auth/api_helper.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class KycController extends GetxController {
//   final pageController = PageController();
//   final scrollController = ScrollController();
//   int currentStep = 0;

//   List<dynamic> cityList = [];
//   String? selectedCityId;
//   String? selectedCityName;

//   List<dynamic> genderList = [];
//   String? selectedGenderId;
//   String? selectedGenderName;

//   final formKeys = List.generate(7, (index) => GlobalKey<FormState>());

//   final nameController = TextEditingController();
//   final dobController = TextEditingController();
//   final phoneController = TextEditingController();
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();

//   final ifscController = TextEditingController();
//   final bankNameController = TextEditingController();
//   final accountNumberController = TextEditingController();
//   final accountHolderController = TextEditingController();

//   final addressController = TextEditingController();

//   String vehicleType = "Car";
//   final vehicleModelController = TextEditingController();
//   final vehicleNumberController = TextEditingController();
//   final dlNumberController = TextEditingController();
//   final dlExpiryController = TextEditingController();

//   XFile? profilePhoto;
//   XFile? licencePhoto;
//   XFile? aadharPhoto;
//   XFile? insurancePhoto;

//   final otpController = TextEditingController();
//   bool otpSent = false;
//   bool otpVerified = false;

//   @override
//   void onInit() {
//     super.onInit();
//     fetchCities();
//     fetchGenders();
//   }

//   void showSnack(String msg, Color color) {
//     ScaffoldMessenger.of(
//       Get.context!,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
//   }

//   Future<void> fetchCities() async {
//     final result = await ApiHelper.get("/delivery/auth/cities");
//     if (result["success"] == true && result["data"] != null) {
//       cityList = result["data"];
//       update();
//     } else {
//       showSnack("Failed to load cities", Colors.redAccent);
//     }
//   }

//   Future<void> fetchGenders() async {
//     final result = await ApiHelper.get("/delivery/auth/gender");
//     if (result["success"] == true && result["data"] != null) {
//       genderList = result["data"];
//       update();
//     } else {
//       showSnack("Failed to load genders", Colors.redAccent);
//     }
//   }

//   Future<void> pickFile(Function(XFile) setFile) async {
//     final picker = ImagePicker();
//     final img = await picker.pickImage(source: ImageSource.gallery);
//     if (img != null) {
//       setFile(img);
//       update();
//     }
//   }

//   Future<void> sendOTP() async {
//     final phone = phoneController.text.trim();
//     if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
//       showSnack("Please enter valid phone", Colors.redAccent);
//       return;
//     }

//     final registered = await submitRegistration(navigate: false);
//     if (!registered) return;

//     final res = await ApiHelper.post("/delivery/auth/send-otp", {
//       "phone": phone,
//     });

//     if (res["success"] == true || res["status"] == true) {
//       otpSent = true;
//       otpVerified = false;
//       showSnack("OTP Sent", Colors.green);
//     } else {
//       showSnack("OTP failed", Colors.redAccent);
//     }
//     update();
//   }

//   Future<void> verifyOTP() async {
//     final result = await ApiHelper.post("/delivery/auth/verify-otp", {
//       "phone": phoneController.text.trim(),
//       "otp": otpController.text.trim(),
//     });

//     if (result["success"] == true || result["status"] == true) {
//       otpVerified = true;
//     } else {
//       showSnack("Invalid OTP", Colors.redAccent);
//     }
//     update();
//   }

//   Future<bool> submitRegistration({bool navigate = true}) async {
//     Map<String, dynamic> data = {};
//     final mobile = phoneController.text.trim();

//     switch (currentStep) {
//       case 0:
//         data = {
//           "step": 1,
//           "name": nameController.text.trim(),
//           "dob": dobController.text.trim(),
//           "mobile": mobile,
//           "gender": selectedGenderId,
//         };
//         break;

//       case 1:
//         data = {
//           "step": 2,
//           "mobile": mobile,
//           "email": emailController.text.trim(),
//           "password": passwordController.text.trim(),
//           "confirmPassword": confirmPasswordController.text.trim(),
//         };
//         break;

//       case 2:
//         if (profilePhoto == null) {
//           showSnack("Upload profile photo", Colors.redAccent);
//           return false;
//         }
//         data = {
//           "step": 3,
//           "mobile": mobile,
//           "profilePhoto": base64Encode(
//             await File(profilePhoto!.path).readAsBytes(),
//           ),
//         };
//         break;

//       case 3:
//         data = {
//           "step": 4,
//           "mobile": mobile,
//           "ifsc": ifscController.text.trim(),
//           "bankName": bankNameController.text.trim(),
//           "accountNo": accountNumberController.text.trim(),
//           "accountHolder": accountHolderController.text.trim(),
//         };
//         break;

//       case 4:
//         data = {
//           "step": 5,
//           "mobile": mobile,
//           "address": addressController.text.trim(),
//           "city": selectedCityId,
//         };
//         break;

//       case 5:
//         data = {
//           "step": 6,
//           "mobile": mobile,
//           "vehicleType": vehicleType,
//           "vehicleModel": vehicleModelController.text.trim(),
//           "vehicleNo": vehicleNumberController.text.trim(),
//           "dlNumber": dlNumberController.text.trim(),
//           "dlExpiry": dlExpiryController.text.trim(),
//         };
//         break;

//       case 6:
//         if (licencePhoto == null ||
//             aadharPhoto == null ||
//             insurancePhoto == null) {
//           showSnack("Upload all docs", Colors.redAccent);
//           return false;
//         }
//         data = {
//           "step": 7,
//           "mobile": mobile,
//           "drivingLicense": base64Encode(
//             await File(licencePhoto!.path).readAsBytes(),
//           ),
//           "aadharCard": base64Encode(
//             await File(aadharPhoto!.path).readAsBytes(),
//           ),
//           "insuranceDoc": base64Encode(
//             await File(insurancePhoto!.path).readAsBytes(),
//           ),
//         };
//         break;
//     }

//     final result = await ApiHelper.post("/delivery/auth/register", data);

//     final success = result["success"] == true || result["status"] == true;

//     if (success) {
//       if (currentStep == 6 && result["token"] != null) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString("token", result["token"]);
//       }

//       if (navigate) {
//         if (currentStep < 6) {
//           currentStep++;
//           pageController.nextPage(
//             duration: Duration(milliseconds: 400),
//             curve: Curves.easeInOut,
//           );
//         } else {
//           showSnack("Registration Complete", Colors.green);
//           Get.offAllNamed("/login");
//         }
//       }
//       update();
//       return true;
//     }

//     showSnack(result["message"] ?? "Failed", Colors.redAccent);
//     return false;
//   }

//   void nextPage() async {
//     if (!(formKeys[currentStep].currentState?.validate() ?? false)) return;

//     if (currentStep == 0 && !otpVerified) {
//       showSnack("Verify Phone First", Colors.redAccent);
//       return;
//     }

//     if (currentStep == 1 &&
//         passwordController.text != confirmPasswordController.text) {
//       showSnack("Passwords do not match", Colors.redAccent);
//       return;
//     }

//     await submitRegistration();
//   }

//   void prevPage() {
//     if (currentStep > 0) {
//       currentStep--;
//       pageController.previousPage(
//         duration: Duration(milliseconds: 400),
//         curve: Curves.easeInOut,
//       );
//       update();
//     } else {
//       Get.back();
//     }
//   }
// }
