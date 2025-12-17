
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zamboree/auth/api_helper.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentStep = 0;

  // Controllers
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
  final cityController = TextEditingController();

  // Vehicle Info
  String vehicleType = "Car";
  final vehicleModelController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  // Documents
  XFile? profilePhoto;
  XFile? licencePhoto;
  XFile? aadharPhoto;
  XFile? insurancePhoto;

  final _formKeys = List.generate(7, (index) => GlobalKey<FormState>());

  // OTP
  String generatedOTP = "";
  final otpController = TextEditingController();
  bool otpSent = false;
  bool otpVerified = false;

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

  // Validation
  String? validateName(String? v) {
    if (v == null || v.isEmpty) return "Enter Name";
    if (!RegExp(r"^[a-zA-Z ]+$").hasMatch(v)) return "Enter valid Name";
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return "Enter Email";
    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v))
      return "Enter valid Email";
    return null;
  }

  String? validatePhone(String? v) {
    if (v == null || v.isEmpty) return "Enter Phone Number";
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v))
      return "Enter valid 10-digit Phone";
    return null;
  }

  String? validateDOB(String? v) {
    if (v == null || v.isEmpty) return "Enter Date of Birth";
    try {
      DateTime dob = DateTime.parse(v);
      if (dob.isAfter(DateTime.now())) return "Invalid Date of Birth";
    } catch (e) {
      return "Enter valid DOB (YYYY-MM-DD)";
    }
    return null;
  }

  // OTP
  // 🔹 Send OTP (Dynamic)
  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid phone number")),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏳ Sending OTP..."),
          backgroundColor: Colors.blueAccent,
        ),
      );

      // ✅ Use custom API helper instead of http.post
      final result = await ApiHelper.post(
        "/delivery/auth/send-register-otp",
        {"phone": phone},
      );

      if (result["status"] == true || result["success"] == true) {
        setState(() => otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "OTP sent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Failed to send OTP"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // 🔹 Verify OTP (Dynamic)
  Future<void> verifyOTP() async {
    final phone = phoneController.text.trim();
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter OTP to verify")),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏳ Verifying OTP..."),
          backgroundColor: Colors.blueAccent,
        ),
      );

      // ✅ Use your custom ApiHelper instead of http.post
      final result = await ApiHelper.post(
        "/delivery/auth/verify-register-otp",
        {"phone": phone, "otp": otp},
      );

      if (result["status"] == true || result["success"] == true) {
        setState(() => otpVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "OTP Verified Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Invalid OTP"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  // Step Navigation
  void nextPage() async {
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      if (_currentStep == 0) {
        if (!otpVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please verify your phone number before proceeding",
              ),
            ),
          );
          return;
        }
      }

      if (_currentStep == 1 &&
          passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
        return;
      }

      if (_currentStep < 6) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        List<String> registeredNumbers =
            prefs.getStringList('registered_numbers') ?? [];
        if (!registeredNumbers.contains(phoneController.text.trim())) {
          registeredNumbers.add(phoneController.text.trim());
          await prefs.setStringList('registered_numbers', registeredNumbers);
        }
        _submitRegistration();
      }
    }
  }

  void prevPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _submitRegistration() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⏳ Registering user, please wait..."),
          backgroundColor: Colors.blueAccent,
        ),
      );

      // Body data (match API fields)
      final Map<String, String> data = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "dob": dobController.text.trim(),
        "gender": gender,
        "password": passwordController.text.trim(),
        "vehicle_type": vehicleType,
        "vehicle_model": vehicleModelController.text.trim(),
        "vehicle_number": vehicleNumberController.text.trim(),
        "address": addressController.text.trim(),
        "city": cityController.text.trim(),
        "ifsc": ifscController.text.trim(),
        "bank_name": bankNameController.text.trim(),
        "account_number": accountNumberController.text.trim(),
        "account_holder_name": accountHolderController.text.trim(),
      };

      // Send POST request
      final result = await ApiHelper.post("/delivery/auth/register", data);


      if (result["status"] == true || result["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Registration Successful!"),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result["message"] ?? "Registration failed"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Step Title
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
        return "Documents Upload";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = 7;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: isKeyboardOpen
          ? SingleChildScrollView(
              controller: _scrollController,
              child: _buildMainContent(context, totalSteps),
            )
          : _buildMainContent(context, totalSteps),
    );
  }

  Widget _buildMainContent(BuildContext context, int totalSteps) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 220),
          painter: _CurvedPainter(),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
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

                  // Step indicator
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
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _step1Personal(),
                          _step3Password(),
                          _step4Photo(),
                          _step5Bank(),
                          _step6Address(),
                          _step7Vehicle(),
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
                      onPressed: nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentStep == 6 ? "Submit" : "Proceed",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 20),
                  if (_currentStep > 0)
                    Center(
                      child: TextButton.icon(
                        onPressed: prevPage,
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        label: const Text(
                          "Back",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===== Step 1 with OTP inside =====
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
        _inputField(
          "Phone Number",
          phoneController,
          Icons.phone,
          keyboard: TextInputType.phone,
          validator: validatePhone,
        ),
        const SizedBox(height: 10),

        if (!otpSent)
          ElevatedButton(
            onPressed: () {
              if (validatePhone(phoneController.text) == null) {
                sendOTP();
                setState(() => otpSent = true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter valid number")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Send OTP",
              style: TextStyle(color: Colors.white),
            ),
          ),

        if (otpSent && !otpVerified) ...[
          const SizedBox(height: 15),
          TextFormField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "Enter 4-digit OTP",
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: verifyOTP, // ✅ backend API call karega
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Verify OTP",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],

        if (otpVerified)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 20),
                SizedBox(width: 6),
                Text(
                  "Phone verified successfully!",
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),
        Row(
          children: [
            _genderOption("Male"),
            const SizedBox(width: 12),
            _genderOption("Female"),
          ],
        ),
      ],
    ),
  );

  // === Other Steps remain same ===
  Widget _step3Password() => Form(
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

  Widget _step4Photo() => Form(
    key: _formKeys[2],
    child: Column(
      children: [
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickFile((f) => profilePhoto = f),
          child: _uploadBox("Tap to upload your profile photo", profilePhoto),
        ),
      ],
    ),
  );

  Widget _step5Bank() => Form(
    key: _formKeys[3],
    child: Column(
      children: [
        _inputField("IFSC Code", ifscController, Icons.account_balance),
        _inputField("Bank Name", bankNameController, Icons.account_balance),
        _inputField(
          "Account Number",
          accountNumberController,
          Icons.confirmation_number,
        ),
        _inputField(
          "Account Holder Name",
          accountHolderController,
          Icons.person,
        ),
      ],
    ),
  );

  Widget _step6Address() => Form(
    key: _formKeys[4],
    child: Column(
      children: [
        _inputField("Address", addressController, Icons.home),
        _inputField("City", cityController, Icons.location_city),
      ],
    ),
  );

  Widget _step7Vehicle() => Form(
    key: _formKeys[5],
    child: Column(
      children: [
        DropdownButtonFormField<String>(
          value: vehicleType,
          decoration: _dropdownDecoration("Vehicle Type"),
          items: const [
            DropdownMenuItem(value: "Car", child: Text("Car")),
            DropdownMenuItem(value: "Bike", child: Text("Bike")),
            DropdownMenuItem(value: "Scooty", child: Text("Scooty")),
          ],
          onChanged: (v) => setState(() => vehicleType = v!),
        ),
        const SizedBox(height: 14),
        _inputField(
          "Vehicle Model",
          vehicleModelController,
          Icons.directions_car,
        ),
        _inputField("Vehicle Number", vehicleNumberController, Icons.numbers),
      ],
    ),
  );

  Widget _step8Documents() => Form(
    key: _formKeys[6],
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

  // Common Widgets
  Widget _inputField(
    String hint,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboard,
        readOnly: hint == "Date of Birth",
        onTap: hint == "Date of Birth"
            ? () async {
                FocusScope.of(context).unfocus();
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000, 1, 1),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  controller.text =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                }
              }
            : null,
        validator:
            validator ?? (v) => v == null || v.isEmpty ? "Enter $hint" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
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
        ),
      ),
    );
  }

  Widget _uploadBox(String text, XFile? file) => Container(
    height: 160,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: file == null
        ? Center(
            child: Text(text, style: const TextStyle(color: Colors.black54)),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(file.path), fit: BoxFit.cover),
          ),
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

  Widget _genderOption(String label) => Row(
    children: [
      Radio<String>(
        value: label,
        groupValue: gender,
        onChanged: (v) => setState(() => gender = v!),
        activeColor: Colors.black,
      ),
      Text(label, style: const TextStyle(fontSize: 15)),
    ],
  );
}

class _CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF19676E), Color(0xFF4A2FBD), Color(0xFFA7404C)],
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
