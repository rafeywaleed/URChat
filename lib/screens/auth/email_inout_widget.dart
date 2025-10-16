import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat_back_testing/service/api_service.dart';

class EmailInputDialog extends StatefulWidget {
  const EmailInputDialog({Key? key}) : super(key: key);

  @override
  _EmailInputDialogState createState() => _EmailInputDialogState();
}

class _EmailInputDialogState extends State<EmailInputDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false; // Add loading state

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final isSmall = screenWidth < 400;
      final dialogWidth = isSmall ? screenWidth * 0.9 : 380;
      final fontSize = isSmall ? 13.0 : 15.0;
      final buttonFont = isSmall ? 12.0 : 14.0;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        backgroundColor: Colors.transparent,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: dialogWidth as double,
              padding: EdgeInsets.all(isSmall ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter Your Email',
                    style: TextStyle(
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.center,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Show loading indicator or buttons
                  if (_isLoading)
                    const NesHourglassLoadingIndicator()
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: NesButton(
                            onPressed: () => Navigator.pop(context),
                            type: NesButtonType.normal,
                            child: Text(
                              'Cancel',
                              style: TextStyle(fontSize: buttonFont),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NesButton(
                            onPressed: _submitEmail,
                            type: NesButtonType.primary,
                            child: Text(
                              'Continue',
                              style: TextStyle(fontSize: buttonFont),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      NesSnackbar.show(
        context,
        text: "Please enter a valid email",
        type: NesSnackbarType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.forgotPassword(email);
      if (mounted) {
        Navigator.pop(context, email);
      }
    } catch (e) {
      if (mounted) {
        NesSnackbar.show(
          context,
          text: "Failed to send OTP: $e",
          type: NesSnackbarType.error,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
