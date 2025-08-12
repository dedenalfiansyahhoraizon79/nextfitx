import 'package:nextfitx/common/colo_extension.dart';
import 'package:nextfitx/common_widget/round_button.dart';
import 'package:nextfitx/services/auth_service.dart';
import 'package:nextfitx/view/login/reset_password_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class OtpVerificationView extends StatefulWidget {
  final String email;
  final String whatsappNumber;

  const OtpVerificationView({
    super.key,
    required this.email,
    required this.whatsappNumber,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  String _getOtpCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    String otpCode = _getOtpCode();
    
    if (otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Masukkan 6 digit kode verifikasi';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      bool isValid = await _authService.verifyOTP(widget.email, otpCode);
      
      if (isValid) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordView(
                email: widget.email,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Kode verifikasi tidak valid atau sudah kadaluarsa';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String newOtpCode = _generateOTP();
      await _authService.saveOTPForVerification(widget.email, newOtpCode);
      
      // Kirim ulang pesan WhatsApp
      await _sendWhatsAppMessage(widget.whatsappNumber, newOtpCode);
      
      // Reset timer
      _startResendTimer();
      
      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kode verifikasi baru telah dikirim'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _generateOTP() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber, String otpCode) async {
    final message = 'Kode verifikasi NextFitX Anda adalah: $otpCode\n\nKode ini berlaku selama 10 menit. Jangan bagikan kode ini kepada siapapun.';
    final whatsappUrl = 'https://wa.me/${phoneNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Tidak dapat membuka WhatsApp');
      }
    } catch (e) {
      throw Exception('Gagal mengirim pesan WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: TColor.black),
        ),
        title: Text(
          "Verifikasi Kode",
          style: TextStyle(
            color: TColor.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: media.width * 0.05),
                Icon(
                  Icons.phone_android,
                  size: 80,
                  color: TColor.primaryColor1,
                ),
                SizedBox(height: media.width * 0.04),
                Text(
                  "Masukkan kode verifikasi",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: media.width * 0.02),
                Text(
                  "Kode telah dikirim ke WhatsApp Anda",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: media.width * 0.05),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => Container(
                      width: 45,
                      height: 55,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: TColor.gray.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        onChanged: (value) => _onOtpChanged(value, index),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                SizedBox(height: media.width * 0.05),
                _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          TColor.primaryColor1,
                        ),
                      )
                    : RoundButton(
                        title: "Verifikasi",
                        onPressed: _verifyOtp,
                      ),
                SizedBox(height: media.width * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Tidak menerima kode? ",
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _canResend ? _resendOtp : null,
                      child: Text(
                        _canResend ? "Kirim Ulang" : "Kirim Ulang ($_resendTimer)",
                        style: TextStyle(
                          color: _canResend ? TColor.primaryColor1 : TColor.gray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
  }
} 