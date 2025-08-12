import 'package:nextfitx/common/colo_extension.dart';
import 'package:nextfitx/common_widget/round_button.dart';
import 'package:nextfitx/services/auth_service.dart';
import 'package:nextfitx/view/login/login_view.dart';
import 'package:flutter/material.dart';

class ResetPasswordView extends StatefulWidget {
  final String email;

  const ResetPasswordView({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Password baru tidak boleh kosong';
      });
      return;
    }

    if (_confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Konfirmasi password tidak boleh kosong';
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Password dan konfirmasi password tidak sama';
      });
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password minimal 6 karakter';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      await _authService.resetPasswordWithOTP(
        widget.email,
        _newPasswordController.text.trim(),
      );

      setState(() {
        _successMessage = 'Password berhasil diubah';
      });

      // Tampilkan dialog sukses
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Berhasil',
                style: TextStyle(
                  color: TColor.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'Password Anda berhasil diubah. Silakan login dengan password baru.',
                style: TextStyle(color: TColor.gray),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: TColor.primaryColor1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
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
          "Reset Password",
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
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: TColor.primaryColor1,
                ),
                SizedBox(height: media.width * 0.04),
                Text(
                  "Buat Password Baru",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: media.width * 0.02),
                Text(
                  "Masukkan password baru untuk akun Anda",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: media.width * 0.05),
                Container(
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      hintText: "Password Baru",
                      prefixIcon: Image.asset(
                        "assets/img/lock.png",
                        width: 20,
                        height: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                          color: TColor.gray,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.04),
                Container(
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: "Konfirmasi Password Baru",
                      prefixIcon: Image.asset(
                        "assets/img/lock.png",
                        width: 20,
                        height: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: TColor.gray,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
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
                        title: "Reset Password",
                        onPressed: _resetPassword,
                      ),
                SizedBox(height: media.width * 0.04),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginView(),
                        ),
                        (route) => false,
                      );
                    },
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