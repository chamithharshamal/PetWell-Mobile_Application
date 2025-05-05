// lib/features/auth/presentation/widgets/auth_form.dart
import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final bool isSignIn;
  final bool isLoading;
  final Function(String email, String password) onSubmit;

  const AuthForm({
    Key? key,
    required this.isSignIn,
    this.isLoading = false,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !widget.isLoading,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(
                color: Colors.black,
              ), // Label text color
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: Colors.black,
              ), // Optional: icon color
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black), // Normal border
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black,
                  width: 2,
                ), // Focused border
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            enabled: !widget.isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(
                color: Colors.black,
              ), // Label text color
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Colors.black,
              ), // Icon color
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black), // Normal border
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.black,
                  width: 2,
                ), // Focused border
              ),
              border: const OutlineInputBorder(), // Fallback border
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.black, // Suffix icon color
                ),
                onPressed:
                    widget.isLoading
                        ? null
                        : () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!widget.isSignIn && value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Confirm password field (only for sign up)
          if (!widget.isSignIn) ...[
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isPasswordVisible,
              enabled: !widget.isLoading,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(color: Colors.black), // Label text color
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.black,
                ), // Optional: icon color
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black), // Normal border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ), // Focused border
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
          ],

          // Forgot password link (only for sign in)
          if (widget.isSignIn)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed:
                    widget.isLoading
                        ? null
                        : () {
                          // TODO: Navigate to password reset screen
                          print('Navigate to password reset');
                        },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFFE74D3D),
                  ), // Custom text color
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFFE74D3D,
              ), // Button background color
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                widget.isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE74D3D),
                      ),
                    )
                    : const Text(
                      'Sign In', // or 'Sign Up' based on your logic
                      style: TextStyle(
                        color: Colors.white,
                      ), // Optional: text color
                    ),
          ),

          const SizedBox(height: 24),

          // Social login options
          Row(
            children: [
              const Expanded(child: Divider(thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or continue with',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const Expanded(child: Divider(thickness: 1)),
            ],
          ),

          const SizedBox(height: 24),

          // Social login buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                icon: Icons.g_mobiledata,
                color: Colors.red,
                onPressed:
                    widget.isLoading
                        ? null
                        : () {
                          // TODO: Implement Google sign in with Firebase
                          print('Google sign in');
                        },
              ),
              _buildSocialButton(
                icon: Icons.facebook,
                color: Colors.blue,
                onPressed:
                    widget.isLoading
                        ? null
                        : () {
                          // TODO: Implement Facebook sign in with Firebase
                          print('Facebook sign in');
                        },
              ),
              _buildSocialButton(
                icon: Icons.apple,
                color: Colors.black,
                onPressed:
                    widget.isLoading
                        ? null
                        : () {
                          // TODO: Implement Apple sign in with Firebase
                          print('Apple sign in');
                        },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
