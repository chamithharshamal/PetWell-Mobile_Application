// lib/widgets/auth_form.dart
import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final bool isSignIn;
  final Function(String email, String password) onSubmit;

  const AuthForm({Key? key, required this.isSignIn, required this.onSubmit})
    : super(key: key);

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Submit form data
      widget.onSubmit(_emailController.text.trim(), _passwordController.text);

      setState(() {
        _isLoading = false;
      });
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
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
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
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
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
              if (value.length < 6) {
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
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
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
                onPressed: () {
                  // TODO: Implement forgot password logic
                  print('Forgot password');
                },
                child: const Text('Forgot Password?'),
              ),
            ),

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(widget.isSignIn ? 'Sign In' : 'Sign Up'),
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
                onPressed: () {
                  // TODO: Implement Google sign in
                  print('Google sign in');
                },
              ),
              _buildSocialButton(
                icon: Icons.facebook,
                color: Colors.blue,
                onPressed: () {
                  // TODO: Implement Facebook sign in
                  print('Facebook sign in');
                },
              ),
              _buildSocialButton(
                icon: Icons.apple,
                color: Colors.black,
                onPressed: () {
                  // TODO: Implement Apple sign in
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
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
