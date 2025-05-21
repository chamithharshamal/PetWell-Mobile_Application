import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/auth_form.dart';
import './signup_screen.dart';
import '../../home/home_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart'; // Ensure this path is correct and the file contains the AdminDashboardScreen class

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFecdaca),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.pets, size: 80, color: const Color(0xFFe74d3d)),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 116, 112, 112),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthForm(
                    isSignIn: true,
                    isLoading: _isLoading,
                    onSubmit: (email, password) async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        final userCredential = await FirebaseAuth.instance
                            .signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        // Check if user is admin
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userCredential.user!.uid)
                            .get();
                        final isAdmin = userDoc.data()?['isAdmin'] ?? false;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => isAdmin
                                ? const AdminDashboardScreen()
                                : const HomeScreen(),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message ?? 'Sign-in failed')),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFe74d3d),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}