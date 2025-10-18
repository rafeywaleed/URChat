import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat_back_testing/model/dto.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/service/storage_service.dart';

class OtpVerificationDialog extends StatefulWidget {
  final RegisterRequest registerRequest;
  final VoidCallback? onVerificationSuccess;

  const OtpVerificationDialog({
    Key? key,
    required this.registerRequest,
    this.onVerificationSuccess,
  }) : super(key: key);

  @override
  _OtpVerificationDialogState createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _setupOtpFocus();
    _startCooldown();
  }

  void _startCooldown() {
    _resendCooldown = 30;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _setupOtpFocus() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _otpControllers[i].text.isEmpty) {
          if (i > 0) _focusNodes[i - 1].requestFocus();
        }
      });
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (index == 3 && value.isNotEmpty) {
      final otp = _getOtp();
      if (otp.length == 4) {
        _verifyAndCompleteRegistration();
      }
    }
  }

  String _getOtp() => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyAndCompleteRegistration() async {
    final otp = _getOtp();
    if (otp.length != 4) {
      NesSnackbar.show(
        context,
        text: 'Please enter the 4-digit OTP',
        type: NesSnackbarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse =
          await ApiService.completeRegistration(widget.registerRequest, otp);
      await _saveAuthData(authResponse);

      NesSnackbar.show(
        context,
        text: 'Registration completed successfully!',
        type: NesSnackbarType.success,
      );

      widget.onVerificationSuccess?.call();
      // Navigator.of(context).pop(true);
    } catch (e) {
      NesSnackbar.show(
        context,
        text: 'Registration failed: $e',
        type: NesSnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    try {
      await ApiService.resendOtp(widget.registerRequest.email, "REGISTRATION");
      NesSnackbar.show(
        context,
        text: 'OTP sent successfully!',
        type: NesSnackbarType.success,
      );

      for (var c in _otpControllers) c.clear();
      _focusNodes.first.requestFocus();
      _startCooldown();
    } catch (e) {
      NesSnackbar.show(
        context,
        text: 'Failed to resend OTP: $e',
        type: NesSnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await StorageService().saveAuthData(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
      username: authResponse.username,
      accessTokenExpiry: authResponse.accessTokenExpiry.toIso8601String(),
      refreshTokenExpiry: authResponse.refreshTokenExpiry.toIso8601String(),
    );
    ApiService.accessToken = authResponse.accessToken;
    ApiService.refreshToken = authResponse.refreshToken;
    ApiService.currentUsername = authResponse.username;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final isMobile = screenWidth < 600;
      final dialogWidth = isMobile
          ? screenWidth * 0.9
          : screenWidth < 900
              ? 400
              : 450;

      final basePadding = isMobile ? 16.0 : 24.0;
      final baseFontSize = isMobile ? 13.0 : 15.0;
      final otpBoxSize = isMobile ? 48.0 : 56.0;

      return
          // WillPopScope(
          //   onWillPop: () async {
          //     NesSnackbar.show(
          //       context,
          //       text: 'Please complete OTP verification to continue',
          //       type: NesSnackbarType.warning,
          //     );
          //     return false;
          //   },
          //   child:
          Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: dialogWidth as double,
              padding: EdgeInsets.all(basePadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VERIFY YOUR EMAIL',
                    style: TextStyle(
                      fontSize: baseFontSize + 3,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a 4-digit verification code to',
                    style: TextStyle(fontSize: baseFontSize),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.registerRequest.email,
                    style: TextStyle(
                      fontSize: baseFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: Email may land in spam folder',
                    style: TextStyle(
                      fontSize: baseFontSize - 1,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        width: otpBoxSize,
                        height: otpBoxSize,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: TextStyle(
                            fontSize: baseFontSize + 4,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _onOtpChanged(value, index),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const NesHourglassLoadingIndicator()
                  else
                    NesButton(
                      onPressed: _verifyAndCompleteRegistration,
                      type: NesButtonType.primary,
                      child: Text(
                        'Verify & Register',
                        style: TextStyle(fontSize: baseFontSize),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_isResending)
                    const NesHourglassLoadingIndicator()
                  else
                    NesButton(
                      onPressed: _resendCooldown > 0 ? null : _resendOtp,
                      type: NesButtonType.normal,
                      child: Text(
                        _resendCooldown > 0
                            ? "Resend in $_resendCooldown s"
                            : "Resend OTP",
                        style: TextStyle(fontSize: baseFontSize - 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // ),
      );
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (var c in _otpControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }
}
