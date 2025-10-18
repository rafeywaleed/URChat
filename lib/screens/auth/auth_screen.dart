import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/screens/auth/email_inout_widget.dart';
import 'package:urchat_back_testing/screens/auth/otp_verification_dialog.dart';
import 'package:urchat_back_testing/screens/auth/password_reset_screen.dart';
import 'package:urchat_back_testing/screens/home_screen.dart';
import 'package:urchat_back_testing/service/api_service.dart';

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
  bool _obscurePassword = true;

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

  InputDecoration _inputStyle(String label, {bool isPassword = false}) {
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
      // Add suffix icon for password fields
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: _brown.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            )
          : null,
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 6) {
      return '6 characters';
    }
    return null;
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
                                validator: (value) =>
                                    value!.isEmpty ? "Enter username" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration:
                                    _inputStyle("Password", isPassword: true),
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 8),
                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () async {
                                      final email = await showDialog<String>(
                                        context: context,
                                        builder: (context) =>
                                            EmailInputDialog(),
                                      );

                                      if (email != null && email.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PasswordResetScreen(
                                                    email: email),
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
                                validator: (value) =>
                                    value!.isEmpty ? "Enter full name" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputStyle("Email"),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Enter email';
                                  }
                                  // Basic email validation
                                  if (!value.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _usernameController,
                                decoration: _inputStyle("Username"),
                                validator: (value) =>
                                    value!.isEmpty ? "Enter username" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration:
                                    _inputStyle("Password", isPassword: true),
                                obscureText: _obscurePassword,
                                validator:
                                    _validatePassword, // Use the validation method
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
                        // Clear form when switching modes
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
