import 'package:nextfitx/common/colo_extension.dart';
import 'package:nextfitx/common_widget/round_button.dart';
import 'package:nextfitx/common_widget/round_textfield.dart';
import 'package:nextfitx/services/auth_service.dart';
import 'package:nextfitx/view/login/otp_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Email tidak boleh kosong';
      });
      return;
    }

    if (_whatsappController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Nomor WhatsApp tidak boleh kosong';
      });
      return;
    }

    // Validasi format email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Format email tidak valid';
      });
      return;
    }

    // Validasi format nomor WhatsApp
    String whatsappNumber = _whatsappController.text.trim();
    if (!whatsappNumber.startsWith('+62')) {
      whatsappNumber = '+62${whatsappNumber.replaceAll(RegExp(r'^0+'), '')}';
    }

    if (!RegExp(r'^\+62[0-9]{9,12}$').hasMatch(whatsappNumber)) {
      setState(() {
        _errorMessage = 'Format nomor WhatsApp tidak valid';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      // Validasi email terlebih dahulu
      bool emailExists = await _authService.checkEmailExists(_emailController.text.trim());
      
      if (!emailExists) {
        setState(() {
          _errorMessage = 'Email tidak terdaftar dalam sistem. Silakan daftar terlebih dahulu.';
        });
        return;
      }

      // Generate OTP code
      String otpCode = _generateOTP();

      // Simpan OTP untuk verifikasi (dalam praktik nyata, ini akan disimpan di database)
      await _authService.saveOTPForVerification(
          _emailController.text.trim(), otpCode);

      // Kirim pesan WhatsApp
      await _sendWhatsAppMessage(whatsappNumber, otpCode);

      setState(() {
        _successMessage = 'Kode verifikasi telah dikirim ke WhatsApp Anda';
      });

      // Navigate ke halaman verifikasi OTP
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationView(
              email: _emailController.text.trim(),
              whatsappNumber: whatsappNumber,
            ),
          ),
        );
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

  String _generateOTP() {
    // Generate 6 digit OTP
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber, String otpCode) async {
    final message =
        'Kode verifikasi NextFitX Anda adalah: $otpCode\n\nKode ini berlaku selama 10 menit. Jangan bagikan kode ini kepada siapapun.';
    final whatsappUrl =
        'https://wa.me/${phoneNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}';

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication);
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
          "Lupa Password",
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: media.width * 0.05),
                Text(
                  "Masukkan email dan nomor WhatsApp Anda",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: media.width * 0.02),
                Text(
                  "Kode verifikasi akan dikirim ke WhatsApp Anda",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: media.width * 0.05),
                RoundTextField(
                  hitText: "Email",
                  icon: "assets/img/email.png",
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                SizedBox(height: media.width * 0.04),
                Container(
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Nomor WhatsApp (contoh: 08123456789)",
                      prefixIcon: Icon(
                        Icons.phone,
                        color: TColor.gray,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
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
                if (_successMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _successMessage,
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ),
                SizedBox(height: media.width * 0.05),
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            TColor.primaryColor1,
                          ),
                        ),
                      )
                    : RoundButton(
                        title: "Kirim Kode Verifikasi",
                        onPressed: _sendResetCode,
                      ),
                SizedBox(height: media.width * 0.04),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Kembali ke Login",
                      style: TextStyle(
                        color: TColor.primaryColor1,
                        fontSize: 14,
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
    );
  }
}
