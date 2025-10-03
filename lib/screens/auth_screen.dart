import 'package:flutter/material.dart';
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
      } else {
        await ApiService.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          _fullNameController.text,
        );
      }

      _usernameController.clear();
      _passwordController.clear();
      _emailController.clear();
      _fullNameController.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homescreen()),
      );
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
                  Text(
                    "URChat",
                    style: TextStyle(
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
                                decoration: _inputStyle("Password"),
                                obscureText: true,
                                validator: (value) =>
                                    value!.isEmpty ? "Enter password" : null,
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
                                decoration: _inputStyle("Email"),
                                validator: (value) =>
                                    value!.isEmpty ? "Enter email" : null,
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
                                decoration: _inputStyle("Password"),
                                obscureText: true,
                                validator: (value) =>
                                    value!.isEmpty ? "Enter password" : null,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),

                  _isLoading
                      ? const CircularProgressIndicator()
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
