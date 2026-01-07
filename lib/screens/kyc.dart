import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zamboree/auth/api_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentStep = 0;

  List<dynamic> cityList = [];
  String? selectedCityId;
  String? selectedCityName;

  List<dynamic> genderList = [];
  String? selectedGenderId;
  String? selectedGenderName;

  List<dynamic> vehicleTypeList = [];
  String? selectedVehicleTypeId;
  String? selectedVehicleTypeName;

  @override
  void initState() {
    super.initState();
    fetchCities();
    fetchGenders();
    fetchVehicleTypes(); // ✅ Load cities when page starts
  }

  Future<void> fetchCities() async {
    try {
      final result = await ApiHelper.get("/delivery/auth/cities");
      print("📥 Cities API Response: $result");

      if (result["success"] == true && result["data"] != null) {
        setState(() {
          cityList = result["data"];
        });
      } else {
        _showSnack("Failed to load cities", Colors.redAccent);
      }
    } catch (e) {
      print("❌ Error fetching cities: $e");
      _showSnack("Error loading cities: $e", Colors.redAccent);
    }
  }

  Future<void> fetchGenders() async {
    try {
      final result = await ApiHelper.get("/delivery/auth/gender");
      print("📥 Gender API Response: $result");

      if (result["success"] == true && result["data"] != null) {
        setState(() {
          genderList = result["data"];
        });
      } else {
        _showSnack("Failed to load genders", Colors.redAccent);
      }
    } catch (e) {
      print("❌ Error fetching genders: $e");
      _showSnack("Error loading genders: $e", Colors.redAccent);
    }
  }

  Future<void> fetchVehicleTypes() async {
    try {
      final result = await ApiHelper.get("/delivery/auth/vehicleType");
      print("📥 Vehicle Type API Response: $result");

      if (result["success"] == true && result["data"] != null) {
        setState(() {
          vehicleTypeList = result["data"];
        });
      } else {
        _showSnack("Failed to load vehicle types", Colors.redAccent);
      }
    } catch (e) {
      print("❌ Error fetching vehicle types: $e");
      _showSnack("Error loading vehicle types: $e", Colors.redAccent);
    }
  }

  // ---------- Controllers ----------
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  String gender = "Male";
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Bank Info
  final ifscController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final accountHolderController = TextEditingController();

  // Address Info
  final addressController = TextEditingController();
  // final cityController = TextEditingController();

  // Vehicle Info
  String vehicleType = "Car";
  final vehicleModelController = TextEditingController();
  final vehicleNumberController = TextEditingController();
  final dlNumberController = TextEditingController();
  final dlExpiryController = TextEditingController();

  // Documents
  XFile? profilePhoto;
  XFile? licencePhoto;
  XFile? aadharPhoto;
  XFile? insurancePhoto;

  // Nominee Information
  final nomineeNameController = TextEditingController();
  final nomineeRelationshipController = TextEditingController();
  final nomineeDobController = TextEditingController();
  final nomineePhoneController = TextEditingController();
  final nomineeEmergencyPhoneController = TextEditingController();

  final _formKeys = List.generate(8, (index) => GlobalKey<FormState>());

  // OTP
  final otpController = TextEditingController();
  bool otpSent = false;
  bool otpVerified = false;
  bool _isSendingOtp = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(Function(XFile) setFile) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => setFile(img));
  }

  Future<void> _captureSelfie(Function(XFile) setFile) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front, // selfie camera
      imageQuality: 70,
    );

    if (img != null) {
      setState(() => setFile(img));
    }
  }

  // ---------- Validation ----------
  String? validateName(String? v) {
    if (v == null || v.isEmpty) return "Enter Name";
    if (!RegExp(r"^[a-zA-Z ]+$").hasMatch(v)) return "Enter valid Name";
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return "Enter Email";
    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
      return "Enter valid Email";
    }
    return null;
  }

  String? validatePhone(String? v) {
    if (v == null || v.isEmpty) return "Enter Phone Number";
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      return "Enter valid 10-digit Phone";
    }
    return null;
  }

  String? validateDOB(String? v) {
    if (v == null || v.isEmpty) return "Enter Date of Birth";
    try {
      final parts = v.split('-');
      if (parts.length != 3) return "Enter valid DOB (DD-MM-YYYY)";

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final dob = DateTime(year, month, day);

      if (dob.isAfter(DateTime.now())) return "Invalid Date of Birth";
    } catch (e) {
      return "Enter valid DOB (DD-MM-YYYY)";
    }
    return null;
  }

  String convertToApiDate(String date) {
    try {
      final parts = date.split("-");
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    } catch (e) {
      return date;
    }
  }

  // ---------- OTP ----------
  // ---------- OTP ----------
  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showSnack("Please enter a valid phone number", Colors.redAccent);
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      // ✅ Remove all previous SnackBars before showing new one
      ScaffoldMessenger.of(context).clearSnackBars();

      print("📤 Sending OTP API call...");

      final result = await ApiHelper.post("/delivery/auth/send-otp", {
        "phone": phone,
      });

      print("📥 OTP API Response: $result");

      final success =
          result["status"] == true ||
          result["success"] == true ||
          result["status"] == "success";

      // ✅ Clear any existing snack before showing our custom one
      ScaffoldMessenger.of(context).clearSnackBars();

      if (success) {
        setState(() {
          otpSent = true;
          otpVerified = false;
        });

        // 🔥 Only show this clean single message
        _showSnack("OTP sent to your phone number", Colors.green);
      } else {
        _showSnack(
          result["message"] ?? "Failed to send OTP. Please try again.",
          Colors.redAccent,
        );
      }
    } catch (e) {
      print("❌ Exception in sendOTP: $e");
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSnack("Error sending OTP: $e", Colors.redAccent);
    } finally {
      setState(() => _isSendingOtp = false);
    }
  }

  Future<void> verifyOTP() async {
    final phone = phoneController.text.trim();
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      _showSnack("Please enter OTP", Colors.redAccent);
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      // ❌ No loading snackbar
      print("📤 Verifying OTP API call...");

      final result = await ApiHelper.post("/delivery/auth/verify-otp", {
        "phone": phone,
        "otp": otp,
      });

      print("📥 Verify OTP API Response: $result");

      final success =
          result["status"] == true ||
          result["success"] == true ||
          result["status"] == "success";

      // ✅ Clear any previous snackbars (optional safety)
      ScaffoldMessenger.of(context).clearSnackBars();

      if (success) {
        setState(() {
          otpVerified = true;
        });

        // ✅ Do not show any “verifying” or “success” snackbar here
        // UI already shows green “Phone verified successfully!” message
        print("✅ OTP verified successfully!");
      } else {
        _showSnack(
          result["message"] ?? "Invalid OTP. Please try again.",
          Colors.redAccent,
        );
      }
    } catch (e) {
      print("❌ Exception in verifyOTP: $e");
      _showSnack("Error verifying OTP: $e", Colors.redAccent);
    } finally {
      setState(() => _isSendingOtp = false);
    }
  }

  // ---------- Helper ----------
  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<String?> _uploadImage(XFile file, String label) async {
    try {
      final result = await ApiHelper.uploadImage(file.path);
      final msg = result["message"]?.toString().toLowerCase() ?? "";

      if (result["success"] == true ||
          result["status"] == "success" ||
          msg.contains("success") ||
          msg.contains("uploaded")) {
        //  SUCCESS par ab koi snackbar nahi dikhegi
        return result["data"]["url"];
      } else {
        _showSnack(
          result["message"] ?? "Failed to upload $label",
          Colors.redAccent,
        );
        return null;
      }
    } catch (e) {
      _showSnack("Error uploading $label: $e", Colors.redAccent);
      return null;
    }
  }

  // ---------- Navigation ----------
  void nextPage() async {
    if (!(_formKeys[_currentStep].currentState?.validate() ?? false)) return;

    if (_currentStep == 0 && !otpVerified) {
      _showSnack(
        "Please verify phone number before proceeding",
        Colors.redAccent,
      );
      return;
    }

    if (_currentStep == 1 &&
        passwordController.text != confirmPasswordController.text) {
      _showSnack("Passwords do not match", Colors.redAccent);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _submitRegistration();
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void prevPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);

      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      // 👇 YAHI ADD KARO
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<bool> _submitRegistration({bool navigate = true}) async {
    Map<String, dynamic> data = {};
    final mobile = phoneController.text.trim();

    switch (_currentStep) {
      case 0:
        data = {
          "step": 1,
          "name": nameController.text.trim(),
          "dob": dobController.text.trim(),
          "mobile": mobile,
          "gender": selectedGenderId,
        };
        break;

      case 1:
        data = {
          "step": 2,
          "mobile": mobile,
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "confirmPassword": confirmPasswordController.text.trim(),
        };
        break;

      case 2:
        if (profilePhoto == null) {
          _showSnack("Upload profile photo", Colors.redAccent);
          return false;
        }
        final profileUrl = await _uploadImage(profilePhoto!, "Profile Photo");
        if (profileUrl == null) return false;

        data = {"step": 3, "mobile": mobile, "profilePhoto": profileUrl};
        break;

      case 3:
        data = {
          "step": 4,
          "mobile": mobile,
          "ifsc": ifscController.text.trim(),
          "bankName": bankNameController.text.trim(),
          "accountNo": accountNumberController.text.trim(),
          "accountHolder": accountHolderController.text.trim(),
        };
        break;

      case 4:
        data = {
          "step": 5,
          "mobile": mobile,
          "address": addressController.text.trim(),
          "city": selectedCityId,
        };
        break;

      case 5:
        data = {
          "step": 6,
          "mobile": mobile,
          "vehicleType": selectedVehicleTypeId,
          "vehicleModel": vehicleModelController.text.trim(),
          "vehicleNo": vehicleNumberController.text.trim(),
          "dLNumber": dlNumberController.text.trim(),
          "dLExpiryDate": convertToApiDate(dlExpiryController.text.trim()),
        };
        break;

      case 6:
        data = {
          "step": 7,
          "mobile": mobile,
          "nomineeName": nomineeNameController.text.trim(),
          "relationship": nomineeRelationshipController.text.trim(),
          "nomineeDOB": nomineeDobController.text.trim(),
          "nomineeMobile": nomineePhoneController.text.trim(),
          "emergencyMobile": nomineeEmergencyPhoneController.text.trim(),
        };
        break;

      case 7:
        if (licencePhoto == null ||
            aadharPhoto == null ||
            insurancePhoto == null) {
          _showSnack("Please upload all required documents", Colors.redAccent);
          return false;
        }

        final dlUrl = await _uploadImage(licencePhoto!, "Driving Licence");
        if (dlUrl == null) return false;

        final aadharUrl = await _uploadImage(aadharPhoto!, "Aadhar Card");
        if (aadharUrl == null) return false;

        final insuranceUrl = await _uploadImage(
          insurancePhoto!,
          "Insurance Document",
        );
        if (insuranceUrl == null) return false;
        _showSnack("Image upload Successfully done!", Colors.green);

        data = {
          "step": 8,
          "mobile": mobile,
          "drivingLicense": dlUrl,
          "aadharCard": aadharUrl,
          "insuranceDoc": insuranceUrl,
        };
        break;
    }

    // _showSnack("⏳ Submitting Step ${_currentStep + 1}...", Colors.blueAccent);
    final result = await ApiHelper.post("/delivery/auth/register", data);

    print("📤 Sent Data: $data");
    print("📥 Response: $result");

    final msg = result["message"]?.toString().toLowerCase() ?? "";
    final success =
        result["status"] == true ||
        result["success"] == true ||
        result["status"] == "success" ||
        msg.contains("success") ||
        msg.contains("uploaded");

    if (success) {
      if (!navigate) {
        _showSnack(
          result["message"] ?? "Proceeding to OTP...",
          Colors.blueAccent,
        );
      }
      // ✅ If last step, handle token
      if (_currentStep == 7 && result["token"] != null) {
        print("✅ Token received: ${result["token"]}");
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", result["token"]);
      }

      if (navigate) {
        if (_currentStep < 7) {
          setState(() => _currentStep++);
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          await Future.delayed(const Duration(milliseconds: 50));
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        } else {
          _showSnack("Registration completed!", Colors.green);
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
      return true;
    } else {
      // Step 1 already registered handling
      if (_currentStep == 0 &&
          result["message"] != null &&
          result["message"].toString().toLowerCase().contains("already")) {
        if (!navigate) {
          _showSnack(result["message"], Colors.blueAccent);
        }
        if (navigate && _currentStep < 7) {
          setState(() => _currentStep++);
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
        return true;
      }

      _showSnack(
        result["message"] ?? "Step submission failed",
        Colors.redAccent,
      );
      return false;
    }
  }

  // ---------- Step Titles ----------
  String getStepTitle() {
    switch (_currentStep) {
      case 0:
        return "Personal Information";
      case 1:
        return "Security Information";
      case 2:
        return "Profile Photo Upload";
      case 3:
        return "Bank Information";
      case 4:
        return "Address Information";
      case 5:
        return "Vehicle Information";
      case 6:
        return "Nominee Information";
      case 7:
        return "Documents Upload";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = 8;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: _buildMainContent(context, totalSteps),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, int totalSteps) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 220),
          painter: _CurvedPainter(),
        ),

        /// ⭐ SAFE AREA UI
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                const Center(
                  child: Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Center(
                  child: Text(
                    "Please fill in the following details to continue",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    getStepTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // ---- Step Indicator ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (index) {
                    return Container(
                      width: 22,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? Colors.black
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),

                // ---- Step Pages ----
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox(
                    height: () {
                      final h = MediaQuery.of(context).size.height;

                      // STEP 1 — Personal + OTP case handle
                      if (_currentStep == 0) {
                        // OTP tabhi height badhao jab OTP field visible ho
                        bool showOtpField = otpSent && !otpVerified;
                        return showOtpField ? h * 0.60 : h * 0.46;
                      }

                      if (_currentStep == 1) return h * 0.48; // Password
                      if (_currentStep == 2) return h * 0.42; // Photo
                      if (_currentStep == 3) return h * 0.55; // Bank
                      if (_currentStep == 4) return h * 0.48; //
                      if (_currentStep == 5) return h * 0.62; // Vehicle
                      if (_currentStep == 6) {
                        return h * 0.70; // Nominee (zyada fields)
                      }

                      // STEP 8 — Documents (big images so more height)
                      return h * 0.75;
                    }(),

                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _step1Personal(),
                        _step2Password(),
                        _step3Photo(),
                        _step4Bank(),
                        _step5Address(),
                        _step6Vehicle(),
                        _step7Nominee(),
                        _step8Documents(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentStep == 7 ? "Submit" : "Proceed",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                if (_currentStep == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        ),

        /// 🔥 WORKING BACK BUTTON ON TOP
        if (_currentStep > 0)
          Positioned(
            top: 50,
            left: 18,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: prevPage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Color.fromARGB(255, 7, 7, 7),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------- Steps ----------
  Widget _step1Personal() => Form(
    key: _formKeys[0],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField(
          "Full Name",
          nameController,
          Icons.person_outline,
          validator: validateName,
        ),
        _inputField(
          "Date of Birth",
          dobController,
          Icons.calendar_today,
          validator: validateDOB,
        ),

        // ✅ Gender dropdown (moved above Phone Number)
        DropdownButtonFormField<String>(
          initialValue: selectedGenderId,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person, color: Colors.black54),
            hintText: "Select Gender",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 15,
            ),
          ),
          items: genderList.map<DropdownMenuItem<String>>((gender) {
            return DropdownMenuItem<String>(
              value: gender["_id"],
              child: Row(
                children: [
                  Image.network(
                    gender["image"],
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person),
                  ),
                  const SizedBox(width: 8),
                  Text(gender["name"]),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedGenderId = value;
              selectedGenderName = genderList.firstWhere(
                (g) => g["_id"] == value,
              )["name"];
            });
          },
          validator: (value) => value == null ? "Please select gender" : null,
        ),

        const SizedBox(height: 14),

        // ✅ Phone number with integrated OTP button
        _inputField(
          "Phone Number",
          phoneController,
          Icons.phone,
          keyboard: TextInputType.phone,
          validator: validatePhone,
          maxLength: 10,
          suffixIcon: otpVerified
              ? const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.verified, color: Colors.green),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _isSendingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF19676E),
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: _isSendingOtp
                              ? null
                              : () async {
                                  if (!(_formKeys[0].currentState?.validate() ??
                                      false)) {
                                    return; // ❌ agar form valid nahi to OTP call nahi
                                  }

                                  setState(() => _isSendingOtp = true);

                                  //  Step-1 registration submit (without navigation)
                                  final registered = await _submitRegistration(
                                    navigate: false,
                                  );

                                  if (registered) {
                                    await sendOTP(); // Ab backend user ko pehchanega → OTP हमेशा first click me jayega
                                  }

                                  setState(() => _isSendingOtp = false);
                                },

                          child: Text(
                            otpSent ? "Resend" : "Send OTP",
                            style: const TextStyle(
                              color: Color(0xFF19676E),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                ),
        ),

        const SizedBox(height: 10),

        if (otpSent && !otpVerified) ...[
          const SizedBox(height: 15),
          _inputField(
            "Enter 6-digit OTP",
            otpController,
            Icons.lock_clock_outlined,
            keyboard: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _isSendingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: verifyOTP,
                      child: const Text(
                        "Verify",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _step2Password() => Form(
    key: _formKeys[1],
    child: Column(
      children: [
        _inputField(
          "Email",
          emailController,
          Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
          validator: validateEmail,
        ),
        _inputField(
          "Password",
          passwordController,
          Icons.lock_outline,
          isPassword: true,
        ),
        _inputField(
          "Confirm Password",
          confirmPasswordController,
          Icons.lock,
          isPassword: true,
        ),
      ],
    ),
  );

  Widget _step3Photo() => Form(
    key: _formKeys[2],
    child: Column(
      children: [
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _captureSelfie((f) => profilePhoto = f),
          child: _uploadBox("Click your live selfie", profilePhoto),
        ),
      ],
    ),
  );

  Widget _step4Bank() => Form(
    key: _formKeys[3],
    child: Column(
      children: [
        // _inputField("IFSC Code", ifscController, Icons.account_balance),
        _inputField("Bank Name", bankNameController, Icons.account_balance),
        _inputField(
          "Account Number",
          accountNumberController,
          Icons.confirmation_number,
        ),
        _inputField("IFSC Code", ifscController, Icons.account_balance),
        _inputField(
          "Account Holder Name",
          accountHolderController,
          Icons.person,
        ),
      ],
    ),
  );

  Widget _step5Address() => Form(
    key: _formKeys[4],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField("Address", addressController, Icons.home),

        const SizedBox(height: 14),

        // ✅ City dropdown from API
        DropdownButtonFormField<String>(
          initialValue: selectedCityId,
          decoration: _dropdownDecoration("Select City"),
          items: cityList.map<DropdownMenuItem<String>>((city) {
            return DropdownMenuItem<String>(
              value: city["_id"],
              child: Text(city["name"]),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCityId = value;
              selectedCityName = cityList.firstWhere(
                (city) => city["_id"] == value,
              )["name"];
            });
          },
          validator: (value) => value == null ? "Please select a city" : null,
        ),
      ],
    ),
  );

  Widget _step6Vehicle() => Form(
    key: _formKeys[5],
    child: Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedVehicleTypeId,
          decoration: _dropdownDecoration("Vehicle Type"),
          items: vehicleTypeList.map<DropdownMenuItem<String>>((vType) {
            return DropdownMenuItem<String>(
              value: vType["_id"],
              child: Text(vType["name"]),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedVehicleTypeId = value;
              selectedVehicleTypeName = vehicleTypeList.firstWhere(
                (v) => v["_id"] == value,
              )["name"];
            });
          },
          validator: (value) =>
              value == null ? "Please select vehicle type" : null,
        ),

        const SizedBox(height: 14),

        _inputField(
          "Vehicle Model",
          vehicleModelController,
          Icons.directions_car,
        ),

        _inputField("Vehicle Number", vehicleNumberController, Icons.numbers),

        _inputField(
          "Driving Licence Number",
          dlNumberController,
          Icons.badge_outlined,
        ),

        _inputField("DL Expiry Date", dlExpiryController, Icons.calendar_month),
      ],
    ),
  );

  Widget _step7Nominee() => Form(
    key: _formKeys[6],
    child: Column(
      children: [
        _inputField(
          "Nominee Name",
          nomineeNameController,
          Icons.person_outline,
          validator: validateName,
        ),
        _inputField(
          "Relationship",
          nomineeRelationshipController,
          Icons.family_restroom,
        ),
        _inputField(
          "Nominee DOB",
          nomineeDobController,
          Icons.calendar_today,
          validator: validateDOB,
        ),
        _inputField(
          "Nominee Mobile Number",
          nomineePhoneController,
          Icons.phone,
          keyboard: TextInputType.phone,
          validator: validatePhone,
          maxLength: 10,
        ),
        _inputField(
          "Emergency Mobile Number",
          nomineeEmergencyPhoneController,
          Icons.phone_android,
          keyboard: TextInputType.phone,
          validator: validatePhone,
          maxLength: 10,
        ),
      ],
    ),
  );

  Widget _step8Documents() => Form(
    key: _formKeys[7],
    child: Column(
      children: [
        GestureDetector(
          onTap: () => _pickFile((f) => licencePhoto = f),
          child: _uploadBox("Upload Driving Licence", licencePhoto),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _pickFile((f) => aadharPhoto = f),
          child: _uploadBox("Upload Aadhar Card", aadharPhoto),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _pickFile((f) => insurancePhoto = f),
          child: _uploadBox(
            "Upload Vehicle Insurance Document",
            insurancePhoto,
          ),
        ),
      ],
    ),
  );

  // ---------- Common Widgets ----------
  Widget _inputField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboard,
        maxLength: maxLength,
        textAlign: textAlign,
        readOnly:
            hint == "Date of Birth" ||
            hint == "DL Expiry Date" ||
            hint == "Nominee DOB",
        onTap:
            (hint == "Date of Birth" ||
                hint == "DL Expiry Date" ||
                hint == "Nominee DOB")
            ? () async {
                FocusScope.of(context).unfocus();
                DateTime initial =
                    (hint == "Date of Birth" || hint == "Nominee DOB")
                    ? DateTime(2000, 1, 1)
                    : DateTime.now();
                DateTime first =
                    (hint == "Date of Birth" || hint == "Nominee DOB")
                    ? DateTime(1900)
                    : DateTime.now();
                DateTime last =
                    (hint == "Date of Birth" || hint == "Nominee DOB")
                    ? DateTime.now()
                    : DateTime(2100);

                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: first,
                  lastDate: last,
                );
                if (pickedDate != null) {
                  controller.text =
                      "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
                }
              }
            : null,
        validator:
            validator ?? (v) => v == null || v.isEmpty ? "Enter $hint" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54),

          labelText: hint,

          // Normal label color
          labelStyle: const TextStyle(color: Colors.black54),

          // Floating label color (jab upar chala jata hai)
          floatingLabelStyle: const TextStyle(
            color: Colors.red, // 👈 apni pasand ka color
            fontWeight: FontWeight.w600,
          ),

          floatingLabelBehavior: FloatingLabelBehavior.auto,

          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          suffixIcon: suffixIcon,
          counterText: "",
        ),
      ),
    );
  }

  Widget _uploadBox(String label, XFile? file) => Stack(
    children: [
      Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: file == null
            ? Center(
                child: Text(
                  "Tap to upload $label",
                  style: const TextStyle(color: Colors.black54),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(file.path), fit: BoxFit.cover),
              ),
      ),

      /// 🔥 Floating Label
      Positioned(
        left: 12,
        top: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );

  InputDecoration _dropdownDecoration(String hint) => InputDecoration(
    prefixIcon: const Icon(Icons.directions_car, color: Colors.black54),
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.black26),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
  );

  // Widget _genderOption(String label) => Row(
  //   children: [
  //     Radio<String>(
  //       value: label,
  //       groupValue: gender,
  //       onChanged: (v) => setState(() => gender = v!),
  //       activeColor: Colors.black,
  //     ),
  //     Text(label, style: const TextStyle(fontSize: 15)),
  //   ],
  // );
}

class _CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF19676E), Color(0xFF4A2FBD), Color(0xFF40A798)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.lineTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.5,
      size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.4,
      size.width,
      size.height * 0.55,
    );
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
