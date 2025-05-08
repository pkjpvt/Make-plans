import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../screen/bottom_navbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _saveFirebaseUser(User user) async {
    try {
      final name = user.displayName != null && user.displayName!.isNotEmpty
          ? user.displayName
          : "Guest User";

      final uri = Uri.parse(
        'https://cb46-2401-4900-5028-cb63-8a-6e6c-b706-bfca.ngrok-free.app/makeplans-api/api/auth/save_firebase_user.php',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "firebase_uid": user.uid,
          "name": name,
          "email": user.email ?? '',
          "profile_picture": user.photoURL ?? ''
        }),
      );

      final result = jsonDecode(response.body);
      if (result['status'] == true) {
        print("✅ MySQL user sync success: ${result['user_id']}");
      } else {
        print("⚠️ MySQL sync failed: ${result['message']}");
      }
    } catch (e) {
      print("❌ Error syncing with MySQL: $e");
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = userCredential.user;

        if (user != null) {
          print('✅ Login successful for: ${user.email}');
          await _saveFirebaseUser(user);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavBar()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unexpected error: No user found')),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Login failed';
        if (e.code == 'user-not-found') {
          message = 'No user found with this email.';
        } else if (e.code == 'wrong-password') {
          message = 'Incorrect password.';
        } else {
          message = e.message ?? 'Authentication error';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        print('❌ Unexpected error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut(); // 👈 Force account picker every time

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        print("✅ Google login successful: ${user.email}");
        await _saveFirebaseUser(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
      }
    } catch (e) {
      print("❌ Google Sign-In failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google login failed: $e")),
      );
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(result.accessToken!.token);

        final userCredential = await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);

        final user = userCredential.user;

        if (user != null) {
          print("✅ Facebook login successful: ${user.email}");
          await _saveFirebaseUser(user);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavBar()),
          );
        }
      } else {
        print("⚠️ Facebook login cancelled or failed: ${result.status}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Facebook login failed")),
        );
      }
    } catch (e) {
      print("❌ Facebook Sign-In error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),
                      const Center(
                        child: Text(
                          'Make Plans',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      const Text('Email', style: TextStyle(fontSize: 16)),
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Enter your email',
                      ),
                      const SizedBox(height: 20),
                      const Text('Password', style: TextStyle(fontSize: 16)),
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Enter your password',
                        isPassword: true,
                      ),
                      const SizedBox(height: 30),
                      CustomButton(
                        text: 'Login',
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            'Don\'t have an account? Register Here',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Center(
                        child: Text(
                          'Or Sign Up Using',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialButton('assets/images/google.png', 'Google',
                              _signInWithGoogle),
                          const SizedBox(width: 16),
                          _socialButton('assets/images/facebook.png', 'Facebook',
                              _signInWithFacebook),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton(String imagePath, String altText, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.white,
        child: Image.asset(imagePath, width: 30, height: 30),
      ),
    );
  }
}
