import 'package:nextfitx/common/colo_extension.dart';
import 'package:nextfitx/common_widget/round_button.dart';
import 'package:nextfitx/common_widget/round_textfield.dart';
import 'package:nextfitx/services/auth_service.dart';
import 'package:nextfitx/view/login/complete_profile_view.dart';
import 'package:nextfitx/view/login/login_view.dart';
import 'package:flutter/material.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  bool isCheck = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmailAndPassword() async {
    if (!isCheck) {
      setState(() {
        _errorMessage = 'Please accept the Privacy Policy and Terms of Use';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CompleteProfileView(
                    firstName: _firstNameController.text.trim(),
                    lastName: _lastNameController.text.trim(),
                    email: _emailController.text.trim(),
                  )),
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

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CompleteProfileView(
                    firstName: _firstNameController.text.trim(),
                    lastName: _lastNameController.text.trim(),
                    email: _emailController.text.trim(),
                  )),
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
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Hey there,",
                  style: TextStyle(color: TColor.gray, fontSize: 16),
                ),
                Text(
                  "Create an Account",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: media.width * 0.05),
                RoundTextField(
                  hitText: "First Name",
                  icon: "assets/img/user_text.png",
                  controller: _firstNameController,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  hitText: "Last Name",
                  icon: "assets/img/user_text.png",
                  controller: _lastNameController,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  hitText: "Email",
                  icon: "assets/img/email.png",
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  hitText: "Password",
                  icon: "assets/img/lock.png",
                  obscureText: true,
                  isPassword: true,
                  controller: _passwordController,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isCheck = !isCheck;
                        });
                      },
                      icon: Icon(
                        isCheck
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank_outlined,
                        color: TColor.gray.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "By continuing you accept our Privacy Policy and Term of Use",
                        style: TextStyle(color: TColor.gray, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                SizedBox(height: media.width * 0.4),
                _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          TColor.primaryColor1,
                        ),
                      )
                    : RoundButton(
                        title: "Register",
                        onPressed: _signUpWithEmailAndPassword,
                      ),
                SizedBox(height: media.width * 0.04),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: TColor.gray.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      "  Or  ",
                      style: TextStyle(color: TColor.black, fontSize: 12),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: TColor.gray.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _signUpWithGoogle,
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TColor.white,
                          border: Border.all(
                            width: 1,
                            color: TColor.gray.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Image.asset(
                          "assets/img/google.png",
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: TColor.black, fontSize: 14),
                      ),
                      Text(
                        "Login",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: media.width * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
