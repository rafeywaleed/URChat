import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat/model/dto.dart';
import 'package:urchat/screens/auth/email_inout_widget.dart';
import 'package:urchat/screens/auth/otp_verification_dialog.dart';
import 'package:urchat/screens/auth/password_reset_screen.dart';
import 'package:urchat/screens/home_screen.dart';
import 'package:urchat/service/api_service.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  final Color _beige = const Color(0xFFF5F5DC);
  final Color _brown = const Color(0xFF5C4033);

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await ApiService.login(
            _usernameController.text, _passwordController.text);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homescreen()),
        );
      } else {
        final registerRequest = RegisterRequest(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
        );

        await ApiService.initiateRegistration(registerRequest);

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => OtpVerificationDialog(
            registerRequest: registerRequest,
            onVerificationSuccess: () {
              _usernameController.clear();
              _passwordController.clear();
              _emailController.clear();
              _fullNameController.clear();

              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Homescreen()),
              );
            },
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _brown,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Comprehensive validation methods
  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    // if (value.length > 50) {
    //   return 'Full name cannot exceed 50 characters';
    // }
    // Allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Zà-ÿÀ-Ÿ '\-]+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Full name can only contain letters, spaces, hyphens, and apostrophes';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Check for spaces
    if (value.contains(' ')) {
      return 'Email cannot contain spaces';
    }

    // Basic email format validation
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    // Check for consecutive dots
    if (value.contains('..')) {
      return 'Email cannot contain consecutive dots';
    }

    // Check for special characters at the beginning or end
    if (value.startsWith('.') ||
        value.endsWith('.') ||
        value.startsWith('@') ||
        value.endsWith('@')) {
      return 'Email cannot start or end with special characters';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 20) {
      return 'Username cannot exceed 20 characters';
    }
    if (value.contains(' ')) {
      return 'Username cannot contain spaces';
    }
    // Check for uppercase letters
    if (value.contains(RegExp(r'[A-Z]'))) {
      return 'Username cannot contain uppercase letters';
    }
    // Allow lowercase letters, numbers, underscores, hyphens, and dots
    final usernameRegex = RegExp(r'^[a-z0-9_.-]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain lowercase letters, numbers, underscores, hyphens, and dots';
    }
    // Cannot start or end with special characters
    if (value.startsWith('_') ||
        value.endsWith('_') ||
        value.startsWith('-') ||
        value.endsWith('-') ||
        value.startsWith('.') ||
        value.endsWith('.')) {
      return 'Username cannot start or end with underscores, hyphens, or dots';
    }

    if (value.contains('__') ||
        value.contains('--') ||
        value.contains('..') ||
        value.contains('_-') ||
        value.contains('_.') ||
        value.contains('-.') ||
        value.contains('-_') ||
        value.contains('.-') ||
        value.contains('. _') ||
        value.contains('._')) {
      return 'Username cannot contain consecutive special characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 5) {
      return 'Password must be at least 5 characters';
    }
    if (value.length > 128) {
      return 'Password cannot exceed 128 characters';
    }
    if (value.contains(' ')) {
      return 'Password cannot contain spaces';
    }

    // Check for at least one uppercase letter
    // if (!value.contains(RegExp(r'[A-Z]'))) {
    //   return 'Password must contain at least one uppercase letter';
    // }

    // Check for at least one lowercase letter
    // if (!value.contains(RegExp(r'[a-z]'))) {
    //   return 'Password must contain at least one lowercase letter';
    // }

    // Check for at least one number
    // if (!value.contains(RegExp(r'[0-9]'))) {
    //   return 'Password must contain at least one number';
    // }

    // Check for at least one special character
    // if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    //   return 'Password must contain at least one special character';
    // }

    // Check for common insecure patterns
    // if (RegExp(r'(.)\1{2,}').hasMatch(value)) {
    //   return 'Password cannot contain 3 or more identical characters in a row';
    // }

    // Check for sequential characters
    // if (_hasSequentialCharacters(value)) {
    //   return 'Password cannot contain sequential characters (e.g., abc, 123)';
    // }

    return null;
  }

  String? _validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  // Helper method to check for sequential characters
  // bool _hasSequentialCharacters(String input) {
  //   for (int i = 0; i < input.length - 2; i++) {
  //     int char1 = input.codeUnitAt(i);
  //     int char2 = input.codeUnitAt(i + 1);
  //     int char3 = input.codeUnitAt(i + 2);

  //     // Check for ascending sequence (abc, 123)
  //     if (char2 == char1 + 1 && char3 == char2 + 1) {
  //       return true;
  //     }
  //     // Check for descending sequence (cba, 321)
  //     if (char2 == char1 - 1 && char3 == char2 - 1) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _brown, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _brown, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _brown.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: _beige,
      body: Center(
        child: SingleChildScrollView(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(24),
            width: isWide ? 420 : MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_rounded,
                      size: 60, color: _brown.withOpacity(0.9)),
                  const SizedBox(height: 10),
                  NesRunningText(
                    speed: 0.3,
                    running: true,
                    text: "URChat",
                    textStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _brown,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Animated Switch
                  AnimatedSwitcher(
                    switchInCurve: Curves.easeIn,
                    duration: const Duration(milliseconds: 500),
                    child: _isLogin
                        ? Column(
                            key: ValueKey("login"),
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                decoration: _inputStyle("Username"),
                                validator: _validateUsername,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: ValueKey("login_password"),
                                controller: _passwordController,
                                decoration: _inputStyle("Password"),
                                validator: _validateLoginPassword,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    final email = await showDialog<String>(
                                      context: context,
                                      builder: (context) => EmailInputDialog(),
                                    );

                                    if (email != null && email.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PasswordResetScreen(email: email),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: _brown,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            key: ValueKey("register"),
                            children: [
                              TextFormField(
                                controller: _fullNameController,
                                decoration: _inputStyle("Full Name"),
                                validator: _validateFullName,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputStyle("Email"),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _usernameController,
                                decoration: _inputStyle("Username"),
                                validator: _validateUsername,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: ValueKey("register_password"),
                                controller: _passwordController,
                                decoration: _inputStyle("Password"),
                                validator: _validatePassword,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),

                  _isLoading
                      ? const NesHourglassLoadingIndicator()
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            _isLogin ? "Login" : "Register",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        if (_isLogin) {
                          _emailController.clear();
                          _fullNameController.clear();
                        }
                      });
                    },
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Register"
                          : "Already have an account? Login",
                      style: TextStyle(
                        color: _brown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
