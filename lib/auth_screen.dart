import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool isLogin = true;
  bool usePhone = false;
  bool loading = false;
  bool codeSent = false;

  String? verificationId;

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> submitEmail() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.length < 6) {
      showMessage(
        'Email likhein aur password kam az kam 6 characters ka rakhein',
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Authentication failed');
    } catch (e) {
      showMessage('Something went wrong');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (!phone.startsWith('+') || phone.length < 10) {
      showMessage('Number country code ke sath likhein, misal: +923001234567');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            showMessage('Phone login successful!');
          } on FirebaseAuthException catch (e) {
            showMessage(e.message ?? 'Phone login failed');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          showMessage(e.message ?? 'OTP send nahi ho saka');
          if (mounted) setState(() => loading = false);
        },
        codeSent: (String id, int? resendToken) {
          if (!mounted) return;
          setState(() {
            verificationId = id;
            codeSent = true;
            loading = false;
          });
          showMessage('OTP bhej diya gaya hai');
        },
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted && !codeSent) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> verifyOTP() async {
    if (verificationId == null || otpController.text.trim().length != 6) {
      showMessage('6 digit OTP code likhein');
      return;
    }

    setState(() => loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      showMessage('Phone login successful!');
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'OTP verification failed');
    } catch (e) {
      showMessage('Something went wrong');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00A884);

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.chat, size: 75, color: green),
              const SizedBox(height: 15),
              const Text(
                'MR ChatWave',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                usePhone
                    ? 'Phone Number Login'
                    : isLogin
                    ? 'Welcome Back!'
                    : 'Create Your Account',
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 25),

              if (!usePhone) ...[
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.email, color: green),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.lock, color: green),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: loading ? null : submitEmail,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isLogin ? 'LOGIN' : 'CREATE ACCOUNT'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Login',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],

              if (usePhone) ...[
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (+923001234567)',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.phone, color: green),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (codeSent)
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Enter 6 Digit OTP',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.password, color: green),
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: loading
                        ? null
                        : codeSent
                        ? verifyOTP
                        : sendOTP,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(codeSent ? 'VERIFY OTP' : 'SEND OTP'),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        setState(() {
                          usePhone = !usePhone;
                          codeSent = false;
                          verificationId = null;
                          otpController.clear();
                        });
                      },
                child: Text(
                  usePhone ? 'Login with Email' : 'Login with Phone Number',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
